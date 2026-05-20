// Copyright (c) 2025 Yeah Music
//
// This file is part of Yeah Music.
//
// Yeah Music is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Yeah Music is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:yeah_music/logging/app_log.dart';

String _auddResponseBodyUtf8(http.Response r) {
  try {
    return utf8.decode(r.bodyBytes, allowMalformed: true);
  } catch (_) {
    return r.body;
  }
}

String? _auddJsonString(dynamic v) {
  if (v == null) return null;
  if (v is String) return v;
  return v.toString();
}

/// [AudD](https://audd.io) 识别结果（需有效 api_token；`test` 仅供试用有额度限制）。
class AuddRecognitionOutcome {
  const AuddRecognitionOutcome({
    required this.rawStatus,
    this.title,
    this.artist,
    this.album,
    this.releaseDate,
    this.appleMusicUrl,
    this.spotifyUrl,
    this.errorMessage,
  });

  final String rawStatus;
  final String? title;
  final String? artist;
  final String? album;
  final String? releaseDate;
  final String? appleMusicUrl;
  final String? spotifyUrl;
  final String? errorMessage;

  bool get hasMatch => title != null && title!.trim().isNotEmpty;

  bool get isSuccess => rawStatus == 'success' && hasMatch;

  bool get isNoMatch => rawStatus == 'success' && !hasMatch;

  static AuddRecognitionOutcome fromHttpResponse(http.Response r) {
    try {
      final text = _auddResponseBodyUtf8(r);
      final m = jsonDecode(text);
      if (m is! Map<String, dynamic>) {
        return AuddRecognitionOutcome(
          rawStatus: 'error',
          errorMessage: 'Invalid response',
        );
      }
      final status = m['status'] as String? ?? 'error';
      if (status == 'error') {
        final err = m['error'];
        String? msg;
        if (err is Map && err['error_message'] != null) {
          msg = err['error_message'].toString();
        } else {
          msg = m['message']?.toString();
        }
        return AuddRecognitionOutcome(
          rawStatus: 'error',
          errorMessage: msg ?? text,
        );
      }
      final result = m['result'];
      if (result == null) {
        return AuddRecognitionOutcome(rawStatus: 'success');
      }
      if (result is Map<String, dynamic>) {
        String? apple;
        String? spotify;
        final appleObj = result['apple_music'];
        if (appleObj is Map && appleObj['url'] != null) {
          apple = appleObj['url'].toString();
        }
        final spotObj = result['spotify'];
        if (spotObj is Map && spotObj['external_urls'] is Map) {
          final eu = spotObj['external_urls'] as Map;
          spotify = eu['spotify']?.toString();
        }
        return AuddRecognitionOutcome(
          rawStatus: status,
          title: _auddJsonString(result['title']),
          artist: _auddJsonString(result['artist']),
          album: _auddJsonString(result['album']),
          releaseDate: _auddJsonString(result['release_date']),
          appleMusicUrl: apple,
          spotifyUrl: spotify,
        );
      }
      return AuddRecognitionOutcome(rawStatus: status);
    } catch (e, st) {
      appLog.e('AudD parse failed', error: e, stackTrace: st);
      return AuddRecognitionOutcome(
        rawStatus: 'error',
        errorMessage: e.toString(),
      );
    }
  }
}

/// 向 AudD 上传本地 WAV/M4A 等音频片段识别曲目。
class AuddMusicRecognitionService {
  static final Uri _endpoint = Uri.parse('https://api.audd.io/');

  static Future<AuddRecognitionOutcome> recognizeFile({
    required File file,
    required String apiToken,
  }) async {
    final token = apiToken.trim().isEmpty ? 'test' : apiToken.trim();
    try {
      final req = http.MultipartRequest('POST', _endpoint)
        ..fields['api_token'] = token
        ..fields['return'] = 'apple_music,spotify';
      req.files.add(await http.MultipartFile.fromPath('file', file.path));
      final streamed = await req.send().timeout(const Duration(seconds: 45));
      final resp = await http.Response.fromStream(streamed);
      return AuddRecognitionOutcome.fromHttpResponse(resp);
    } catch (e, st) {
      appLog.e('AudD request failed', error: e, stackTrace: st);
      return AuddRecognitionOutcome(
        rawStatus: 'error',
        errorMessage: e.toString(),
      );
    }
  }
}
