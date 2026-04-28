package com.pengwz.yeah_music

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity

/// 供 OAuth 自定义 scheme（如 OneDrive）从浏览器返回时把 Intent 交给 AppAuth，
/// 避免因 [singleTop] 未更新 Activity intent 而无法完成令牌交换。
class MainActivity : FlutterActivity() {
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
    }
}
