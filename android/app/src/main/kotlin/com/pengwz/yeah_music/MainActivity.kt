package com.pengwz.yeah_music

import android.content.Intent
import com.ryanheise.audioservice.AudioServiceFragmentActivity

/// 供 OAuth 自定义 scheme（如 OneDrive）从浏览器返回时把 Intent 交给 AppAuth，
/// 避免因 [singleTop] 未更新 Activity intent 而无法完成令牌交换。
/// 继承 [AudioServiceFragmentActivity] 以支持 just_audio_background / 车载与锁屏媒体控制。
class MainActivity : AudioServiceFragmentActivity() {
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
    }
}
