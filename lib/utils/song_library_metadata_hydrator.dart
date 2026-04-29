import 'dart:typed_data';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:yeah_music/logging/app_log.dart';
import 'package:yeah_music/models/song.dart';
import 'package:yeah_music/utils/application_utils.dart';
import 'package:yeah_music/utils/file_utils.dart';

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
class SongLibraryMetadataHydrator {
  SongLibraryMetadataHydrator._();

  static final Map<String, Future<void>> _pending = {};
  static final Map<String, _MetaSnapshot> _cache = {};

  /// 列表展示经 [ResizeImage] 已降采样；过小会丢弃内嵌图导致大量「无封面」。
  static const int _maxArtBytes = 512 * 1024;

  /// 若 [Song] 已与缓存一致则返回 false；否则写入并返回 true（便于列表仅在真有变更时 [setState]）。
  ///
  /// Hive 等已持久化「封面+标题+歌词」时，会先用内存快照预热 [_cache]，避免冷启动重复读音频文件。
  static Future<bool> hydrateIfNeeded(Song song) async {
    final p = song.path;
    if (p.isEmpty) return false;

    _maybeSeedCacheFromLibrarySong(song);

    final cached = _cache[p];
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
      return true;
    }

    final fut = _pending[p] ??= _loadPath(p);
    await fut;
    final snap = _cache[p];
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
    return true;
  }

  /// 文件删除或重命名后丢弃该路径的内存缓存与封面 provider。
  static void invalidatePath(String path) {
    final p = path.trim();
    if (p.isEmpty) return;
    _cache.remove(p);
    _pending.remove(p);
    ApplicationUtils.evictSongCoverProvidersForPath(p);
  }

  /// 库内已有完整展示所需元数据时写入 [_cache]，使后续 hydrate 走「已命中」分支、不重复 [readMetadata]。
  /// 要求非空歌词，以免阻断「仅从文件补歌词」的路径。
  static void _maybeSeedCacheFromLibrarySong(Song song) {
    final p = song.path;
    if (p.isEmpty) return;
    if (_cache.containsKey(p) || _pending.containsKey(p)) return;
    final bytes = song.imageBytes;
    if (bytes == null || bytes.isEmpty) return;
    if (!(song.title?.trim().isNotEmpty ?? false)) return;
    final ly = song.lyrics;
    if (ly == null || ly.trim().isEmpty) return;
    _cache[p] = _MetaSnapshot.fromSong(song);
  }

  static Future<void> _loadPath(String path) async {
    try {
      await Future<void>.delayed(Duration.zero);
      final tmp = Song(path);
      await FileUtils.loadSongMeta(
        tmp,
        loadEmbeddedAlbumArt: true,
        storeLyricsWithTrack: true,
        maxEmbeddedArtBytes: _maxArtBytes,
      );
      _cache[path] = _MetaSnapshot.fromSong(tmp);
    } catch (e, st) {
      appLog.w('后台补全曲目元数据失败: $path', error: e, stackTrace: st);
    } finally {
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
