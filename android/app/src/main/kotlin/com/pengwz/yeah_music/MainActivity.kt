package com.pengwz.yeah_music

import android.content.Intent
import android.os.Bundle
import android.view.KeyEvent
import com.ryanheise.audioservice.AudioServiceFragmentActivity
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
        WireRemoteDiagnostics.init(this)
        WireRemoteHolder.attach(flutterEngine.dartExecutor.binaryMessenger)
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
    }

    override fun dispatchKeyEvent(event: KeyEvent): Boolean {
        if (WireRemoteHolder.onMediaButtonEvent(event)) {
            return true
        }
        return super.dispatchKeyEvent(event)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        OpenWithChannel.captureViewIntent(intent)
    }
}
