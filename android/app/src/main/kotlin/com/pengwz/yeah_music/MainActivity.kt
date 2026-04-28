package com.pengwz.yeah_music

import android.content.Intent
import android.os.Bundle
import android.view.KeyEvent
import com.ryanheise.audioservice.AudioServiceFragmentActivity
import com.ryanheise.audioservice.AudioServicePlugin

/// 供 OAuth 自定义 scheme（如 OneDrive）从浏览器返回时把 Intent 交给 AppAuth，
/// 避免因 [singleTop] 未更新 Activity intent 而无法完成令牌交换。
/// 继承 [AudioServiceFragmentActivity] 以支持 just_audio_background / 车载与锁屏媒体控制。
class MainActivity : AudioServiceFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        try {
            val engine = AudioServicePlugin.getFlutterEngine(this)
            WireRemoteHolder.attach(engine.dartExecutor.binaryMessenger)
        } catch (_: Throwable) {
        }
    }

    override fun dispatchKeyEvent(event: KeyEvent): Boolean {
        if (event.action == KeyEvent.ACTION_DOWN) {
            when (event.keyCode) {
                KeyEvent.KEYCODE_HEADSETHOOK,
                KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE,
                -> {
                    if (WireRemoteHolder.onHeadsetHookDown()) {
                        return true
                    }
                }
            }
        }
        return super.dispatchKeyEvent(event)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
    }
}
