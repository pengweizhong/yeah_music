package com.pengwz.yeah_music

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import android.view.KeyEvent

/**
 * 后台/锁屏下接收媒体键，并转发到 Flutter 侧的线控手势处理。
 */
class WireRemoteMediaButtonReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "WireRemoteReceiver"
    }

    override fun onReceive(context: Context, intent: Intent?) {
        if (intent?.action != Intent.ACTION_MEDIA_BUTTON) return
        WireRemoteDiagnostics.init(context)
        WireRemoteHolder.ensureAttached(context)
        val event = intent.getParcelableExtra<KeyEvent>(Intent.EXTRA_KEY_EVENT)
        if (event != null) {
            Log.d(
                TAG,
                "onReceive action=${event.action} keyCode=${event.keyCode} repeat=${event.repeatCount}",
            )
            WireRemoteDiagnostics.append(
                "receiver action=${event.action} keyCode=${event.keyCode} repeat=${event.repeatCount}",
            )
        } else {
            Log.w(TAG, "onReceive without KeyEvent")
            WireRemoteDiagnostics.append("receiver without KeyEvent")
        }
        val consumedByWireRemote = WireRemoteHolder.onMediaButtonBroadcastEvent(event)
        WireRemoteDiagnostics.append("receiver consumedByWireRemote=$consumedByWireRemote")

        // 线控耳机常把多击都发成 HEADSETHOOK。若不拦截，系统会把每击当 play/pause，
        // 导致双击/三击映射被吞。已被自定义线控消费的事件不再交给系统会话。
        val shouldAbortForHook =
            consumedByWireRemote &&
                event?.action == KeyEvent.ACTION_DOWN &&
                (event.keyCode == KeyEvent.KEYCODE_HEADSETHOOK ||
                    event.keyCode == KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE)
        if (shouldAbortForHook && isOrderedBroadcast) {
            Log.d(TAG, "abort ordered broadcast for hook/playPause key")
            WireRemoteDiagnostics.append("receiver abort ordered broadcast")
            abortBroadcast()
        }
        if (consumedByWireRemote) return

        forwardToAudioServiceMediaButtonReceiver(context, intent)
    }

    private fun forwardToAudioServiceMediaButtonReceiver(context: Context, intent: Intent) {
        try {
            val receiver =
                Class
                    .forName("com.ryanheise.audioservice.MediaButtonReceiver")
                    .getDeclaredConstructor()
                    .newInstance() as BroadcastReceiver
            receiver.onReceive(context, intent)
        } catch (t: Throwable) {
            Log.w(TAG, "forward to audio_service MediaButtonReceiver failed", t)
            WireRemoteDiagnostics.append("forward to audio_service receiver failed: ${t.message}")
        }
    }
}
