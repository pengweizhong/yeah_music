import 'dart:typed_data';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:yeah_music/logging/app_log.dart';
import 'package:yeah_music/models/song.dart';
import 'package:yeah_music/utils/application_utils.dart';
import 'package:yeah_music/utils/concurrent_limiter.dart';
import 'package:yeah_music/utils/file_utils.dart';
import 'package:yeah_music/utils/folder_song_hive_persistence.dart';
import 'package:yeah_music/utils/song_audio_quality.dart';

bool _sameImageBytes(Uint8List? a, Uint8List? b) {
  if (identical(a, b)) return true;
  if (a == null || b == null) return false;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool _picturesRoughEqual(List<Picture>? a, List<Picture>? b) {
  if (identical(a, b)) return true;
  if (a == null || b == null) return a == null && b == null;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (!_sameImageBytes(a[i].bytes, b[i].bytes)) return false;
  }
  return true;
}

/// 入库为轻量元数据时可调用本类，在列表等处后台补全：**封面、歌词与其它标签**，同一路径只读文件一次，
/// [applyTo] 到各 [Song] 实例（不因去重跳过其它引用）。
/// 与并行上限配合，避免滑动长列表时数十路同时 readMetadata。
///
/// 内存路径级 [_cache] 为 **LRU + 条数上限**（大图/歌词快照只保留近期访问的路径），避免长会话无界增长。
class SongLibraryMetadataHydrator {
  SongLibraryMetadataHydrator._();

  static final Map<String, Future<void>> _pending = {};
  /// 插入序即 LRU 序（Dart [Map] 默认 [LinkedHashMap]）；[_cacheTouch] / [_cachePut] 维护。
  static final Map<String, _MetaSnapshot> _cache = <String, _MetaSnapshot>{};
  static final ConcurrentLimiter _ioLimiter = ConcurrentLimiter(3);

  /// 路径条数上限；单条可含大图与歌词，不宜过大。
  static const int maxCacheEntries = 384;

  static _MetaSnapshot? _cacheTouch(String path) {
    final snap = _cache.remove(path);
    if (snap == null) return null;
    _cache[path] = snap;
    return snap;
  }

  static void _cachePut(String path, _MetaSnapshot snap) {
    _cache.remove(path);
    _cache[path] = snap;
    while (_cache.length > maxCacheEntries) {
      final k = _cache.keys.first;
      _cache.remove(k);
    }
  }

  /// 列表展示经 [ResizeImage] 已降采样；过小会丢弃内嵌图导致大量「无封面」。
  static const int maxEmbeddedArtBytes = 1920 * 1024;

  /// 若 [Song] 已与缓存一致则返回 false；否则写入并返回 true（便于列表仅在真有变更时 [setState]）。
  ///
  /// Hive 等已持久化「封面+标题+歌词」时，会先用内存快照预热 [_cache]，避免冷启动重复读音频文件。
  static Future<bool> hydrateIfNeeded(Song song) async {
    final p = song.path;
    if (p.isEmpty) return false;

    _maybeSeedCacheFromLibrarySong(song);

    final cached = _cacheTouch(p);
    if (cached != null) {
      if (cached.matchesSong(song)) {
        return false;
      }
      final beforeFp = ApplicationUtils.coverBytesFingerprint(song.imageBytes);
      cached.applyTo(song);
      final afterFp = ApplicationUtils.coverBytesFingerprint(song.imageBytes);
      if (beforeFp != afterFp) {
        ApplicationUtils.evictSongCoverProvidersForPath(p);
      }
      scheduleEmbeddedSongMetadataPersist(song);
      return true;
    }

    final fut = _pending[p] ??= _loadPath(p);
    await fut;
    final snap = _cacheTouch(p);
    if (snap == null) return false;
    if (snap.matchesSong(song)) {
      return false;
    }
    final beforeFp = ApplicationUtils.coverBytesFingerprint(song.imageBytes);
    snap.applyTo(song);
    final afterFp = ApplicationUtils.coverBytesFingerprint(song.imageBytes);
    if (beforeFp != afterFp) {
      ApplicationUtils.evictSongCoverProvidersForPath(p);
    }
    scheduleEmbeddedSongMetadataPersist(song);
    return true;
  }

