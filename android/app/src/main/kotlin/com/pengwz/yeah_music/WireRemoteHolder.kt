package com.pengwz.yeah_music

import android.content.Context
import android.view.KeyEvent
import com.ryanheise.audioservice.AudioServicePlugin
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * 前台 Activity 拦截耳机线控连击，在短停顿后把次数发给 Flutter（与 [WireRemoteNative] 对应）。
 */
object WireRemoteHolder {
    private const val CHANNEL = "yeah_music/wire_remote"
    /// 略长于双击间隔，避免三击被拆成 2+1；蓝牙耳机连击若仍无反应，多为系统直接发 NEXT 键，见 [onMediaDiscreteKey]。
    private const val GAP_MS = 700L

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

    fun ensureAttached(context: Context) {
        if (messenger != null) return
        try {
            val engine = AudioServicePlugin.getFlutterEngine(context)
            attach(engine.dartExecutor.binaryMessenger)
        } catch (_: Throwable) {
        }
    }

    /**
     * 蓝牙耳机等常直接发 `MEDIA_NEXT` / `MEDIA_PREVIOUS`，不会走连击计数。
     *
     * @param kind 与 Flutter 约定：`next` | `previous`
     * @return true 表示已消费。
     */
    fun onMediaDiscreteKey(kind: String): Boolean {
        if (!enabled) return false
        val m = messenger ?: return false
        MethodChannel(m, CHANNEL).invokeMethod("mediaDiscrete", kind)
        return true
    }

    fun onMediaButtonEvent(event: KeyEvent?): Boolean {
        val e = event ?: return false
        if (e.action != KeyEvent.ACTION_DOWN) return false
        return when (e.keyCode) {
            KeyEvent.KEYCODE_HEADSETHOOK,
            KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE,
            -> onHeadsetHookDown(e.repeatCount)

            KeyEvent.KEYCODE_MEDIA_NEXT,
            KeyEvent.KEYCODE_MEDIA_FAST_FORWARD,
            -> {
                if (e.repeatCount > 0) false else onMediaDiscreteKey("next")
            }

            KeyEvent.KEYCODE_MEDIA_PREVIOUS,
            KeyEvent.KEYCODE_MEDIA_REWIND,
            -> {
                if (e.repeatCount > 0) false else onMediaDiscreteKey("previous")
            }

            else -> false
        }
    }

    /**
     * 线控 / 部分设备的播放键连击。
     *
     * @param repeatCount [KeyEvent.getRepeatCount] 长按会产生重复 DOWN，不参与连击计数。
     * @return true 表示已消费。
     */
    fun onHeadsetHookDown(repeatCount: Int): Boolean {
        if (!enabled) return false
        if (repeatCount > 0) return false
        hookCount++
        if (hookCount > 3) hookCount = 3
        handler.removeCallbacks(flushRunnable)
        handler.postDelayed(flushRunnable, GAP_MS)
        return true
    }
}
