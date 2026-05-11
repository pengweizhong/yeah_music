package com.pengwz.yeah_music

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.ClipData
import android.content.ContentResolver
import android.content.ContentUris
import android.content.Intent
import android.media.MediaScannerConnection
import android.os.Build
import android.provider.MediaStore
import android.webkit.MimeTypeMap
import androidx.core.content.FileProvider
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

/// 将本地音频交给外部编辑器。
/// MediaStore Uri **不可** [grantUriPermission]（系统 Provider），仅用 Intent flag + ClipData；
/// 自有 FileProvider 再额外 [grantUriPermission]。
object MusicTagEditorBridge {

    private const val CHANNEL = "yeah_music/music_tag_editor"

    private val uriPermissionFlags: Int
        get() = Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION

    private var pendingOriginalForCacheFallback: File? = null
    private var pendingCacheCopy: File? = null

    fun onHostResume(@Suppress("UNUSED_PARAMETER") activity: Activity) {
        val orig = pendingOriginalForCacheFallback ?: return
        val cache = pendingCacheCopy ?: return
        pendingOriginalForCacheFallback = null
        pendingCacheCopy = null
        try {
            if (!cache.exists()) return
            val freshOrig = File(orig.path)
            if (!freshOrig.exists()) return
            // 若仅用「更长 / mtime 大于编辑前」判断是否合并，原地改写 ID3（长度不变、mtime 不可靠）会跳过写回，导致标签未落盘。
            // 副本初始即来自原文件；未在编辑器保存时内容与原件一致，覆盖无损。
            cache.copyTo(freshOrig, overwrite = true)
        } catch (_: Exception) {
        }
    }

