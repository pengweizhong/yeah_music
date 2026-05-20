/* Copyright (c) 2025 Yeah Music
 *
 * This file is part of Yeah Music.
 *
 * Yeah Music is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Yeah Music is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 */

package com.pengwz.yeah_music

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.OpenableColumns
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.ConcurrentLinkedQueue

/**
 * 文件管理器「打开方式 → Yeah Music」：[ACTION_VIEW] 携带的 [Uri] 入队，
 * Flutter 侧调用 [consumePending] 时再 materialize 为本地可读路径（content:// 会复制到 cache）。
 */
object OpenWithChannel {
    private const val CHANNEL = "com.pengwz.yeah_music/open_with"
    private val pendingUris = ConcurrentLinkedQueue<Uri>()

    fun captureViewIntent(intent: Intent?) {
        if (intent?.action != Intent.ACTION_VIEW) return
        val data = intent.data ?: return
        pendingUris.add(data)
    }

    fun register(activity: Activity, messenger: io.flutter.plugin.common.BinaryMessenger) {
        MethodChannel(messenger, CHANNEL).setMethodCallHandler { call: MethodCall, result: MethodChannel.Result ->
            when (call.method) {
                "consumePending" -> {
                    val uri = pendingUris.poll()
                    if (uri == null) {
                        result.success(null)
                        return@setMethodCallHandler
                    }
                    Thread {
                        try {
                            val path = materializeToReadablePath(activity.applicationContext, uri)
                            activity.runOnUiThread {
                                result.success(path)
                            }
                        } catch (_: Throwable) {
                            activity.runOnUiThread {
                                result.success(null)
                            }
                        }
                    }.start()
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun materializeToReadablePath(context: Context, uri: Uri): String? {
        val scheme = uri.scheme?.lowercase() ?: return null
        if (scheme == "file") {
            val p = uri.path ?: return null
            val f = File(p)
            return if (f.exists() && f.isFile) f.canonicalPath else null
        }
        if (scheme != "content") return null

        val resolver = context.contentResolver
        var displayName = "track.audio"
        resolver.query(uri, null, null, null, null)?.use { c ->
            val idx = c.getColumnIndex(OpenableColumns.DISPLAY_NAME)
            if (idx >= 0 && c.moveToFirst()) {
                val n = c.getString(idx)
                if (!n.isNullOrBlank()) displayName = n
            }
        }

        val outDir = File(context.cacheDir, "open_with").apply { mkdirs() }
        val safeName = displayName.replace(Regex("""[\\/:*?"<>|]"""), "_").take(160)
        val out = File(outDir, "${System.currentTimeMillis()}_$safeName")

        resolver.openInputStream(uri)?.use { input ->
            out.outputStream().use { output -> input.copyTo(output) }
        } ?: return null
        if (!out.exists() || out.length() == 0L) {
            try {
                out.delete()
            } catch (_: Throwable) {
            }
            return null
        }
        return out.canonicalPath
    }
}
