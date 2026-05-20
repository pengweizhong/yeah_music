package com.ryanheise.audioservice;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.media.AudioManager;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.os.ParcelFileDescriptor;
import android.os.PowerManager;
import android.support.v4.media.MediaBrowserCompat;
import android.support.v4.media.MediaDescriptionCompat;
import android.support.v4.media.MediaMetadataCompat;
import android.support.v4.media.RatingCompat;
import android.support.v4.media.session.MediaControllerCompat;
import android.support.v4.media.session.MediaSessionCompat;
import android.support.v4.media.session.PlaybackStateCompat;
import android.util.LruCache;
import android.util.Size;
import android.view.KeyEvent;
import android.view.View;
import android.widget.RemoteViews;

import androidx.annotation.RequiresApi;
import androidx.core.app.ServiceCompat;
import androidx.core.content.ContextCompat;
import androidx.core.app.NotificationCompat;
import androidx.media.MediaBrowserServiceCompat;
import androidx.media.VolumeProviderCompat;
import androidx.media.app.NotificationCompat.MediaStyle;
import androidx.media.utils.MediaConstants;

import java.io.FileDescriptor;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.embedding.engine.FlutterEngine;

public class AudioService extends MediaBrowserServiceCompat {
    public static final String CONTENT_STYLE_SUPPORTED = "android.media.browse.CONTENT_STYLE_SUPPORTED";
    public static final String CONTENT_STYLE_PLAYABLE_HINT = "android.media.browse.CONTENT_STYLE_PLAYABLE_HINT";
    public static final String CONTENT_STYLE_BROWSABLE_HINT = "android.media.browse.CONTENT_STYLE_BROWSABLE_HINT";
    public static final int CONTENT_STYLE_LIST_ITEM_HINT_VALUE = 1;
    public static final int CONTENT_STYLE_GRID_ITEM_HINT_VALUE = 2;
    public static final int CONTENT_STYLE_CATEGORY_LIST_ITEM_HINT_VALUE = 3;
    public static final int CONTENT_STYLE_CATEGORY_GRID_ITEM_HINT_VALUE = 4;

    private static final String SHARED_PREFERENCES_NAME = "audio_service_preferences";

    private static final int NOTIFICATION_ID = 1124;
    private static final int REQUEST_CONTENT_INTENT = 1000;
    public static final String NOTIFICATION_CLICK_ACTION = "com.ryanheise.audioservice.NOTIFICATION_CLICK";
    public static final String CUSTOM_ACTION_STOP = "com.ryanheise.audioservice.action.STOP";
    public static final String CUSTOM_ACTION_FAST_FORWARD = "com.ryanheise.audioservice.action.FAST_FORWARD";
    public static final String CUSTOM_ACTION_REWIND = "com.ryanheise.audioservice.action.REWIND";
    private static final String BROWSABLE_ROOT_ID = "root";
    private static final String RECENT_ROOT_ID = "recent";
    // See the comment in onMediaButtonEvent to understand how the BYPASS keycodes work.
    // We hijack KEYCODE_MUTE and KEYCODE_MEDIA_RECORD since the media session subsystem
    // considers these keycodes relevant to media playback and will pass them on to us.
    public static final int KEYCODE_BYPASS_PLAY = KeyEvent.KEYCODE_MUTE;
    public static final int KEYCODE_BYPASS_PAUSE = KeyEvent.KEYCODE_MEDIA_RECORD;
    public static final int MAX_COMPACT_ACTIONS = 3;
    private static final long AUTO_ENABLED_ACTIONS = PlaybackStateCompat.ACTION_STOP
            | PlaybackStateCompat.ACTION_PAUSE
            | PlaybackStateCompat.ACTION_PLAY
            | PlaybackStateCompat.ACTION_REWIND
            // Auto-enabling these is bad for Android Auto since it forces the
            // previous/next buttons to always show.
            //| PlaybackStateCompat.ACTION_SKIP_TO_PREVIOUS
            //| PlaybackStateCompat.ACTION_SKIP_TO_NEXT
            | PlaybackStateCompat.ACTION_FAST_FORWARD
            | PlaybackStateCompat.ACTION_SET_RATING
            // "seek" is the exception because it's the only action that
            // affects the appearance of the media notification, so we leave it
            // up to the plugin user whether to enable it (via systemActions).
            //| PlaybackStateCompat.ACTION_SEEK_TO
            | PlaybackStateCompat.ACTION_PLAY_PAUSE
            | PlaybackStateCompat.ACTION_PLAY_FROM_MEDIA_ID
            | PlaybackStateCompat.ACTION_PLAY_FROM_SEARCH
            | PlaybackStateCompat.ACTION_SKIP_TO_QUEUE_ITEM
            | PlaybackStateCompat.ACTION_PLAY_FROM_URI
            | PlaybackStateCompat.ACTION_PREPARE
            | PlaybackStateCompat.ACTION_PREPARE_FROM_MEDIA_ID
            | PlaybackStateCompat.ACTION_PREPARE_FROM_SEARCH
            | PlaybackStateCompat.ACTION_PREPARE_FROM_URI
            | PlaybackStateCompat.ACTION_SET_REPEAT_MODE
            | PlaybackStateCompat.ACTION_SET_SHUFFLE_MODE
            | PlaybackStateCompat.ACTION_SET_CAPTIONING_ENABLED;

    /** 通知栏紧凑区仅需上一曲/播放暂停/下一曲；勿含 QUEUE_ITEM/STOP 等（否则 Android 13+ 会显示列表/退出）。 */
    private static final long YEAH_NOTIFICATION_PLAYBACK_ACTIONS =
            PlaybackStateCompat.ACTION_PLAY
                    | PlaybackStateCompat.ACTION_PAUSE
                    | PlaybackStateCompat.ACTION_PLAY_PAUSE
                    | PlaybackStateCompat.ACTION_SKIP_TO_PREVIOUS
                    | PlaybackStateCompat.ACTION_SKIP_TO_NEXT;

    static AudioService instance;
    /** 与 Dart [MusicService.androidNotify*ExtraKey] 一致。 */
    private static final String YEAH_EXTRA_NOTIFY_SUBTITLE = "yeah.notify.subtitle";
    private static final String YEAH_EXTRA_NOTIFY_SONG_TITLE = "yeah.notify.songTitle";
    private static final String YEAH_EXTRA_NOTIFY_ARTIST = "yeah.notify.artist";

    /** 为 true 时 [setMetadata] 不覆盖 [DISPLAY_TITLE]/[DISPLAY_SUBTITLE]（由 [updateNotificationDisplayText] 独占）。 */
    private static volatile boolean yeahLyricsDisplayManaged = false;
    /** Yeah Music：关闭「通知与车载歌词」总开关时不展示媒体通知。 */
    private static volatile boolean yeahCarMediaNotificationEnabled = false;
    /** 歌词模式下通知栏主行缓存，避免 DISPLAY_TITLE 空窗时回退成曲名 [MediaDescription.getTitle]。 */
    private CharSequence yeahLastLyricDisplayTitle;
    private CharSequence yeahLastLyricDisplaySubtitle;
    private String yeahLastLyricMediaId;
    /** 真实曲名（与 [METADATA_KEY_TITLE] 分离；托管时 TITLE 镜像为当前歌词以免系统闪曲名）。 */
    private String yeahCanonicalSongTitle;
    private CharSequence yeahPendingLyricTitle;
    private CharSequence yeahPendingLyricSubtitle;
    private MediaMetadataCompat yeahPendingSessionMeta;
    private final Runnable yeahManagedLyricTickRunner = new Runnable() {
        @Override
        public void run() {
            if (yeahPendingSessionMeta == null) return;
            yeahApplyManagedLyricTick(
                    yeahPendingLyricTitle, yeahPendingLyricSubtitle, yeahPendingSessionMeta);
        }
    };
    private final Runnable yeahLyricFlashGuardRunnable = new Runnable() {
        @Override
        public void run() {
            updateNotification();
        }
    };
    private final Runnable yeahNotificationUpdateRunnable = new Runnable() {
        @Override
        public void run() {
            updateNotification();
        }
    };
    private static PendingIntent contentIntent;
    private static ServiceListener listener;
    private static List<MediaSessionCompat.QueueItem> queue = new ArrayList<>();
    private static final Map<String, MediaMetadataCompat> mediaMetadataCache = new HashMap<>();

    public static void init(ServiceListener listener) {
        AudioService.listener = listener;
    }

    public static int toKeyCode(long action) {
        if (action == PlaybackStateCompat.ACTION_PLAY) {
            return KEYCODE_BYPASS_PLAY;
        } else if (action == PlaybackStateCompat.ACTION_PAUSE) {
            return KEYCODE_BYPASS_PAUSE;
        } else {
            return PlaybackStateCompat.toKeyCode(action);
        }
    }

