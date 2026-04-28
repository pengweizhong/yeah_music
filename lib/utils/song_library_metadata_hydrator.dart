import 'dart:typed_data';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:yeah_music/logging/app_log.dart';
import 'package:yeah_music/models/song.dart';
import 'package:yeah_music/utils/application_utils.dart';
import 'package:yeah_music/utils/file_utils.dart';

/// 入库为轻量元数据时可调用本类，在列表等处后台补全：**封面、歌词与其它标签**，同一路径只读文件一次，
/// [applyTo] 到各 [Song] 实例（不因去重跳过其它引用）。
class SongLibraryMetadataHydrator {
  SongLibraryMetadataHydrator._();

  static final Map<String, Future<void>> _pending = {};
  static final Map<String, _MetaSnapshot> _cache = {};

  /// 列表展示经 [ResizeImage] 已降采样；过小会丢弃内嵌图导致大量「无封面」。
  static const int _maxArtBytes = 512 * 1024;

  /// 已为 [song.path] 成功缓存则套用结果；否则会发起（或并入进行中的）一次 [FileUtils.loadSongMeta]，
  /// 再写入 [song]。失败不写缓存以便后续重试。
  static Future<void> hydrateIfNeeded(Song song) async {
    final p = song.path;
    if (p.isEmpty) return;

    final cached = _cache[p];
    if (cached != null) {
      cached.applyTo(song);
      ApplicationUtils.evictSongCoverProvidersForPath(p);
      return;
    }

    final fut = _pending[p] ??= _loadPath(p);
    await fut;
    final snap = _cache[p];
    if (snap == null) return;
    snap.applyTo(song);
    ApplicationUtils.evictSongCoverProvidersForPath(p);
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
    required this.createDateTime,
    required this.updateDateTime,
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
  final DateTime? createDateTime;
  final DateTime? updateDateTime;

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
      createDateTime: s.createDateTime,
      updateDateTime: s.updateDateTime,
    );
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
    s.imageBytes = imageBytes;
    s.createDateTime = createDateTime;
    s.updateDateTime = updateDateTime;
  }
}
