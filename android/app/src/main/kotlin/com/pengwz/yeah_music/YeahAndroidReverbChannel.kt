package com.pengwz.yeah_music

import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/// [PresetReverb] 在系统里多为 **辅助(aux)效果**，须由播放器 [attachAuxEffect] / [setAuxEffectSendLevel] 绑定。
/// 在未接入 ExoPlayer 管线时强行挂在 session 上会导致 **电平暴增、音量键失效** 等问题，故本通道仅保留为
/// 释放占位（与 Dart [AndroidReverbBridge] 的 `release`/`sync` 对齐），不再创建任何原生混响实例。
object YeahAndroidReverbChannel {
    private const val CHANNEL_NAME = "yeah_music/android_reverb"

    fun register(binaryMessenger: BinaryMessenger) {
        MethodChannel(binaryMessenger, CHANNEL_NAME).setMethodCallHandler { call, result ->
            when (call.method) {
                "sync", "release" -> result.success(null)
                else -> result.notImplemented()
            }
        }
    }
}
