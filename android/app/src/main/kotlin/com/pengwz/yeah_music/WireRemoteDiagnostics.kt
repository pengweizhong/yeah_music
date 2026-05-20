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

import android.content.Context
import java.io.File

object WireRemoteDiagnostics {
    private const val FILE_NAME = "wire_remote_diagnostics.log"
    private const val MAX_BYTES = 256 * 1024L
    private const val KEEP_BYTES = 128 * 1024

    @Volatile
    private var appContext: Context? = null

    @Volatile
    var enabled: Boolean = false

    fun init(context: Context) {
        appContext = context.applicationContext
    }

    private fun logFile(): File? {
        val ctx = appContext ?: return null
        return File(ctx.filesDir, FILE_NAME)
    }

    @Synchronized
    fun append(message: String) {
        if (!enabled) return
        val file = logFile() ?: return
        try {
            if (file.exists() && file.length() > MAX_BYTES) {
                val text = file.readText()
                file.writeText(text.takeLast(KEEP_BYTES))
            }
            file.appendText("${System.currentTimeMillis()} $message\n")
        } catch (_: Throwable) {
        }
    }

    @Synchronized
    fun read(): String {
        return try {
            val file = logFile() ?: return ""
            if (!file.exists()) "" else file.readText()
        } catch (_: Throwable) {
            ""
        }
    }

    @Synchronized
    fun clear() {
        try {
            logFile()?.delete()
        } catch (_: Throwable) {
        }
    }
}
