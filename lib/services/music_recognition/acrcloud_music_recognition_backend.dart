import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:yeah_music/logging/app_log.dart';
import 'package:yeah_music/models/acr_cloud_recognition_config.dart';
import 'package:yeah_music/services/music_recognition/music_recognition_backend.dart';
import 'package:yeah_music/services/music_recognition/music_recognition_outcome.dart';

String _acrResponseBodyUtf8(http.Response r) {
  try {
    return utf8.decode(r.bodyBytes, allowMalformed: true);
  } catch (_) {
    return r.body;
  }
}

String? _acrJsonString(dynamic v) {
  if (v == null) return null;
  if (v is String) return v;
  return v.toString();
}

/// ACRCloud [Identification API V1](https://docs.acrcloud.com/reference/identification-api/identification-api.md) 实现。
final class AcrCloudMusicRecognitionBackend implements MusicRecognitionBackend {
  AcrCloudMusicRecognitionBackend({required AcrCloudRecognitionConfig config})
    : _config = config;

  final AcrCloudRecognitionConfig _config;

  static const String _httpUri = '/v1/identify';

  static String _signature({
    required String accessKey,
    required String accessSecret,
    required String timestamp,
  }) {
    const dataType = 'audio';
    const sigVersion = '1';
    final stringToSign =
        'POST\n$_httpUri\n$accessKey\n$dataType\n$sigVersion\n$timestamp';
    final digest = Hmac(sha1, utf8.encode(accessSecret)).convert(
      utf8.encode(stringToSign),
    );
    return base64Encode(digest.bytes);
  }

  static String? _spotifyUrlFromExternal(Map<String, dynamic>? ext) {
    if (ext == null) return null;
    final sp = ext['spotify'];
    if (sp is! Map) return null;
    final track = sp['track'];
    if (track is! Map) return null;
    final id = track['id']?.toString();
    if (id == null || id.isEmpty) return null;
    return 'https://open.spotify.com/track/$id';
  }

  static String? _appleMusicUrlFromExternal(Map<String, dynamic>? ext) {
    if (ext == null) return null;
    final raw =
        ext['apple_music'] ?? ext['applemusic'] ?? ext['itunes'] ?? ext['apple'];
    if (raw is Map) {
      final track = raw['track'];
      if (track is Map) {
        final url = track['url'] ?? track['link'];
        if (url != null && url.toString().startsWith('http')) {
          return url.toString();
        }
      }
    }
    return null;
  }

  static MusicRecognitionOutcome _parseBody(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        return MusicRecognitionOutcome(
          rawStatus: 'error',
          errorMessage: 'Invalid JSON',
        );
      }
      final status = decoded['status'];
      if (status is! Map) {
        return MusicRecognitionOutcome(
          rawStatus: 'error',
          errorMessage: body.length > 200 ? '${body.substring(0, 200)}…' : body,
        );
      }
      final code = status['code'];
      final msg = status['msg']?.toString();
      if (code is int && code != 0) {
        if (code == 1001) {
          return const MusicRecognitionOutcome(rawStatus: 'success');
        }
        return MusicRecognitionOutcome(
          rawStatus: 'error',
          errorMessage: msg ?? 'code $code',
        );
      }
      final metadata = decoded['metadata'];
      if (metadata is! Map<String, dynamic>) {
        return const MusicRecognitionOutcome(rawStatus: 'success');
      }
      final music = metadata['music'];
      if (music is! List || music.isEmpty) {
        return const MusicRecognitionOutcome(rawStatus: 'success');
      }
      final first = music.first;
      if (first is! Map<String, dynamic>) {
        return const MusicRecognitionOutcome(rawStatus: 'success');
      }
      final title = _acrJsonString(first['title']);
      final albumMap = first['album'];
      String? album;
      if (albumMap is Map && albumMap['name'] != null) {
        album = _acrJsonString(albumMap['name']);
      }
      String? artist;
      final artists = first['artists'];
      if (artists is List && artists.isNotEmpty) {
        final a0 = artists.first;
        if (a0 is Map && a0['name'] != null) {
          artist = _acrJsonString(a0['name']);
        }
      }
      final releaseDate = _acrJsonString(first['release_date']);
      final ext = first['external_metadata'];
      Map<String, dynamic>? extMap;
      if (ext is Map<String, dynamic>) {
        extMap = ext;
      }
      return MusicRecognitionOutcome(
        rawStatus: 'success',
        title: title,
        artist: artist,
        album: album,
        releaseDate: releaseDate,
        appleMusicUrl: _appleMusicUrlFromExternal(extMap),
        spotifyUrl: _spotifyUrlFromExternal(extMap),
      );
    } catch (e, st) {
      appLog.e('ACRCloud parse failed', error: e, stackTrace: st);
      return MusicRecognitionOutcome(
        rawStatus: 'error',
        errorMessage: e.toString(),
      );
    }
  }

  @override
  Future<MusicRecognitionOutcome> recognizeFile(File file) async {
    final host = AcrCloudRecognitionConfig.normalizeHost(_config.host);
    final accessKey = _config.accessKey.trim();
    final secret = _config.accessSecret.trim();
    if (host.isEmpty || accessKey.isEmpty || secret.isEmpty) {
      return const MusicRecognitionOutcome(
        rawStatus: 'error',
        errorMessage: 'ACRCloud host / keys incomplete',
      );
    }
    final uri = Uri.parse('https://$host$_httpUri');
    final ts = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    final sign = _signature(
      accessKey: accessKey,
      accessSecret: secret,
      timestamp: ts,
    );
    try {
      final length = await file.length();
      if (length <= 0 || length > 5 * 1024 * 1024) {
        return const MusicRecognitionOutcome(
          rawStatus: 'error',
          errorMessage: 'sample size invalid',
        );
      }
      final req = http.MultipartRequest('POST', uri)
        ..fields['access_key'] = accessKey
        ..fields['sample_bytes'] = length.toString()
        ..fields['timestamp'] = ts
        ..fields['signature'] = sign
        ..fields['data_type'] = 'audio'
        ..fields['signature_version'] = '1';
      req.files.add(
        await http.MultipartFile.fromPath(
          'sample',
          file.path,
          filename: 'sample.wav',
        ),
      );
      final streamed = await req.send().timeout(const Duration(seconds: 45));
      final resp = await http.Response.fromStream(streamed);
      return _parseBody(_acrResponseBodyUtf8(resp));
    } catch (e, st) {
      appLog.e('ACRCloud request failed', error: e, stackTrace: st);
      return MusicRecognitionOutcome(
        rawStatus: 'error',
        errorMessage: e.toString(),
      );
    }
  }
}
