import 'dart:convert';

import 'package:yeah_music/models/song_recognition_provider.dart';

/// 识别方式：应用内一键 / 环境聆听（周期性采样，用于外放或其他 App）
enum SongRecognitionCaptureMode { inApp, ambient }

SongRecognitionCaptureMode songRecognitionCaptureModeFromStorage(String? raw) {
  if (raw == SongRecognitionCaptureMode.ambient.name) {
    return SongRecognitionCaptureMode.ambient;
  }
  return SongRecognitionCaptureMode.inApp;
}

/// 单条听歌识曲历史（本地存储）
class SongRecognitionEntry {
  const SongRecognitionEntry({
    required this.id,
    required this.createdAt,
    required this.mode,
    this.provider,
    this.title,
    this.artist,
    this.album,
    this.releaseDate,
    this.appleMusicUrl,
    this.spotifyUrl,
    required this.status,
    this.errorMessage,
    this.archived = false,
  });

  final String id;
  final DateTime createdAt;
  final SongRecognitionCaptureMode mode;
  /// 所用识曲引擎；旧数据可能为 null。
  final SongRecognitionProvider? provider;
  final String? title;
  final String? artist;
  final String? album;
  final String? releaseDate;
  final String? appleMusicUrl;
  final String? spotifyUrl;

  /// `success` | `no_match` | `error`
  final String status;
  final String? errorMessage;

  /// 已收藏（持久化键仍为 archived，兼容旧版）；旧数据无该字段时视为 false。
  final bool archived;

  SongRecognitionEntry copyWith({bool? archived}) {
    return SongRecognitionEntry(
      id: id,
      createdAt: createdAt,
      mode: mode,
      provider: provider,
      title: title,
      artist: artist,
      album: album,
      releaseDate: releaseDate,
      appleMusicUrl: appleMusicUrl,
      spotifyUrl: spotifyUrl,
      status: status,
      errorMessage: errorMessage,
      archived: archived ?? this.archived,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'createdAt': createdAt.toIso8601String(),
    'mode': mode.name,
    if (provider != null) 'provider': provider!.name,
    'title': title,
    'artist': artist,
    'album': album,
    'releaseDate': releaseDate,
    'appleMusicUrl': appleMusicUrl,
    'spotifyUrl': spotifyUrl,
    'status': status,
    'errorMessage': errorMessage,
    'archived': archived,
  };

  static String? _songRecJsonString(dynamic v) {
    if (v == null) return null;
    if (v is String) return v;
    return v.toString();
  }

  static SongRecognitionEntry? fromJsonMap(Map<String, dynamic> m) {
    try {
      final id = m['id'] as String?;
      final at = m['createdAt'] as String?;
      if (id == null || at == null) return null;
      SongRecognitionProvider? prov;
      final pr = m['provider'] as String?;
      if (pr != null) {
        for (final v in SongRecognitionProvider.values) {
          if (v.name == pr) {
            prov = v;
            break;
          }
        }
      }
      return SongRecognitionEntry(
        id: id,
        createdAt: DateTime.tryParse(at) ?? DateTime.now(),
        mode: songRecognitionCaptureModeFromStorage(m['mode'] as String?),
        provider: prov,
        title: _songRecJsonString(m['title']),
        artist: _songRecJsonString(m['artist']),
        album: _songRecJsonString(m['album']),
        releaseDate: _songRecJsonString(m['releaseDate']),
        appleMusicUrl: _songRecJsonString(m['appleMusicUrl']),
        spotifyUrl: _songRecJsonString(m['spotifyUrl']),
        status: m['status'] as String? ?? 'error',
        errorMessage: _songRecJsonString(m['errorMessage']),
        archived: m['archived'] == true,
      );
    } catch (_) {
      return null;
    }
  }

  static String encodeList(List<SongRecognitionEntry> list) =>
      jsonEncode(list.map((e) => e.toJson()).toList());

  static List<SongRecognitionEntry> decodeList(String raw) {
    if (raw.trim().isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List<dynamic>) return [];
      final out = <SongRecognitionEntry>[];
      for (final e in decoded) {
        if (e is Map<String, dynamic>) {
          final x = fromJsonMap(e);
          if (x != null) out.add(x);
        }
      }
      return out;
    } catch (_) {
      return [];
    }
  }
}