    MediaMetadataCompat createMediaMetadata(String mediaId, String title, String album, String artist, String genre, Long duration, String artUri, Boolean playable, String displayTitle, String displaySubtitle, String displayDescription, RatingCompat rating, Map<?, ?> extras) {
        MediaMetadataCompat.Builder builder = new MediaMetadataCompat.Builder()
                .putString(MediaMetadataCompat.METADATA_KEY_MEDIA_ID, mediaId)
                .putString(MediaMetadataCompat.METADATA_KEY_TITLE, title);
        if (album != null)
            builder.putString(MediaMetadataCompat.METADATA_KEY_ALBUM, album);
        if (artist != null)
            builder.putString(MediaMetadataCompat.METADATA_KEY_ARTIST, artist);
        if (genre != null)
            builder.putString(MediaMetadataCompat.METADATA_KEY_GENRE, genre);
        if (duration != null)
            builder.putLong(MediaMetadataCompat.METADATA_KEY_DURATION, duration);
        if (artUri != null) {
            builder.putString(MediaMetadataCompat.METADATA_KEY_DISPLAY_ICON_URI, artUri);
        }
        if (playable != null)
            builder.putLong("playable_long", playable ? 1 : 0);
        if (displayTitle != null)
            builder.putString(MediaMetadataCompat.METADATA_KEY_DISPLAY_TITLE, displayTitle);
        if (displaySubtitle != null)
            builder.putString(MediaMetadataCompat.METADATA_KEY_DISPLAY_SUBTITLE, displaySubtitle);
        if (displayDescription != null)
            builder.putString(MediaMetadataCompat.METADATA_KEY_DISPLAY_DESCRIPTION, displayDescription);
        if (rating != null) {
            builder.putRating(MediaMetadataCompat.METADATA_KEY_RATING, rating);
        }
        if (extras != null) {
            for (Object o : extras.keySet()) {
                String key = (String)o;
                Object value = extras.get(key);
                if (value instanceof Long) {
                    builder.putLong(key, (Long)value);
                } else if (value instanceof Integer) {
                    builder.putLong(key, (long)((Integer)value));
                } else if (value instanceof String) {
                    builder.putString(key, (String)value);
                } else if (value instanceof Boolean) {
                    builder.putLong(key, (Boolean)value ? 1 : 0);
                } else if (value instanceof Double) {
                    builder.putString(key, value.toString());
                }
            }
        }
        MediaMetadataCompat mediaMetadata = builder.build();
        mediaMetadataCache.put(mediaId, mediaMetadata);
        return mediaMetadata;
    }

    static MediaMetadataCompat getMediaMetadata(String mediaId) {
        return mediaMetadataCache.get(mediaId);
    }

    Bitmap loadArtBitmap(String artUriString, String loadThumbnailUri) {
        Bitmap bitmap = artBitmapCache.get(artUriString);
        if (bitmap != null) return bitmap;
        try {
            // There are 3 cases handled by this function:
            //   1. content URI with openFileDescriptor
            //   2. content URI with loadThumbnail (when Android >= Q and specified by the config)
            //   3. not content URI - loading from the file, or cache file created by the Dart side
            Uri artUri = Uri.parse(artUriString);
            boolean usesContentScheme = "content".equals(artUri.getScheme());
            FileDescriptor fileDescriptor = null;
            if (usesContentScheme) {
                try {
                    if (loadThumbnailUri != null && Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        Size defaultSize = new Size(192, 192);
                        bitmap = getContentResolver().loadThumbnail(
                                artUri,
                                new Size(config.artDownscaleWidth == -1
                                                ? defaultSize.getWidth()
                                                : config.artDownscaleWidth,
                                        config.artDownscaleHeight == -1
                                                ? defaultSize.getHeight()
                                                : config.artDownscaleHeight),
                                null);
                        if (bitmap == null) {
                            return null;
                        }
                    } else {
                        ParcelFileDescriptor parcelFileDescriptor = getContentResolver().openFileDescriptor(artUri, "r");
                        if (parcelFileDescriptor != null) {
                            fileDescriptor = parcelFileDescriptor.getFileDescriptor();
                        } else {
                            return null;
                        }
                    }
                } catch (FileNotFoundException ex) {
                    return null;
                } catch (IOException ex) {
                    return null;
                }
            }
            // Decode the image ourselves for scenarios 1 and 3 (see the comment above).
            if (!usesContentScheme || fileDescriptor != null) {
                if (config.artDownscaleWidth != -1) {
                    BitmapFactory.Options options = new BitmapFactory.Options();
                    options.inJustDecodeBounds = true;
                    if (fileDescriptor != null) {
                        BitmapFactory.decodeFileDescriptor(fileDescriptor, null, options);
                    } else {
                        BitmapFactory.decodeFile(artUri.getPath(), options);
                    }
                    options.inSampleSize = calculateInSampleSize(options, config.artDownscaleWidth, config.artDownscaleHeight);
                    options.inJustDecodeBounds = false;

                    if (fileDescriptor != null) {
                        bitmap = BitmapFactory.decodeFileDescriptor(fileDescriptor, null, options);
                    } else {
                        bitmap = BitmapFactory.decodeFile(artUri.getPath(), options);
                    }
                } else {
                    if (fileDescriptor != null) {
                        bitmap = BitmapFactory.decodeFileDescriptor(fileDescriptor);
                    } else {
                        bitmap = BitmapFactory.decodeFile(artUri.getPath());
                    }
                }
            }
            artBitmapCache.put(artUriString, bitmap);
            return bitmap;
        } catch (Exception e) {
            e.printStackTrace();
            return null;
        }
    }

    private static int calculateInSampleSize(BitmapFactory.Options options, int reqWidth, int reqHeight) {
        final int height = options.outHeight;
        final int width = options.outWidth;
        int inSampleSize = 1;

        if (height > reqHeight || width > reqWidth) {
            final int halfHeight = height / 2;
            final int halfWidth = width / 2;
            while ((halfHeight / inSampleSize) >= reqHeight
                    && (halfWidth / inSampleSize) >= reqWidth) {
                inSampleSize *= 2;
            }
        }

        return inSampleSize;
    }

    private FlutterEngine flutterEngine;
    private AudioServiceConfig config;
    private PowerManager.WakeLock wakeLock;
    private MediaSessionCompat mediaSession;
    private MediaSessionCallback mediaSessionCallback;
    private List<MediaControl> controls = new ArrayList<>();
    private List<NotificationCompat.Action> nativeActions = new ArrayList<>();
    private List<PlaybackStateCompat.CustomAction> customActions = new ArrayList<>();
    private int[] compactActionIndices;
    private MediaMetadataCompat mediaMetadata;
    private Bitmap artBitmap;
    /// 封面文件未变时仅更新歌词/标题文字，避免高频 decode 造成通知「攒一批再跳」。
    private String lastArtCacheFilePath;
    private String notificationChannelId;
    private LruCache<String, Bitmap> artBitmapCache;
    private boolean playing = false;
    private AudioProcessingState processingState = AudioProcessingState.idle;
    private int repeatMode;
    private int shuffleMode;
    private boolean notificationCreated;
    private final Handler handler = new Handler(Looper.getMainLooper());
    private VolumeProviderCompat volumeProvider;

    public AudioProcessingState getProcessingState() {
        return processingState;
    }

    public boolean isPlaying() {
        return playing;
    }

    public int getRepeatMode() {
        return repeatMode;
    }

    public int getShuffleMode() {
        return shuffleMode;
    }

    @Override
    public void onCreate() {
        super.onCreate();
        instance = this;
        repeatMode = 0;
        shuffleMode = 0;
        notificationCreated = false;
        playing = false;
        processingState = AudioProcessingState.idle;
        mediaSession = new MediaSessionCompat(this, "media-session");

        configure(new AudioServiceConfig(getApplicationContext()));

        mediaSession.setFlags(MediaSessionCompat.FLAG_HANDLES_QUEUE_COMMANDS);
        PlaybackStateCompat.Builder stateBuilder = new PlaybackStateCompat.Builder()
                .setActions(AUTO_ENABLED_ACTIONS);
        mediaSession.setPlaybackState(stateBuilder.build());
        mediaSession.setCallback(mediaSessionCallback = new MediaSessionCallback());
        setSessionToken(mediaSession.getSessionToken());
        mediaSession.setQueue(queue);

        PowerManager pm = (PowerManager)getSystemService(Context.POWER_SERVICE);
        wakeLock = pm.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, AudioService.class.getName());

        // Get max available VM memory, exceeding this amount will throw an
        // OutOfMemory exception. Stored in kilobytes as LruCache takes an
        // int in its constructor.
        final int maxMemory = (int)(Runtime.getRuntime().maxMemory() / 1024);

        // Use 1/8th of the available memory for this memory cache.
        final int cacheSize = maxMemory / 8;

        artBitmapCache = new LruCache<String, Bitmap>(cacheSize) {
            @Override
            protected int sizeOf(String key, Bitmap bitmap) {
                // The cache size will be measured in kilobytes rather than
                // number of items.
                return bitmap.getByteCount() / 1024;
            }
        };