    fun register(activity: MainActivity, flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "scanAudioFileAfterExternalEdit" -> {
                    val path = call.argument<String>("path")?.trim()
                    if (path.isNullOrEmpty()) {
                        result.success(mapOf("ok" to false))
                        return@setMethodCallHandler
                    }
                    try {
                        scanAudioFile(activity, path)
                        result.success(mapOf("ok" to true))
                    } catch (e: Exception) {
                        result.success(mapOf("ok" to false, "detail" to (e.message ?: "")))
                    }
                }
                "openWithMusicTagEditor", "openWithSyncedLyricEditor" -> {
                    val defaultPkg = when (call.method) {
                        "openWithMusicTagEditor" -> "com.xjcheng.musictageditor"
                        "openWithSyncedLyricEditor" ->
                            "lyriceditor.lyricsearch.embedlyrictomp3.syncedlyriceditor"
                        else -> ""
                    }
                    val path = call.argument<String>("path")
                    val pkg = call.argument<String>("package") ?: defaultPkg
                    if (path.isNullOrBlank()) {
                        result.success(mapOf("status" to "invalid_args"))
                        return@setMethodCallHandler
                    }
                    try {
                        result.success(open(activity, path, pkg))
                    } catch (e: Exception) {
                        result.success(mapOf("status" to "error", "detail" to (e.message ?: "")))
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun ourFileProviderAuthority(activity: MainActivity): String =
        "${activity.application.packageName}.fileprovider"

    private fun isOurFileProviderUri(activity: MainActivity, uri: android.net.Uri): Boolean =
        uri.authority == ourFileProviderAuthority(activity)

    private fun open(activity: MainActivity, path: String, packageName: String): Map<String, Any?> {
        pendingOriginalForCacheFallback = null
        pendingCacheCopy = null

        val raw = File(path.trim())
        if (!raw.exists()) {
            return mapOf("status" to "file_not_found")
        }
        val file = try {
            raw.canonicalFile
        } catch (_: Exception) {
            raw
        }

        // 优先自有 FileProvider 指向磁盘真实路径，便于第三方直接改写文件；Yeah Music 侧也用同一 path 读标签。
        // 若先走 MediaStore，部分机型上编辑器会「保存成功」但后续同步/回写路径失败，出现连续「成功」「失败」Toast。
        val attempts = buildList {
            directFileProviderUri(activity, file)?.let {
                add(UriAttempt(it, false, "fileprovider_direct"))
            }
            mediaStoreUriForAudioFile(activity, file)?.let {
                add(UriAttempt(it, false, "mediastore"))
            }
            cacheFallbackUri(activity, file)?.let {
                add(it)
            }
        }

        if (attempts.isEmpty()) {
            return mapOf("status" to "cannot_share_path")
        }

        val ext = file.name.substringAfterLast('.', "").lowercase()
        val mime = MimeTypeMap.getSingleton().getMimeTypeFromExtension(ext) ?: "audio/*"

        var lastNotFound: ActivityNotFoundException? = null
        var lastOtherError: String? = null

        for (attempt in attempts) {
            val intents = listOf(
                Intent(Intent.ACTION_EDIT).apply {
                    setDataAndType(attempt.uri, mime)
                    setPackage(packageName)
                },
                Intent(Intent.ACTION_VIEW).apply {
                    setDataAndType(attempt.uri, mime)
                    setPackage(packageName)
                },
            )
            for (intent in intents) {
                try {
                    prepareIntentUriPermissions(activity, intent, attempt.uri, packageName)
                    activity.startActivity(intent)
                    return mapOf(
                        "status" to "ok",
                        "used_cache_fallback" to attempt.usedCacheFallback,
                        "uri_source" to attempt.source,
                    )
                } catch (e: ActivityNotFoundException) {
                    safeRevokeUri(activity, attempt.uri)
                    lastNotFound = e
                } catch (e: Exception) {
                    safeRevokeUri(activity, attempt.uri)
                    lastOtherError = e.message ?: "start_failed"
                }
            }
        }

        if (lastOtherError != null) {
            return mapOf("status" to "error", "detail" to lastOtherError)
        }
        return if (lastNotFound != null) {
            mapOf("status" to "activity_not_found")
        } else {
            mapOf("status" to "error", "detail" to "launch_failed")
        }
    }

    private data class UriAttempt(
        val uri: android.net.Uri,
        val usedCacheFallback: Boolean,
        val source: String,
    )

    private fun prepareIntentUriPermissions(
        activity: MainActivity,
        intent: Intent,
        uri: android.net.Uri,
        packageName: String,
    ) {
        intent.addFlags(uriPermissionFlags)
        intent.clipData = ClipData.newUri(activity.contentResolver, "", uri)
        // 仅自有 FileProvider 可 grant；对 MediaStore 等系统 Uri 调用会抛 SecurityException
        if (isOurFileProviderUri(activity, uri)) {
            try {
                activity.grantUriPermission(packageName, uri, uriPermissionFlags)
            } catch (_: Exception) {
            }
        }
    }

    private fun safeRevokeUri(activity: MainActivity, uri: android.net.Uri) {
        if (!isOurFileProviderUri(activity, uri)) return
        try {
            activity.revokeUriPermission(uri, uriPermissionFlags)
        } catch (_: Exception) {
        }
    }

    private fun mediaStoreUriForAudioFile(activity: MainActivity, file: File): android.net.Uri? {
        val resolver = activity.contentResolver
        val candidates = buildList {
            try {
                add(file.canonicalPath)
            } catch (_: Exception) {
            }
            add(file.absolutePath)
        }.distinct()

        val bases = linkedSetOf<android.net.Uri>()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            try {
                bases.add(MediaStore.Audio.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY))
            } catch (_: Exception) {
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                try {
                    for (v in MediaStore.getExternalVolumeNames(activity)) {
                        try {
                            bases.add(MediaStore.Audio.Media.getContentUri(v))
                        } catch (_: Exception) {
                        }
                    }
                } catch (_: Exception) {
                }
            }
        }
        if (bases.isEmpty()) {
            @Suppress("DEPRECATION")
            bases.add(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI)
        }

        val projection = arrayOf(MediaStore.Audio.Media._ID)
        for (base in bases) {
            for (path in candidates) {
                val found = queryAudioIdByData(resolver, base, projection, path)
                if (found != null) return found
            }
        }
        return null
    }

    @Suppress("DEPRECATION")
    private fun queryAudioIdByData(
        resolver: ContentResolver,
        contentUri: android.net.Uri,
        projection: Array<String>,
        path: String,
    ): android.net.Uri? {
        val cursor = try {
            resolver.query(
                contentUri,
                projection,
                "${MediaStore.Audio.Media.DATA}=?",
                arrayOf(path),
                null,
            )
        } catch (_: SecurityException) {
            null
        } catch (_: Exception) {
            null
        } ?: return null
        cursor.use {
            if (!it.moveToFirst()) return null
            val idIdx = it.getColumnIndex(MediaStore.Audio.Media._ID)
            if (idIdx < 0) return null
            val id = it.getLong(idIdx)
            if (id <= 0L) return null
            return ContentUris.withAppendedId(contentUri, id)
        }
    }

    /// 外部编辑器保存后通知系统刷新媒体索引
    private fun scanAudioFile(activity: Activity, absolutePath: String) {
        val f = File(absolutePath.trim())
        if (!f.exists()) return
        MediaScannerConnection.scanFile(
            activity,
            arrayOf(f.absolutePath),
            null,
        ) { _, _ -> }
    }

    private fun directFileProviderUri(activity: MainActivity, file: File): android.net.Uri? {
        val authority = "${activity.application.packageName}.fileprovider"
        return try {
            FileProvider.getUriForFile(activity, authority, file)
        } catch (_: IllegalArgumentException) {
            null
        }
    }

    /// FileProvider 无法暴露该路径时使用缓存副本；返程时在 [onHostResume] 合并回原文件。
    private fun cacheFallbackUri(activity: MainActivity, file: File): UriAttempt? {
        val authority = "${activity.application.packageName}.fileprovider"
        return try {
            val cache = File(activity.cacheDir, "music_tag_share_${System.currentTimeMillis()}_${file.name}")
            file.copyTo(cache, overwrite = true)
            pendingOriginalForCacheFallback = file
            pendingCacheCopy = cache
            UriAttempt(FileProvider.getUriForFile(activity, authority, cache), true, "fileprovider_cache")
        } catch (_: Exception) {
            null
        }
    }
}
