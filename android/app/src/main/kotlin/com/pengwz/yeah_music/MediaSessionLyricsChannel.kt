package com.pengwz.yeah_music

import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/// 绕过 audio_service `setMediaItem` 的单线程池，直接在主线程更新通知栏展示文案。
///
/// 不可在 app 模块直接 import [com.ryanheise.audioservice.AudioService]（其超类
/// [androidx.media.MediaBrowserServiceCompat] 不在 app 编译 classpath 上），故用反射。
object MediaSessionLyricsChannel {
    private const val TAG = "YeahMediaLyrics"
    private const val CHANNEL_NAME = "yeah_music/media_session_lyrics"
    private const val AUDIO_SERVICE_CLASS = "com.ryanheise.audioservice.AudioService"
    private val mainHandler = Handler(Looper.getMainLooper())

    private fun updateNotificationDisplayText(title: String?, subtitle: String?): Boolean {
        if (!hasUpdateNotificationDisplayText()) {
            throw NoSuchMethodException(
                "$AUDIO_SERVICE_CLASS.updateNotificationDisplayText — " +
                    "请确认 pubspec 使用 path: packages/audio_service 并执行 flutter clean 后重装",
            )
        }
        val clazz = Class.forName(AUDIO_SERVICE_CLASS)
        val method = clazz.getMethod(
            "updateNotificationDisplayText",
            String::class.java,
            String::class.java,
        )
        val result = method.invoke(null, title, subtitle)
        return (result as? Boolean) ?: true
    }

    private fun hasUpdateNotificationDisplayText(): Boolean {
        return try {
            Class.forName(AUDIO_SERVICE_CLASS).getMethod(
                "updateNotificationDisplayText",
                String::class.java,
                String::class.java,
            )
            true
        } catch (_: NoSuchMethodException) {
            false
        } catch (_: Throwable) {
            false
        }
    }

    private fun setYeahLyricsDisplayManaged(enabled: Boolean) {
        if (!hasSetYeahLyricsDisplayManaged()) return
        val clazz = Class.forName(AUDIO_SERVICE_CLASS)
        val method = clazz.getMethod(
            "setYeahLyricsDisplayManaged",
            Boolean::class.javaPrimitiveType,
        )
        method.invoke(null, enabled)
    }

    private fun hasSetYeahLyricsDisplayManaged(): Boolean {
        return try {
            Class.forName(AUDIO_SERVICE_CLASS).getMethod(
                "setYeahLyricsDisplayManaged",
                Boolean::class.javaPrimitiveType,
            )
            true
        } catch (_: NoSuchMethodException) {
            false
        } catch (_: Throwable) {
            false
        }
    }

    private fun isAudioServiceReady(): Boolean {
        return try {
            val clazz = Class.forName(AUDIO_SERVICE_CLASS)
            val field = clazz.getDeclaredField("instance")
            field.isAccessible = true
            field.get(null) != null
        } catch (_: Throwable) {
            false
        }
    }

    fun register(binaryMessenger: BinaryMessenger) {
        MethodChannel(binaryMessenger, CHANNEL_NAME).setMethodCallHandler { call, result ->
            when (call.method) {
                "setLyricsManaged" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: false
                    try {
                        setYeahLyricsDisplayManaged(enabled)
                        result.success(null)
                    } catch (t: Throwable) {
                        Log.w(TAG, "setLyricsManaged failed", t)
                        result.error("SET_MANAGED_FAILED", t.message, null)
                    }
                }
                "updateDisplay" -> {
                    val title = call.argument<String>("displayTitle")
                    val subtitle = call.argument<String>("displaySubtitle")
                    if (title == null && subtitle == null) {
                        result.success(null)
                        return@setMethodCallHandler
                    }
                    mainHandler.post {
                        try {
                            if (!hasUpdateNotificationDisplayText()) {
                                Log.e(
                                    TAG,
                                    "AudioService 缺少 updateNotificationDisplayText；" +
                                        "需 dependency_overrides: audio_service -> packages/audio_service",
                                )
                                result.error(
                                    "AUDIO_SERVICE_FORK_REQUIRED",
                                    "Use packages/audio_service fork (flutter clean + reinstall)",
                                    null,
                                )
                                return@post
                            }
                            if (!isAudioServiceReady()) {
                                Log.w(TAG, "updateDisplay skipped: AudioService not ready")
                                result.success(null)
                                return@post
                            }
                            setYeahLyricsDisplayManaged(true)
                            val changed = updateNotificationDisplayText(title, subtitle)
                            if (changed) {
                                Log.d(TAG, "updateDisplay title=${title?.take(24)}")
                            }
                            result.success(null)
                        } catch (t: Throwable) {
                            Log.w(TAG, "updateDisplay failed", t)
                            result.error(
                                "UPDATE_DISPLAY_FAILED",
                                t.message ?: t.toString(),
                                null,
                            )
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