  /// 文件删除或重命名后丢弃该路径的内存缓存与封面 provider。
  static void invalidatePath(String path) {
    final p = path.trim();
    if (p.isEmpty) return;
    _cache.remove(p);
    _pending.remove(p);
    invalidateSongAudioQualityCacheForPath(p);
    ApplicationUtils.evictSongCoverProvidersForPath(p);
  }

  /// Hive 等已持久化「封面 + 文案」时可预热 [_cache]，避免冷启动对已带封面的 FLAC 重复读文件。
  /// （不要求先有歌词——否则大量「仅嵌入封面」条目无法命中缓存。）
  static void _maybeSeedCacheFromLibrarySong(Song song) {
    final p = song.path;
    if (p.isEmpty) return;
    if (_cache.containsKey(p) || _pending.containsKey(p)) return;
    final bytes = song.imageBytes;
    if (bytes == null || bytes.isEmpty) return;
    if (!(song.title?.trim().isNotEmpty ?? false)) return;
    _cachePut(p, _MetaSnapshot.fromSong(song));
  }

  static Future<void> _loadPath(String path) async {
    await _ioLimiter.acquire();
    try {
      await Future<void>.delayed(Duration.zero);
      try {
        final tmp = Song(path);
        await FileUtils.loadSongMeta(
          tmp,
          loadEmbeddedAlbumArt: true,
          storeLyricsWithTrack: true,
          maxEmbeddedArtBytes: maxEmbeddedArtBytes,
        );
        _cachePut(path, _MetaSnapshot.fromSong(tmp));
      } catch (e, st) {
        appLog.w('后台补全曲目元数据失败: $path', error: e, stackTrace: st);
      }
    } finally {
      _ioLimiter.release();
      _pending.remove(path);
    }
  }
}

class _MetaSnapshot {
  _MetaSnapshot({
    required this.title,
    required this.album,
    required this.artist,
    required this.year,
    required this.duration,
    required this.trackNumber,
    required this.discNumber,
    required this.sampleRate,
    required this.bitrate,
    required this.lyrics,
    required this.pictures,
    required this.imageBytes,
  });

  final String? title;
  final String? album;
  final String? artist;
  final DateTime? year;
  final Duration? duration;
  final int? trackNumber;
  final int? discNumber;
  final int? sampleRate;
  final int? bitrate;
  final String? lyrics;
  final List<Picture>? pictures;
  final Uint8List? imageBytes;

  factory _MetaSnapshot.fromSong(Song s) {
    return _MetaSnapshot(
      title: s.title,
      album: s.album,
      artist: s.artist,
      year: s.year,
      duration: s.duration,
      trackNumber: s.trackNumber,
      discNumber: s.discNumber,
      sampleRate: s.sampleRate,
      bitrate: s.bitrate,
      lyrics: s.lyrics,
      pictures: s.pictures,
      imageBytes: s.imageBytes,
    );
  }

  bool matchesSong(Song s) {
    return s.title == title &&
        s.album == album &&
        s.artist == artist &&
        s.year == year &&
        s.duration == duration &&
        s.trackNumber == trackNumber &&
        s.discNumber == discNumber &&
        s.sampleRate == sampleRate &&
        s.bitrate == bitrate &&
        s.lyrics == lyrics &&
        _sameImageBytes(s.imageBytes, imageBytes) &&
        _picturesRoughEqual(s.pictures, pictures);
  }

  void applyTo(Song s) {
    s.title = title;
    s.album = album;
    s.artist = artist;
    s.year = year;
    s.duration = duration;
    s.trackNumber = trackNumber;
    s.discNumber = discNumber;
    s.sampleRate = sampleRate;
    s.bitrate = bitrate;
    s.lyrics = lyrics;
    s.pictures = pictures;
    if (!_sameImageBytes(s.imageBytes, imageBytes)) {
      s.imageBytes = imageBytes;
    }
  }
}
