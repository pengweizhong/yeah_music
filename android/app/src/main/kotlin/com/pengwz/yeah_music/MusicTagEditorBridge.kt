package com.pengwz.yeah_music

import android.content.ActivityNotFoundException
import android.content.Intent
import android.webkit.MimeTypeMap
import androidx.core.content.FileProvider
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

/// 将本地音频路径通过 [Intent.ACTION_EDIT] / [Intent.ACTION_VIEW] 交给指定包名的外部编辑器（标签 / 歌词等）。
object MusicTagEditorBridge {

    private const val CHANNEL = "yeah_music/music_tag_editor"

    fun register(activity: MainActivity, flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            val defaultPkg = when (call.method) {
                "openWithMusicTagEditor" -> "com.xjcheng.musictageditor"
                "openWithSyncedLyricEditor" -> "lyriceditor.lyricsearch.embedlyrictomp3.syncedlyriceditor"
                else -> {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
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
    }

    private fun open(activity: MainActivity, path: String, packageName: String): Map<String, Any?> {
        val file = File(path)
        if (!file.exists()) {
            return mapOf("status" to "file_not_found")
        }
        val uri = uriForFile(activity, file) ?: return mapOf("status" to "cannot_share_path")
        val ext = file.name.substringAfterLast('.', "").lowercase()
        val mime = MimeTypeMap.getSingleton().getMimeTypeFromExtension(ext) ?: "audio/*"
        val intents = listOf(
            Intent(Intent.ACTION_EDIT).apply {
                setDataAndType(uri, mime)
                setPackage(packageName)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
            },
            Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, mime)
                setPackage(packageName)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
            },
        )
        var notFound: ActivityNotFoundException? = null
        for (intent in intents) {
            try {
                activity.startActivity(intent)
                return mapOf("status" to "ok")
            } catch (e: ActivityNotFoundException) {
                notFound = e
            }
        }
        return if (notFound != null) {
            mapOf("status" to "activity_not_found")
        } else {
            mapOf("status" to "error")
        }
    }

    private fun uriForFile(activity: MainActivity, file: File): android.net.Uri? {
        val authority = "${activity.application.packageName}.fileprovider"
        return try {
            FileProvider.getUriForFile(activity, authority, file)
        } catch (_: IllegalArgumentException) {
            try {
                val cache = File(activity.cacheDir, "music_tag_share_${System.currentTimeMillis()}_${file.name}")
                file.copyTo(cache, overwrite = true)
                FileProvider.getUriForFile(activity, authority, cache)
            } catch (_: Exception) {
                null
            }
        }
    }
}
