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
