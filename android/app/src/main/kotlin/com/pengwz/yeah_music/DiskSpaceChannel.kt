package com.pengwz.yeah_music

import android.os.Environment
import android.os.StatFs
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/// 与 Dart [SystemUtils]、`macos/Runner/YeahMusicMethodChannels.swift` 约定一致：`getDiskSpace` 返回字节。
object DiskSpaceChannel {
    private const val CHANNEL_NAME = "disk_space"

    fun register(binaryMessenger: BinaryMessenger) {
        MethodChannel(binaryMessenger, CHANNEL_NAME).setMethodCallHandler { call, result ->
            when (call.method) {
                "getDiskSpace" -> {
                    try {
                        val stat = StatFs(Environment.getDataDirectory().absolutePath)
                        val total = stat.totalBytes
                        val free = stat.availableBytes
                        result.success(
                            mapOf(
                                "total" to total,
                                "free" to free,
                            ),
                        )
                    } catch (e: Throwable) {
                        result.error(
                            "DISK_SPACE_ERROR",
                            e.message ?: "StatFs failed",
                            null,
                        )
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
