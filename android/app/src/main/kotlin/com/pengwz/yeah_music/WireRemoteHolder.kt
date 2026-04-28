package com.pengwz.yeah_music

import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * 前台 Activity 拦截耳机线控连击，在短停顿后把次数发给 Flutter（与 [WireRemoteNative] 对应）。
 */
object WireRemoteHolder {
    private const val CHANNEL = "yeah_music/wire_remote"
    private const val GAP_MS = 520L

    @Volatile
    var enabled: Boolean = true

    private var messenger: BinaryMessenger? = null
    private var hookCount = 0
    private val handler = Handler(Looper.getMainLooper())

    private val flushRunnable = Runnable {
        val n = hookCount
        hookCount = 0
        val m = messenger ?: return@Runnable
        if (n > 0) {
            MethodChannel(m, CHANNEL).invokeMethod("headsetGesture", n)
        }
    }

    fun attach(binaryMessenger: BinaryMessenger) {
        messenger = binaryMessenger
        MethodChannel(binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "configure" -> {
                    val args = call.arguments as? Map<*, *> ?: emptyMap<Any, Any>()
                    enabled = args["enabled"] as? Boolean ?: true
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    /**
     * @return true 表示已消费事件（勿再交给系统默认处理）。
     */
    fun onHeadsetHookDown(): Boolean {
        if (!enabled) return false
        hookCount++
        if (hookCount > 3) hookCount = 3
        handler.removeCallbacks(flushRunnable)
        handler.postDelayed(flushRunnable, GAP_MS)
        return true
    }
}