        flutterEngine = AudioServicePlugin.getFlutterEngine(this);
        System.out.println("flutterEngine warmed up");
    }

    @Override
    public int onStartCommand(final Intent intent, int flags, int startId) {
        MediaButtonReceiver.handleIntent(mediaSession, intent);
        return START_NOT_STICKY;
    }

    public void stop() {
        deactivateMediaSession();
        stopSelf();
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        if (listener != null) {
            listener.onDestroy();
            listener = null;
        }
        mediaMetadata = null;
        artBitmap = null;
        queue.clear();
        mediaMetadataCache.clear();
        controls.clear();
        artBitmapCache.evictAll();
        compactActionIndices = null;
        releaseMediaSession();
        ServiceCompat.stopForeground(this, config.androidResumeOnClick ? STOP_FOREGROUND_DETACH : STOP_FOREGROUND_REMOVE);
        // This still does not solve the Android 11 problem.
        // if (notificationCreated) {
        //     NotificationManager notificationManager = getNotificationManager();
        //     notificationManager.cancel(NOTIFICATION_ID);
        // }
        releaseWakeLock();
        instance = null;
        notificationCreated = false;
    }

    public AudioServiceConfig getConfig() {
        return config;
    }

    public void configure(AudioServiceConfig config) {
        this.config = config;
        notificationChannelId = (config.androidNotificationChannelId != null)
            ? config.androidNotificationChannelId
            : getApplication().getPackageName() + ".channel";

        if (config.activityClassName != null) {
            Context context = getApplicationContext();
            Intent intent = new Intent((String)null);
            intent.setComponent(new ComponentName(context, config.activityClassName));
            //Intent intent = new Intent(context, config.activityClassName);
            intent.setAction(NOTIFICATION_CLICK_ACTION);
            int flags = PendingIntent.FLAG_UPDATE_CURRENT;
            if (Build.VERSION.SDK_INT >= 23) {
                flags |= PendingIntent.FLAG_IMMUTABLE;
            }
            contentIntent = PendingIntent.getActivity(context, REQUEST_CONTENT_INTENT, intent, flags);
        } else {
            contentIntent = null;
        }
        if (!config.androidResumeOnClick) {
            mediaSession.setMediaButtonReceiver(null);
        }
    }

    int getResourceId(String resource) {
        String[] parts = resource.split("/");
        String resourceType = parts[0];
        String resourceName = parts[1];
        return getResources().getIdentifier(resourceName, resourceType, getApplicationContext().getPackageName());
    }

    NotificationCompat.Action createAction(String resource, String label, long actionCode) {
        int iconId = getResourceId(resource);
        return new NotificationCompat.Action(iconId, label,
                buildMediaButtonPendingIntent(actionCode));
    }

    private boolean needCustomMediaControl(MediaControl control) {
        return control.customAction != null;
    }

    private Bundle mapToBundle(Map<?, ?> map) {
        if (map == null) {
            return null;
        }
        Bundle bundle = new Bundle();
        for (Map.Entry<?, ?> entry : map.entrySet()) {
            String key = entry.getKey().toString();
            Object value = entry.getValue();
            if (value instanceof Integer) {
                bundle.putInt(key, (Integer)value);
            } else if (value instanceof Long) {
                bundle.putLong(key, (Long)value);
            } else {
                bundle.putString(key, value.toString());
            }
        }
        return bundle;
    }

    PlaybackStateCompat.CustomAction createCustomAction(MediaControl control) {
        int iconId = getResourceId(control.icon);
        if (control.customAction != null) {
            return new PlaybackStateCompat.CustomAction.Builder(control.customAction.name, control.label, iconId)
                .setExtras(mapToBundle(control.customAction.extras))
                .build();
        } else if (Build.VERSION.SDK_INT >= 33) {
            // Android 13 changes MediaControl behavior as documented here:
            // https://developer.android.com/about/versions/13/behavior-changes-13
            // The below actions will be added to slots 1-3, if included.
            // 1 - ACTION_PLAY, ACTION_PLAY
            // 2 - ACTION_SKIP_TO_PREVIOUS
            // 3 - ACTION_SKIP_TO_NEXT
            // Custom actions will use slots 2-5 if included.
            // - ACTION_STOP
            // - ACTION_FAST_FORWARD
            // - ACTION_REWIND
            if (control.actionCode == PlaybackStateCompat.ACTION_STOP) {
                return new PlaybackStateCompat.CustomAction.Builder(CUSTOM_ACTION_STOP, control.label, iconId).build();
            } else if (control.actionCode == PlaybackStateCompat.ACTION_FAST_FORWARD) {
                return new PlaybackStateCompat.CustomAction.Builder(CUSTOM_ACTION_FAST_FORWARD, control.label, iconId).build();
            } else if (control.actionCode == PlaybackStateCompat.ACTION_REWIND) {
                return new PlaybackStateCompat.CustomAction.Builder(CUSTOM_ACTION_REWIND, control.label, iconId).build();
            }
        }
        return null;
    }

    PendingIntent buildMediaButtonPendingIntent(long action) {
        int keyCode = toKeyCode(action);
        if (keyCode == KeyEvent.KEYCODE_UNKNOWN)
            return null;
        Intent intent = new Intent(this, MediaButtonReceiver.class);
        intent.setAction(Intent.ACTION_MEDIA_BUTTON);
        intent.putExtra(Intent.EXTRA_KEY_EVENT, new KeyEvent(KeyEvent.ACTION_DOWN, keyCode));
        int flags = 0;
        if (Build.VERSION.SDK_INT >= 23) {
            flags |= PendingIntent.FLAG_IMMUTABLE;
        }
        return PendingIntent.getBroadcast(this, keyCode, intent, flags);
    }

    PendingIntent buildDeletePendingIntent() {
        Intent intent = new Intent(this, MediaButtonReceiver.class);
        intent.setAction(MediaButtonReceiver.ACTION_NOTIFICATION_DELETE);
        int flags = 0;
        if (Build.VERSION.SDK_INT >= 23) {
            flags |= PendingIntent.FLAG_IMMUTABLE;
        }
        return PendingIntent.getBroadcast(this, 0, intent, flags);
    }

    void setState(List<MediaControl> controls, long actionBits, int[] compactActionIndices, AudioProcessingState processingState, boolean playing, long position, long bufferedPosition, float speed, long updateTime, Integer errorCode, String errorMessage, int repeatMode, int shuffleMode, boolean captioningEnabled, Long queueIndex) {
        boolean notificationChanged = false;
        if (!Arrays.equals(compactActionIndices, this.compactActionIndices)) {
            notificationChanged = true;
        }
        if (!controls.equals(this.controls)) {
            notificationChanged = true;
        }
        this.controls = controls;
        this.nativeActions.clear();
        this.customActions.clear();
        for (MediaControl control : controls) {
            final PlaybackStateCompat.CustomAction customAction = createCustomAction(control);
            if (customAction != null) {
                customActions.add(customAction);
            } else {
                nativeActions.add(createAction(control.icon, control.label, control.actionCode));
            }
        }
        this.compactActionIndices = compactActionIndices;
        boolean wasPlaying = this.playing;
        AudioProcessingState oldProcessingState = this.processingState;
        this.processingState = processingState;
        this.playing = playing;
        this.repeatMode = repeatMode;
        this.shuffleMode = shuffleMode;

        PlaybackStateCompat.Builder stateBuilder = new PlaybackStateCompat.Builder()
                .setActions(yeahNotificationPlaybackActions(actionBits))
                .setState(getPlaybackState(), position, speed, updateTime)
                .setBufferedPosition(bufferedPosition);

        for (PlaybackStateCompat.CustomAction action : this.customActions) {
            stateBuilder.addCustomAction(action);
        }

        if (queueIndex != null)
            stateBuilder.setActiveQueueItemId(queueIndex);
        if (errorCode != null && errorMessage != null)
            stateBuilder.setErrorMessage(errorCode, errorMessage);
        else if (errorMessage != null)
            stateBuilder.setErrorMessage(-987654, errorMessage);

        if (mediaMetadata != null) {
            // Update the progress bar in the browse view as content is playing as explained
            // here: https://developer.android.com/training/cars/media#browse-progress-bar
            Bundle extras = new Bundle();
            extras.putString(MediaConstants.PLAYBACK_STATE_EXTRAS_KEY_MEDIA_ID, mediaMetadata.getDescription().getMediaId());
            stateBuilder.setExtras(extras);
        }

        if (yeahCarMediaNotificationEnabled) {
            mediaSession.setPlaybackState(stateBuilder.build());
            mediaSession.setRepeatMode(repeatMode);
            mediaSession.setShuffleMode(shuffleMode);
            mediaSession.setCaptioningEnabled(captioningEnabled);
        }

        if (!wasPlaying && playing) {
            enterPlayingState();
        } else if (wasPlaying && !playing) {
            exitPlayingState();
        }

        if (oldProcessingState != AudioProcessingState.idle && processingState == AudioProcessingState.idle) {
            // TODO: Handle completed state as well?
            stop();
        } else if (processingState != AudioProcessingState.idle && notificationChanged) {
            updateNotification();
        }
    }

    public void setPlaybackInfo(int playbackType, Integer volumeControlType, Integer maxVolume, Integer volume) {
        if (playbackType == MediaControllerCompat.PlaybackInfo.PLAYBACK_TYPE_LOCAL) {
            // We have to wait 'til media2 before we can use AudioAttributes.
            mediaSession.setPlaybackToLocal(AudioManager.STREAM_MUSIC);
            volumeProvider = null;
        } else if (playbackType == MediaControllerCompat.PlaybackInfo.PLAYBACK_TYPE_REMOTE) {
            if (volumeProvider == null || volumeControlType != volumeProvider.getVolumeControl() || maxVolume != volumeProvider.getMaxVolume()) {
                volumeProvider = new VolumeProviderCompat(volumeControlType, maxVolume, volume) {
                    @Override
                    public void onSetVolumeTo(int volumeIndex) {
                        if (listener == null) return;
                        listener.onSetVolumeTo(volumeIndex);
                    }
                    @Override
                    public void onAdjustVolume(int direction) {
                        if (listener == null) return;
                        listener.onAdjustVolume(direction);
                    }
                };
            } else {
                volumeProvider.setCurrentVolume(volume);
            }
            mediaSession.setPlaybackToRemote(volumeProvider);
        } else {
            // silently ignore
        }
    }

    public int getPlaybackState() {
        switch (processingState) {
        case idle: return PlaybackStateCompat.STATE_NONE;
        case loading: return PlaybackStateCompat.STATE_CONNECTING;
        case buffering: return PlaybackStateCompat.STATE_BUFFERING;
        case ready: return playing ? PlaybackStateCompat.STATE_PLAYING : PlaybackStateCompat.STATE_PAUSED;
        case completed: return playing ? PlaybackStateCompat.STATE_PLAYING : PlaybackStateCompat.STATE_PAUSED;
        case error: return PlaybackStateCompat.STATE_ERROR;
        default: return PlaybackStateCompat.STATE_NONE;
        }
    }

    private void applyYeahCustomNotificationContent(
            NotificationCompat.Builder builder,
            CharSequence title,
            CharSequence subtitle) {
        if (title == null && subtitle == null) return;
        try {
            RemoteViews content =
                    new RemoteViews(getPackageName(), R.layout.yeah_media_notification);
            if (title != null) {
                content.setTextViewText(R.id.yeah_notify_title, title);
                content.setViewVisibility(R.id.yeah_notify_title, View.VISIBLE);
            } else {
                content.setViewVisibility(R.id.yeah_notify_title, View.GONE);
            }
            if (subtitle != null) {
                content.setTextViewText(R.id.yeah_notify_subtitle, subtitle);
                content.setViewVisibility(R.id.yeah_notify_subtitle, View.VISIBLE);
            } else {
                content.setViewVisibility(R.id.yeah_notify_subtitle, View.GONE);
            }
            builder.setCustomContentView(content);
            builder.setCustomBigContentView(content);
        } catch (Exception ignored) {}
        if (yeahLyricsDisplayManaged) {
            // 必须写入与 RemoteViews 相同的歌词，否则 MediaStyle 会回退显示 METADATA_KEY_TITLE（曲名）。
            if (title != null && title.length() > 0) builder.setContentTitle(title);
            if (subtitle != null && subtitle.length() > 0) builder.setContentText(subtitle);
        } else {
            if (title != null) builder.setContentTitle(title);
            if (subtitle != null) builder.setContentText(subtitle);
        }
    }

    /**
     * 紧凑区下标必须落在 [nativeActions] 内；Dart 误传控件列表下标时部分 OEM 会显示成列表/退出。
     */
    private int[] yeahSafeCompactActionIndices() {
        final int actionCount = nativeActions.size();
        if (actionCount == 0) {
            return new int[0];
        }
        if (compactActionIndices != null && compactActionIndices.length > 0) {
            final List<Integer> valid = new ArrayList<>();
            for (int idx : compactActionIndices) {
                if (idx >= 0 && idx < actionCount) {
                    valid.add(idx);
                }
            }
            if (!valid.isEmpty()) {
                final int n = Math.min(MAX_COMPACT_ACTIONS, valid.size());
                final int[] out = new int[n];
                for (int i = 0; i < n; i++) {
                    out[i] = valid.get(i);
                }
                return out;
            }
        }
        final int n = Math.min(MAX_COMPACT_ACTIONS, actionCount);
        final int[] out = new int[n];
        for (int i = 0; i < n; i++) {
            out[i] = i;
        }
        return out;
    }

    /**
     * 会话 [setActions] 仅暴露切歌/播放，避免 SystemUI 用 QUEUE_ITEM→列表、STOP→退出 占紧凑位。
     */
    private static long yeahNotificationPlaybackActions(long actionBits) {
        return YEAH_NOTIFICATION_PLAYBACK_ACTIONS
                | (actionBits & YEAH_NOTIFICATION_PLAYBACK_ACTIONS);
    }

    private void yeahResyncNotificationActions() {
        if (!notificationCreated) return;
        if (mediaMetadata != null) {
            final MediaMetadataCompat meta = artBitmap != null
                    ? putArtToMetadata(mediaMetadata)
                    : mediaMetadata;
            mediaSession.setMetadata(meta);
        }
        updateNotification();
        final PlaybackStateCompat current =
                mediaSession.getController().getPlaybackState();
        if (current != null) {
            mediaSession.setPlaybackState(
                    new PlaybackStateCompat.Builder(current).build());
        }
        updateNotification();
    }

    /**
     * 统一 MediaStyle：始终绑定会话并显示上一曲 / 播放暂停 / 下一曲，不用取消钮占位（部分 OEM 会显示成列表/退出）。
     */
    private void yeahApplyMediaNotificationStyle(NotificationCompat.Builder builder) {
        final int[] indices = yeahSafeCompactActionIndices();
        final MediaStyle style = new MediaStyle()
                .setMediaSession(mediaSession.getSessionToken());
        if (indices.length > 0) {
            style.setShowActionsInCompactView(indices);
        }
        style.setShowCancelButton(false);
        if (config.androidNotificationOngoing) {
            builder.setOngoing(true);
        }
        builder.setStyle(style);
    }

    private Notification buildNotification() {
        NotificationCompat.Builder builder = getNotificationBuilder();
        if (mediaMetadata != null) {
            MediaDescriptionCompat description = mediaMetadata.getDescription();
            CharSequence[] lines = new CharSequence[2];
            yeahResolveNotificationDisplayLines(description, lines);
            applyYeahCustomNotificationContent(builder, lines[0], lines[1]);
            if (description.getDescription() != null)
                builder.setSubText(description.getDescription());
            synchronized (this) {
                if (artBitmap != null)
                    builder.setLargeIcon(artBitmap);
            }
        }
        if (config.androidNotificationClickStartsActivity)
            builder.setContentIntent(mediaSession.getController().getSessionActivity());
        // TODO: Look at setColorized
        if (config.notificationColor != -1)
            builder.setColor(config.notificationColor);
        for (NotificationCompat.Action action : nativeActions) {
            builder.addAction(action);
        }
        yeahApplyMediaNotificationStyle(builder);
        return builder.build();
    }

    private NotificationManager getNotificationManager() {
        return (NotificationManager)getSystemService(Context.NOTIFICATION_SERVICE);
    }

    private /*synchronized*/ NotificationCompat.Builder getNotificationBuilder() {
        // This local variable could be commented out and replaced by an
        // instance variable if we want to reuse the builder instance. However,
        // there doesn't turn out to be much benefit to this since we don't
        // actually reuse any of the previous notification values when setting
        // a new notification.
        NotificationCompat.Builder notificationBuilder = null;
        if (notificationBuilder == null) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                createChannel();
            notificationBuilder = new NotificationCompat.Builder(this, notificationChannelId)
                    .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                    .setShowWhen(false)
                    .setDeleteIntent(buildDeletePendingIntent())
            ;
        }
        int iconId = getResourceId(config.androidNotificationIcon);
        notificationBuilder.setSmallIcon(iconId);
        return notificationBuilder;
    }

    public void handleDeleteNotification() {
        if (listener == null) return;
        listener.onClose();
    }


    @RequiresApi(Build.VERSION_CODES.O)
    private void createChannel() {
        NotificationManager notificationManager = getNotificationManager();
        NotificationChannel channel = notificationManager.getNotificationChannel(notificationChannelId);
        if (channel == null) {
            channel = new NotificationChannel(notificationChannelId, config.androidNotificationChannelName, NotificationManager.IMPORTANCE_LOW);
            channel.setShowBadge(config.androidShowNotificationBadge);
            if (config.androidNotificationChannelDescription != null)
                channel.setDescription(config.androidNotificationChannelDescription);
            notificationManager.createNotificationChannel(channel);
        }
    }

    private void updateNotification() {
        if (!yeahCarMediaNotificationEnabled) {
            dismissYeahCarNotification();
            return;
        }
        if (notificationCreated) {
            getNotificationManager().notify(NOTIFICATION_ID, buildNotification());
        }
    }

    private void postNotificationUpdate() {
        if (!yeahCarMediaNotificationEnabled) return;
        if (!notificationCreated) return;
        handler.removeCallbacks(yeahNotificationUpdateRunnable);
        handler.post(yeahNotificationUpdateRunnable);
    }

    private void dismissYeahCarNotification() {
        handler.removeCallbacks(yeahNotificationUpdateRunnable);
        handler.removeCallbacks(yeahLyricFlashGuardRunnable);
        handler.removeCallbacks(yeahManagedLyricTickRunner);
        if (!notificationCreated) return;
        getNotificationManager().cancel(NOTIFICATION_ID);
        ServiceCompat.stopForeground(this, ServiceCompat.STOP_FOREGROUND_REMOVE);
        notificationCreated = false;
    }

    private void enterPlayingState() {
        if (!yeahCarMediaNotificationEnabled) {
            dismissYeahCarNotification();
            acquireWakeLock();
            return;
        }
        ContextCompat.startForegroundService(
                this, new Intent(AudioService.this, AudioService.class));
        if (!mediaSession.isActive()) {
            mediaSession.setActive(true);
        }

        acquireWakeLock();
        mediaSession.setSessionActivity(contentIntent);
        internalStartForeground();
    }

    private void exitPlayingState() {
        if (config.androidStopForegroundOnPause) {
            exitForegroundState();
        }
    }

    private void exitForegroundState() {
        ServiceCompat.stopForeground(this, STOP_FOREGROUND_DETACH);
        releaseWakeLock();
    }

    private void internalStartForeground() {
        startForeground(NOTIFICATION_ID, buildNotification());
        notificationCreated = true;
    }

    private void acquireWakeLock() {
        if (!wakeLock.isHeld())
            wakeLock.acquire();
    }

    private void releaseWakeLock() {
        if (wakeLock.isHeld())
            wakeLock.release();
    }

    private void activateMediaSession() {
        if (!mediaSession.isActive())
            mediaSession.setActive(true);
    }

    private void deactivateMediaSession() {
        if (mediaSession.isActive()) {
            mediaSession.setActive(false);
        }
        // Force cancellation of the notification
        getNotificationManager().cancel(NOTIFICATION_ID);
    }

    private void releaseMediaSession() {
        if (mediaSession == null) return;
        deactivateMediaSession();
        mediaSession.release();
        mediaSession = null;
    }

    /**
     * Updates queue.
     * Gets called from background thread.
     */
    synchronized void setQueue(List<MediaSessionCompat.QueueItem> queue) {
        AudioService.queue = queue;
        mediaSession.setQueue(queue);
    }

    void playMediaItem(MediaDescriptionCompat description) {
        mediaSessionCallback.onPlayMediaItem(description);
    }

    /**
     * Updates metadata, loads the art and updates the notification.
     * Gets called from background thread.
     * <p>
     * Also adds the loaded art bitmap to the MediaMetadata.
     * This is needed to display art in lock screen in versions
     * prior Android 11, in which this feature was removed.
     * <p>
     * See:
     *  - https://developer.android.com/guide/topics/media-apps/working-with-a-media-session#album_artwork
     *  - https://9to5google.com/2020/08/02/android-11-lockscreen-art/
     */
    public static void setYeahCarMediaNotificationEnabled(boolean enabled) {
        yeahCarMediaNotificationEnabled = enabled;
        if (instance == null) return;
        instance.handler.post(() -> {
            if (enabled) {
                if (!instance.mediaSession.isActive()) {
                    instance.mediaSession.setActive(true);
                }
                if (instance.playing
                        && instance.processingState != AudioProcessingState.idle) {
                    ContextCompat.startForegroundService(
                            instance, new Intent(instance, AudioService.class));
                    instance.internalStartForeground();
                    instance.yeahRepublishSessionMetadataIfNeeded();
                    instance.updateNotification();
                }
            } else {
                instance.dismissYeahCarNotification();
                instance.mediaSession.setActive(false);
            }
        });
    }

    private void yeahRepublishSessionMetadataIfNeeded() {
        if (!yeahCarMediaNotificationEnabled || mediaMetadata == null) return;
        final MediaMetadataCompat meta = artBitmap != null
                ? putArtToMetadata(mediaMetadata)
                : mediaMetadata;
        mediaSession.setMetadata(meta);
    }

    private void yeahPublishMetadataToSession(MediaMetadataCompat mediaMetadata) {
        if (!yeahCarMediaNotificationEnabled) return;
        mediaSession.setMetadata(mediaMetadata);
        postNotificationUpdate();
    }

    public static void setYeahLyricsDisplayManaged(boolean managed) {
        yeahLyricsDisplayManaged = managed;
        if (instance == null) return;
        if (managed) {
            synchronized (instance) {
                if (instance.mediaMetadata != null) {
                    instance.yeahCaptureCanonicalSongTitle(instance.mediaMetadata);
                }
            }
            instance.handler.post(() -> {
                if (instance.notificationCreated) {
                    instance.yeahResyncNotificationActions();
                }
            });
            return;
        }
        instance.yeahLastLyricDisplayTitle = null;
        instance.yeahLastLyricDisplaySubtitle = null;
        instance.yeahLastLyricMediaId = null;
        instance.handler.removeCallbacks(instance.yeahManagedLyricTickRunner);
        instance.handler.removeCallbacks(instance.yeahLyricFlashGuardRunnable);
        synchronized (instance) {
            instance.yeahRestoreCanonicalSongTitleOnSession();
        }
        instance.handler.post(() -> {
            if (instance.notificationCreated) {
                instance.yeahResyncNotificationActions();
            }
        });
    }

    private void yeahSyncLastLyricMediaId(String mediaId) {
        if (mediaId == null) return;
        if (yeahLastLyricMediaId != null && !yeahLastLyricMediaId.equals(mediaId)) {
            yeahLastLyricDisplayTitle = null;
            yeahLastLyricDisplaySubtitle = null;
            yeahCanonicalSongTitle = null;
        }
        yeahLastLyricMediaId = mediaId;
    }

    private void yeahCaptureCanonicalSongTitle(MediaMetadataCompat meta) {
        if (meta == null || yeahCanonicalSongTitle != null) return;
        final String title = meta.getString(MediaMetadataCompat.METADATA_KEY_TITLE);
        if (title == null || title.isEmpty()) return;
        final CharSequence display =
                meta.getText(MediaMetadataCompat.METADATA_KEY_DISPLAY_TITLE);
        if (yeahLyricsDisplayManaged && display != null && display.length() > 0) {
            if (title.contentEquals(display.toString())) return;
            if (yeahLastLyricDisplayTitle != null
                    && title.contentEquals(yeahLastLyricDisplayTitle.toString())) {
                return;
            }
        }
        if (display != null && !display.toString().contentEquals(title)) {
            yeahCanonicalSongTitle = title;
            return;
        }
        yeahCanonicalSongTitle = title;
    }

    private CharSequence yeahManagedSongTitleForFilter() {
        if (yeahCanonicalSongTitle != null) return yeahCanonicalSongTitle;
        if (mediaMetadata == null) return null;
        return mediaMetadata.getString(MediaMetadataCompat.METADATA_KEY_TITLE);
    }

    /**
     * 托管歌词时把 [METADATA_KEY_TITLE] 设为当前歌词行，避免 SystemUI 在 setMetadata 间隙读曲名闪一下。
     */
    private MediaMetadataCompat yeahMirrorManagedLyricSessionTitle(MediaMetadataCompat meta) {
        if (!yeahLyricsDisplayManaged || meta == null) return meta;
        yeahCaptureCanonicalSongTitle(meta);
        CharSequence lyric = meta.getText(MediaMetadataCompat.METADATA_KEY_DISPLAY_TITLE);
        lyric = yeahFilterManagedLyricTitle(lyric, meta.getDescription());
        if (lyric == null || lyric.length() == 0) lyric = yeahLastLyricDisplayTitle;
        if (lyric == null || lyric.length() == 0) return meta;
        final String lyricStr = lyric.toString();
        final CharSequence canon = yeahManagedSongTitleForFilter();
        if (canon != null && lyricStr.contentEquals(canon.toString())) {
            if (yeahLastLyricDisplayTitle != null && yeahLastLyricDisplayTitle.length() > 0) {
                return new MediaMetadataCompat.Builder(meta)
                        .putString(MediaMetadataCompat.METADATA_KEY_TITLE,
                                yeahLastLyricDisplayTitle.toString())
                        .build();
            }
            return meta;
        }
        return new MediaMetadataCompat.Builder(meta)
                .putString(MediaMetadataCompat.METADATA_KEY_TITLE, lyricStr)
                .build();
    }

    private void yeahRestoreCanonicalSongTitleOnSession() {
        if (mediaMetadata == null) {
            yeahCanonicalSongTitle = null;
            return;
        }
        String songTitle = yeahCanonicalSongTitle;
        if (songTitle == null || songTitle.isEmpty()) {
            songTitle = mediaMetadata.getString(MediaMetadataCompat.METADATA_KEY_TITLE);
        }
        if (songTitle == null || songTitle.isEmpty()) {
            yeahCanonicalSongTitle = null;
            return;
        }
        final String realArtist = mediaMetadata.getString(YEAH_EXTRA_NOTIFY_ARTIST);
        final String artistForSession = (realArtist != null && realArtist.length() > 0)
                ? realArtist
                : mediaMetadata.getString(MediaMetadataCompat.METADATA_KEY_ARTIST);
        final MediaMetadataCompat.Builder builder = new MediaMetadataCompat.Builder(mediaMetadata)
                .putString(MediaMetadataCompat.METADATA_KEY_TITLE, songTitle)
                .putString(MediaMetadataCompat.METADATA_KEY_DISPLAY_TITLE, songTitle);
        if (artistForSession != null) {
            builder.putString(MediaMetadataCompat.METADATA_KEY_ARTIST, artistForSession);
            builder.putString(MediaMetadataCompat.METADATA_KEY_DISPLAY_SUBTITLE, artistForSession);
            builder.putString(YEAH_EXTRA_NOTIFY_SUBTITLE, artistForSession);
        } else {
            builder.putString(MediaMetadataCompat.METADATA_KEY_DISPLAY_SUBTITLE, "");
            builder.putString(YEAH_EXTRA_NOTIFY_SUBTITLE, "");
        }
        final MediaMetadataCompat restored = builder.build();
        mediaMetadata = restored;
        yeahCanonicalSongTitle = null;
        final String mediaId = restored.getString(MediaMetadataCompat.METADATA_KEY_MEDIA_ID);
        if (mediaId != null) {
            mediaMetadataCache.put(mediaId, restored);
        }
        // 不在此处 setMetadata：Android 13+ 会先按会话动作重绘成列表/退出；由
        // [yeahResyncNotificationActions] 先刷带紧凑位的通知再同步会话。
    }

    private void yeahRememberLyricDisplay(CharSequence title, CharSequence subtitle) {
        if (title != null && title.length() > 0) yeahLastLyricDisplayTitle = title;
        if (subtitle != null && subtitle.length() > 0) yeahLastLyricDisplaySubtitle = subtitle;
    }

    /** 通知副标题：优先读 Dart 写入的 extra（歌词开时为「歌名 - 歌手」）。 */
    private CharSequence yeahNotifySubtitleFromMetadata(MediaMetadataCompat meta) {
        if (meta == null) return null;
        final String fromExtra = meta.getString(YEAH_EXTRA_NOTIFY_SUBTITLE);
        if (fromExtra != null && fromExtra.length() > 0) return fromExtra;
        final CharSequence displaySub =
                meta.getText(MediaMetadataCompat.METADATA_KEY_DISPLAY_SUBTITLE);
        if (displaySub != null && displaySub.length() > 0) return displaySub;
        if (!yeahLyricsDisplayManaged) {
            final String artist = meta.getString(MediaMetadataCompat.METADATA_KEY_ARTIST);
            if (artist != null && artist.length() > 0) return artist;
        }
        return null;
    }

    /**
     * ColorOS 等第二行读 [METADATA_KEY_ARTIST]；歌词托管时把副标题（歌名 - 歌手）同步进 ARTIST，
     * 真实歌手保存在 [YEAH_EXTRA_NOTIFY_ARTIST]。
     */
    private MediaMetadataCompat yeahFinalizeNotificationMetadata(MediaMetadataCompat meta) {
        if (meta == null) return null;
        final CharSequence sub = yeahNotifySubtitleFromMetadata(meta);
        if (sub == null || sub.length() == 0) return meta;
        final String subStr = sub.toString();
        final MediaMetadataCompat.Builder builder = new MediaMetadataCompat.Builder(meta)
                .putString(MediaMetadataCompat.METADATA_KEY_DISPLAY_SUBTITLE, subStr)
                .putString(YEAH_EXTRA_NOTIFY_SUBTITLE, subStr);
        if (yeahLyricsDisplayManaged) {
            builder.putString(MediaMetadataCompat.METADATA_KEY_ARTIST, subStr);
        }
        return builder.build();
    }

    /** 歌词模式下 DISPLAY_TITLE 不得与曲名 [METADATA_KEY_TITLE] 相同。 */
    private CharSequence yeahFilterManagedLyricTitle(
            CharSequence displayTitle, MediaDescriptionCompat description) {
        if (!yeahLyricsDisplayManaged) return displayTitle;
        if (displayTitle == null || displayTitle.length() == 0) {
            return yeahLastLyricDisplayTitle;
        }
        final CharSequence songTitle = yeahManagedSongTitleForFilter();
        if (songTitle != null && displayTitle.toString().contentEquals(songTitle.toString())) {
            return yeahLastLyricDisplayTitle;
        }
        return displayTitle;
    }

    /** 更新歌词缓存后走 [buildNotification]，与关歌词时同一套按钮布局。 */
    private void yeahPublishLyricNotification(CharSequence title, CharSequence subtitle) {
        if (!notificationCreated || mediaMetadata == null) return;
        MediaDescriptionCompat description = mediaMetadata.getDescription();
        title = yeahFilterManagedLyricTitle(title, description);
        if (title != null && title.length() > 0) yeahLastLyricDisplayTitle = title;
        if (subtitle != null && subtitle.length() > 0) yeahLastLyricDisplaySubtitle = subtitle;
        updateNotification();
    }

    /**
     * 换行：先刷歌词通知，再 setMetadata（部分机型依赖会话元数据才刷新），最后再刷一次歌词盖住曲名闪帧。
     */
    private void yeahApplyManagedLyricTick(
            CharSequence notifyTitle,
            CharSequence notifySubtitle,
            MediaMetadataCompat sessionMetadata) {
        sessionMetadata = yeahMirrorManagedLyricSessionTitle(sessionMetadata);
        this.mediaMetadata = sessionMetadata;
        yeahPublishLyricNotification(notifyTitle, notifySubtitle);
        if (artBitmap != null) {
            mediaSession.setMetadata(putArtToMetadata(sessionMetadata));
        } else {
            mediaSession.setMetadata(sessionMetadata);
        }
        yeahPublishLyricNotification(notifyTitle, notifySubtitle);
        handler.removeCallbacks(yeahLyricFlashGuardRunnable);
        handler.postDelayed(yeahLyricFlashGuardRunnable, 48);
    }

    /**
     * 解析通知栏展示文案。歌词托管时主行只用 DISPLAY_TITLE / 缓存歌词，绝不回退曲名。
     */
    private void yeahResolveNotificationDisplayLines(
            MediaDescriptionCompat description,
            CharSequence[] out) {
        CharSequence title = mediaMetadata.getText(MediaMetadataCompat.METADATA_KEY_DISPLAY_TITLE);
        CharSequence subtitle = yeahNotifySubtitleFromMetadata(mediaMetadata);
        if (yeahLyricsDisplayManaged) {
            String mediaId = mediaMetadata.getString(MediaMetadataCompat.METADATA_KEY_MEDIA_ID);
            yeahSyncLastLyricMediaId(mediaId);
            title = yeahFilterManagedLyricTitle(title, description);
            if (title != null && title.length() > 0) yeahLastLyricDisplayTitle = title;
            if (subtitle != null && subtitle.length() > 0) {
                yeahLastLyricDisplaySubtitle = subtitle;
            }
            if (title == null || title.length() == 0) title = yeahLastLyricDisplayTitle;
            if (subtitle == null || subtitle.length() == 0) subtitle = yeahLastLyricDisplaySubtitle;
        } else {
            final String songTitle =
                    mediaMetadata.getString(MediaMetadataCompat.METADATA_KEY_TITLE);
            if (songTitle != null && songTitle.length() > 0) {
                title = songTitle;
            } else if (title == null) {
                title = description.getTitle();
            }
            if (subtitle == null || subtitle.length() == 0) {
                subtitle = description.getSubtitle();
            }
        }
        out[0] = title;
        out[1] = subtitle;
    }

    private MediaMetadataCompat yeahPreserveManagedLyricDisplay(MediaMetadataCompat incoming) {
        if (!yeahLyricsDisplayManaged || this.mediaMetadata == null) return incoming;
        String inId = incoming.getString(MediaMetadataCompat.METADATA_KEY_MEDIA_ID);
        String curId = this.mediaMetadata.getString(MediaMetadataCompat.METADATA_KEY_MEDIA_ID);
        if (inId == null || curId == null || !inId.equals(curId)) return incoming;
        CharSequence curTitle =
                this.mediaMetadata.getText(MediaMetadataCompat.METADATA_KEY_DISPLAY_TITLE);
        CharSequence curSub =
                this.mediaMetadata.getText(MediaMetadataCompat.METADATA_KEY_DISPLAY_SUBTITLE);
        if (curTitle == null && curSub == null) return incoming;
        MediaMetadataCompat.Builder builder = new MediaMetadataCompat.Builder(incoming);
        CharSequence keepTitle = curTitle;
        if (keepTitle != null) {
            CharSequence songTitle = yeahManagedSongTitleForFilter();
            if (songTitle == null) {
                songTitle = incoming.getString(MediaMetadataCompat.METADATA_KEY_TITLE);
            }
            if (songTitle != null && keepTitle.toString().contentEquals(songTitle.toString())) {
                keepTitle = yeahLastLyricDisplayTitle;
            }
        }
        if (keepTitle != null) {
            builder.putString(MediaMetadataCompat.METADATA_KEY_DISPLAY_TITLE, keepTitle.toString());
        }
        if (curSub != null) {
            final String subStr = curSub.toString();
            builder.putString(MediaMetadataCompat.METADATA_KEY_DISPLAY_SUBTITLE, subStr);
            builder.putString(YEAH_EXTRA_NOTIFY_SUBTITLE, subStr);
        }
        return builder.build();
    }

    /**
     * 高频刷新通知栏歌词（主线程、不经过 setMediaItem 单线程池），与网易云等应用行为接近。
     */
    public static boolean updateNotificationDisplayText(String displayTitle, String displaySubtitle) {
        if (!yeahCarMediaNotificationEnabled || instance == null) return false;
        synchronized (instance) {
            if (instance.mediaMetadata == null) return false;
            CharSequence curTitle =
                    instance.mediaMetadata.getText(MediaMetadataCompat.METADATA_KEY_DISPLAY_TITLE);
            CharSequence curSub =
                    instance.mediaMetadata.getText(MediaMetadataCompat.METADATA_KEY_DISPLAY_SUBTITLE);
            boolean titleSame = displayTitle == null
                    || (curTitle != null && displayTitle.contentEquals(curTitle))
                    || (curTitle == null && displayTitle.isEmpty());
            boolean subSame = displaySubtitle == null
                    || (curSub != null && displaySubtitle.contentEquals(curSub))
                    || (curSub == null && displaySubtitle.isEmpty());
            if (titleSame && subSame) return false;
            MediaMetadataCompat.Builder builder =
                    new MediaMetadataCompat.Builder(instance.mediaMetadata);
            if (displayTitle != null) {
                builder.putString(MediaMetadataCompat.METADATA_KEY_DISPLAY_TITLE, displayTitle);
            }
            // displaySubtitle == null：Dart 侧仅刷新歌词行，保留既有「歌名 - 歌手」副标题。
            if (displaySubtitle != null && !subSame) {
                builder.putString(MediaMetadataCompat.METADATA_KEY_DISPLAY_SUBTITLE, displaySubtitle);
                builder.putString(YEAH_EXTRA_NOTIFY_SUBTITLE, displaySubtitle);
            }
            MediaMetadataCompat updated = builder.build();
            String mediaId = updated.getString(MediaMetadataCompat.METADATA_KEY_MEDIA_ID);
            if (yeahLyricsDisplayManaged) {
                instance.yeahSyncLastLyricMediaId(mediaId);
                updated = instance.yeahMirrorManagedLyricSessionTitle(updated);
            }
            updated = instance.yeahFinalizeNotificationMetadata(updated);
            instance.mediaMetadata = updated;
            if (mediaId != null) {
                mediaMetadataCache.put(mediaId, updated);
            }
            if (yeahLyricsDisplayManaged) {
                instance.yeahPendingLyricTitle = displayTitle;
                instance.yeahPendingLyricSubtitle = displaySubtitle;
                final MediaMetadataCompat sessionMeta = instance.artBitmap != null
                        ? instance.putArtToMetadata(updated)
                        : updated;
                instance.yeahPendingSessionMeta = sessionMeta;
                instance.handler.removeCallbacks(instance.yeahManagedLyricTickRunner);
                instance.handler.post(instance.yeahManagedLyricTickRunner);
                return true;
            }
            if (instance.artBitmap != null) {
                instance.mediaSession.setMetadata(instance.putArtToMetadata(updated));
            } else {
                instance.mediaSession.setMetadata(updated);
            }
            instance.postNotificationUpdate();
            return true;
        }
    }

    synchronized void setMetadata(MediaMetadataCompat mediaMetadata) {
        mediaMetadata = yeahPreserveManagedLyricDisplay(mediaMetadata);
        String artCacheFilePath = mediaMetadata.getString("artCacheFile");
        if (artCacheFilePath != null
                && artCacheFilePath.equals(lastArtCacheFilePath)
                && artBitmap != null
                && this.mediaMetadata != null) {
            MediaMetadataCompat.Builder builder = new MediaMetadataCompat.Builder(mediaMetadata);
            String inId = mediaMetadata.getString(MediaMetadataCompat.METADATA_KEY_MEDIA_ID);
            String curId = this.mediaMetadata.getString(MediaMetadataCompat.METADATA_KEY_MEDIA_ID);
            if (inId != null && inId.equals(curId)) {
                CharSequence curDisplay =
                        this.mediaMetadata.getText(MediaMetadataCompat.METADATA_KEY_DISPLAY_TITLE);
                CharSequence inDisplay =
                        mediaMetadata.getText(MediaMetadataCompat.METADATA_KEY_DISPLAY_TITLE);
                MediaMetadataCompat cached = getMediaMetadata(inId);
                CharSequence cachedDisplay = cached == null ? null
                        : cached.getText(MediaMetadataCompat.METADATA_KEY_DISPLAY_TITLE);
                // 队列/debounce/setMediaItem 可能推入过期歌词行；会话上已有展示行则保留。
                if (curDisplay != null
                        && inDisplay != null
                        && !curDisplay.equals(inDisplay)
                        && (cachedDisplay == null || cachedDisplay.equals(inDisplay))) {
                    builder.putString(
                            MediaMetadataCompat.METADATA_KEY_DISPLAY_TITLE, curDisplay.toString());
                    CharSequence curSub = yeahNotifySubtitleFromMetadata(this.mediaMetadata);
                    if (curSub != null) {
                        builder.putString(
                                MediaMetadataCompat.METADATA_KEY_DISPLAY_SUBTITLE, curSub.toString());
                        builder.putString(YEAH_EXTRA_NOTIFY_SUBTITLE, curSub.toString());
                    }
                }
            }
            MediaMetadataCompat merged = builder.build();
            merged = yeahMirrorManagedLyricSessionTitle(merged);
            merged = yeahFinalizeNotificationMetadata(merged);
            this.mediaMetadata = merged;
            yeahPublishMetadataToSession(putArtToMetadata(merged));
            return;
        }
        if (artCacheFilePath != null) {
            lastArtCacheFilePath = artCacheFilePath;
            // Load local files and network images, cached in files
            artBitmap = loadArtBitmap(artCacheFilePath, null);
            mediaMetadata = putArtToMetadata(mediaMetadata);
        } else {
            lastArtCacheFilePath = null;
            // Load content:// URIs
            String artUri = mediaMetadata.getString(MediaMetadataCompat.METADATA_KEY_DISPLAY_ICON_URI);
            if (artUri != null && artUri.startsWith("content:")) {
                String loadThumbnailUri = mediaMetadata.getString("loadThumbnailUri");
                artBitmap = loadArtBitmap(artUri, loadThumbnailUri);
                mediaMetadata = putArtToMetadata(mediaMetadata);
            } else {
                artBitmap = null;
            }
        }
        if (yeahLyricsDisplayManaged) {
            mediaMetadata = yeahMirrorManagedLyricSessionTitle(mediaMetadata);
        }
        mediaMetadata = yeahFinalizeNotificationMetadata(mediaMetadata);
        this.mediaMetadata = mediaMetadata;
        yeahPublishMetadataToSession(mediaMetadata);
    }

    private MediaMetadataCompat putArtToMetadata(MediaMetadataCompat mediaMetadata) {
        return new MediaMetadataCompat.Builder(mediaMetadata)
                .putBitmap(MediaMetadataCompat.METADATA_KEY_ALBUM_ART, artBitmap)
                .putBitmap(MediaMetadataCompat.METADATA_KEY_DISPLAY_ICON, artBitmap)
                .build();
    }

    @Override
    public BrowserRoot onGetRoot(String clientPackageName, int clientUid, Bundle rootHints) {
        Boolean isRecentRequest = rootHints == null ? null : (Boolean)rootHints.getBoolean(BrowserRoot.EXTRA_RECENT);
        if (isRecentRequest == null) isRecentRequest = false;
        Bundle extras = config.getBrowsableRootExtras();
        return new BrowserRoot(isRecentRequest ? RECENT_ROOT_ID : BROWSABLE_ROOT_ID, extras);
        // The response must be given synchronously, and we can't get a
        // synchronous response from the Dart layer. For now, we hardcode
        // the root to "root". This may improve in media2.
        //return listener.onGetRoot(clientPackageName, clientUid, rootHints);
    }

    @Override
    public void onLoadChildren(final String parentMediaId, final Result<List<MediaBrowserCompat.MediaItem>> result) {
        onLoadChildren(parentMediaId, result, null);
    }

    @Override
    public void onLoadChildren(final String parentMediaId, final Result<List<MediaBrowserCompat.MediaItem>> result, Bundle options) {
        if (listener == null) {
            result.sendResult(new ArrayList<>());
            return;
        }
        listener.onLoadChildren(parentMediaId, result, options);
    }

    @Override
    public void onLoadItem(String itemId, Result<MediaBrowserCompat.MediaItem> result) {
        if (listener == null) {
            result.sendResult(null);
            return;
        }
        listener.onLoadItem(itemId, result);
    }

    @Override
    public void onSearch(String query, Bundle extras, Result<List<MediaBrowserCompat.MediaItem>> result) {
        if (listener == null) {
            result.sendResult(new ArrayList<>());
            return;
        }
        listener.onSearch(query, extras, result);
    }

    @Override
    public void onTaskRemoved(Intent rootIntent) {
        if (listener != null) {
            listener.onTaskRemoved();
        }
        super.onTaskRemoved(rootIntent);
    }

    public class MediaSessionCallback extends MediaSessionCompat.Callback {
        @Override
        public void onAddQueueItem(MediaDescriptionCompat description) {
            if (listener == null) return;
            listener.onAddQueueItem(getMediaMetadata(description.getMediaId()));
        }

        @Override
        public void onAddQueueItem(MediaDescriptionCompat description, int index) {
            if (listener == null) return;
            listener.onAddQueueItemAt(getMediaMetadata(description.getMediaId()), index);
        }

        @Override
        public void onRemoveQueueItem(MediaDescriptionCompat description) {
            if (listener == null) return;
            listener.onRemoveQueueItem(getMediaMetadata(description.getMediaId()));
        }

        @Override
        public void onPrepare() {
            if (listener == null) return;
            if (!mediaSession.isActive())
                mediaSession.setActive(true);
            listener.onPrepare();
        }

        @Override
        public void onPrepareFromMediaId(String mediaId, Bundle extras) {
            if (listener == null) return;
            if (!mediaSession.isActive())
                mediaSession.setActive(true);
            listener.onPrepareFromMediaId(mediaId, extras);
        }

        @Override
        public void onPrepareFromSearch(String query, Bundle extras) {
            if (listener == null) return;
            if (!mediaSession.isActive())
                mediaSession.setActive(true);
            listener.onPrepareFromSearch(query, extras);
        }

        @Override
        public void onPrepareFromUri(Uri uri, Bundle extras) {
            if (listener == null) return;
            if (!mediaSession.isActive())
                mediaSession.setActive(true);
            listener.onPrepareFromUri(uri, extras);
        }

        @Override
        public void onPlay() {
            if (listener == null) return;
            listener.onPlay();
        }

        @Override
        public void onPlayFromMediaId(final String mediaId, final Bundle extras) {
            if (listener == null) return;
            listener.onPlayFromMediaId(mediaId, extras);
        }

        @Override
        public void onPlayFromSearch(final String query, final Bundle extras) {
            if (listener == null) return;
            listener.onPlayFromSearch(query, extras);
        }

        @Override
        public void onPlayFromUri(final Uri uri, final Bundle extras) {
            if (listener == null) return;
            listener.onPlayFromUri(uri, extras);
        }

        @Override
        public boolean onMediaButtonEvent(Intent mediaButtonEvent) {
            if (listener == null) return false;
            // TODO: use typesafe version once SDK 33 is released.
            @SuppressWarnings("deprecation")
            final KeyEvent event = (KeyEvent)mediaButtonEvent.getExtras().getParcelable(Intent.EXTRA_KEY_EVENT);
            if (event.getAction() == KeyEvent.ACTION_DOWN) {
                switch (event.getKeyCode()) {
                case KEYCODE_BYPASS_PLAY:
                    onPlay();
                    break;
                case KEYCODE_BYPASS_PAUSE:
                    onPause();
                    break;
                case KeyEvent.KEYCODE_MEDIA_STOP:
                    onStop();
                    break;
                case KeyEvent.KEYCODE_MEDIA_FAST_FORWARD:
                    onFastForward();
                    break;
                case KeyEvent.KEYCODE_MEDIA_REWIND:
                    onRewind();
                    break;
                // Android unfortunately reroutes media button clicks to
                // KEYCODE_MEDIA_PLAY/PAUSE instead of the expected KEYCODE_HEADSETHOOK
                // or KEYCODE_MEDIA_PLAY_PAUSE. As a result, we can't genuinely tell if
                // onMediaButtonEvent was called because a media button was actually
                // pressed or because a PLAY/PAUSE action was pressed instead! To get
                // around this, we make PLAY and PAUSE actions use different keycodes:
                // KEYCODE_BYPASS_PLAY/PAUSE. Now if we get KEYCODE_MEDIA_PLAY/PUASE
                // we know it is actually a media button press.
                case KeyEvent.KEYCODE_MEDIA_NEXT:
                case KeyEvent.KEYCODE_MEDIA_PREVIOUS:
                case KeyEvent.KEYCODE_MEDIA_PLAY:
                case KeyEvent.KEYCODE_MEDIA_PAUSE:
                    // These are the "genuine" media button click events
                case KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE:
                case KeyEvent.KEYCODE_HEADSETHOOK:
                    listener.onClick(eventToButton(event));
                    break;
                }
            }
            return true;
        }

        private MediaButton eventToButton(KeyEvent event) {
            switch (event.getKeyCode()) {
            case KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE:
            case KeyEvent.KEYCODE_HEADSETHOOK:
                return MediaButton.media;
            case KeyEvent.KEYCODE_MEDIA_NEXT:
                return MediaButton.next;
            case KeyEvent.KEYCODE_MEDIA_PREVIOUS:
                return MediaButton.previous;
            default:
                return MediaButton.media;
            }
        }

        @Override
        public void onPause() {
            if (listener == null) return;
            listener.onPause();
        }

        @Override
        public void onStop() {
            if (listener == null) return;
            listener.onStop();
        }

        @Override
        public void onSkipToNext() {
            if (listener == null) return;
            listener.onSkipToNext();
        }

        @Override
        public void onSkipToPrevious() {
            if (listener == null) return;
            listener.onSkipToPrevious();
        }

        @Override
        public void onFastForward() {
            if (listener == null) return;
            listener.onFastForward();
        }

        @Override
        public void onRewind() {
            if (listener == null) return;
            listener.onRewind();
        }

        @Override
        public void onSkipToQueueItem(long id) {
            if (listener == null) return;
            listener.onSkipToQueueItem(id);
        }

        @Override
        public void onSeekTo(long pos) {
            if (listener == null) return;
            listener.onSeekTo(pos);
        }

        @Override
        public void onSetRating(RatingCompat rating) {
            if (listener == null) return;
            listener.onSetRating(rating);
        }

        @Override
        public void onSetPlaybackSpeed(float speed) {
            if (listener == null) return;
            listener.onSetPlaybackSpeed(speed);
        }

        @Override
        public void onSetCaptioningEnabled(boolean enabled) {
            if (listener == null) return;
            listener.onSetCaptioningEnabled(enabled);
        }

        @Override
        public void onSetRepeatMode(int repeatMode) {
            if (listener == null) return;
            listener.onSetRepeatMode(repeatMode);
        }

        @Override
        public void onSetShuffleMode(int shuffleMode) {
            if (listener == null) return;
            listener.onSetShuffleMode(shuffleMode);
        }

        @Override
        public void onCustomAction(String action, Bundle extras) {
            if (listener == null) return;
            if (CUSTOM_ACTION_STOP.equals(action)) {
                listener.onStop();
            } else if (CUSTOM_ACTION_FAST_FORWARD.equals(action)) {
                listener.onFastForward();
            } else if (CUSTOM_ACTION_REWIND.equals(action)) {
                listener.onRewind();
            } else {
                listener.onCustomAction(action, extras);
            }
        }

        @Override
        public void onSetRating(RatingCompat rating, Bundle extras) {
            if (listener == null) return;
            listener.onSetRating(rating, extras);
        }

        //
        // NON-STANDARD METHODS
        //

        public void onPlayMediaItem(final MediaDescriptionCompat description) {
            if (listener == null) return;
            listener.onPlayMediaItem(getMediaMetadata(description.getMediaId()));
        }
    }

    public interface ServiceListener {
        //BrowserRoot onGetRoot(String clientPackageName, int clientUid, Bundle rootHints);
        void onLoadChildren(String parentMediaId, Result<List<MediaBrowserCompat.MediaItem>> result, Bundle options);
        void onLoadItem(String itemId, Result<MediaBrowserCompat.MediaItem> result);
        void onSearch(String query, Bundle extras, Result<List<MediaBrowserCompat.MediaItem>> result);
        void onClick(MediaButton mediaButton);
        void onPrepare();
        void onPrepareFromMediaId(String mediaId, Bundle extras);
        void onPrepareFromSearch(String query, Bundle extras);
        void onPrepareFromUri(Uri uri, Bundle extras);
        void onPlay();
        void onPlayFromMediaId(String mediaId, Bundle extras);
        void onPlayFromSearch(String query, Bundle extras);
        void onPlayFromUri(Uri uri, Bundle extras);
        void onSkipToQueueItem(long id);
        void onPause();
        void onSkipToNext();
        void onSkipToPrevious();
        void onFastForward();
        void onRewind();
        void onStop();
        void onSeekTo(long pos);
        void onSetRating(RatingCompat rating);
        void onSetRating(RatingCompat rating, Bundle extras);
        void onSetRepeatMode(int repeatMode);
        void onSetShuffleMode(int shuffleMode);
        void onCustomAction(String action, Bundle extras);
        void onAddQueueItem(MediaMetadataCompat metadata);
        void onAddQueueItemAt(MediaMetadataCompat metadata, int index);
        void onRemoveQueueItem(MediaMetadataCompat metadata);
        void onRemoveQueueItemAt(int index);
        void onSetPlaybackSpeed(float speed);
        void onSetCaptioningEnabled(boolean enabled);
        void onSetVolumeTo(int volumeIndex);
        void onAdjustVolume(int direction);

        //
        // NON-STANDARD METHODS
        //

        void onPlayMediaItem(MediaMetadataCompat metadata);
        void onTaskRemoved();
        void onClose();
        void onDestroy();
    }
}
