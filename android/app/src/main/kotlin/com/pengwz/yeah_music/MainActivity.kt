package com.pengwz.yeah_music

import android.content.Intent
import android.os.Bundle
import android.view.KeyEvent
import com.ryanheise.audioservice.AudioServiceFragmentActivity
import com.ryanheise.audioservice.AudioServicePlugin
import io.flutter.embedding.engine.FlutterEngine

/// 供 OAuth 自定义 scheme（如 OneDrive）从浏览器返回时把 Intent 交给 AppAuth，
/// 避免因 [singleTop] 未更新 Activity intent 而无法完成令牌交换。
/// 继承 [AudioServiceFragmentActivity] 以支持 just_audio_background / 车载与锁屏媒体控制。
class MainActivity : AudioServiceFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        DiskSpaceChannel.register(flutterEngine.dartExecutor.binaryMessenger)
        MusicTagEditorBridge.register(this, flutterEngine)
        OpenWithChannel.register(this, flutterEngine.dartExecutor.binaryMessenger)
    }

    override fun onResume() {
        // 先于 Flutter 生命周期回调：把第三方写在缓存副本里的结果合并回原音频路径，
        // 以便 Dart 侧 onResume 重新加载元数据时读到最新文件。
        MusicTagEditorBridge.onHostResume(this)
        super.onResume()
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        OpenWithChannel.captureViewIntent(intent)
        try {
            val engine = AudioServicePlugin.getFlutterEngine(this)
            WireRemoteHolder.attach(engine.dartExecutor.binaryMessenger)
        } catch (_: Throwable) {
        }
    }

    override fun dispatchKeyEvent(event: KeyEvent): Boolean {
        if (event.action != KeyEvent.ACTION_DOWN) {
            return super.dispatchKeyEvent(event)
        }
        when (event.keyCode) {
            KeyEvent.KEYCODE_HEADSETHOOK,
            KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE,
            -> {
                if (WireRemoteHolder.onHeadsetHookDown(event.repeatCount)) {
                    return true
                }
            }
            KeyEvent.KEYCODE_MEDIA_NEXT,
            KeyEvent.KEYCODE_MEDIA_FAST_FORWARD,
            -> {
                if (event.repeatCount > 0) {
                    return super.dispatchKeyEvent(event)
                }
                if (WireRemoteHolder.onMediaDiscreteKey("next")) {
                    return true
                }
            }
            KeyEvent.KEYCODE_MEDIA_PREVIOUS,
            KeyEvent.KEYCODE_MEDIA_REWIND,
            -> {
                if (event.repeatCount > 0) {
                    return super.dispatchKeyEvent(event)
                }
                if (WireRemoteHolder.onMediaDiscreteKey("previous")) {
                    return true
                }
            }
        }
        return super.dispatchKeyEvent(event)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        OpenWithChannel.captureViewIntent(intent)
    }
}
