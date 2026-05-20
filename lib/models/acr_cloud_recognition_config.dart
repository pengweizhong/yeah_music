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

/// ACRCloud 识别项目配置（控制台 Host / Access Key / Secret）。
class AcrCloudRecognitionConfig {
  const AcrCloudRecognitionConfig({
    this.host = '',
    this.accessKey = '',
    this.accessSecret = '',
  });

  final String host;
  final String accessKey;
  final String accessSecret;

  bool get isComplete =>
      normalizeHost(host).isNotEmpty &&
      accessKey.trim().isNotEmpty &&
      accessSecret.trim().isNotEmpty;

  Map<String, dynamic> toJson() => {
    'host': host,
    'accessKey': accessKey,
    'accessSecret': accessSecret,
  };

  factory AcrCloudRecognitionConfig.fromJson(Map<String, dynamic>? m) {
    if (m == null) return const AcrCloudRecognitionConfig();
    return AcrCloudRecognitionConfig(
      host: m['host'] as String? ?? '',
      accessKey: m['accessKey'] as String? ?? '',
      accessSecret: m['accessSecret'] as String? ?? '',
    );
  }

  static String encode(AcrCloudRecognitionConfig c) => jsonEncode(c.toJson());

  static AcrCloudRecognitionConfig decode(String raw) {
    if (raw.trim().isEmpty) return const AcrCloudRecognitionConfig();
    try {
      final m = jsonDecode(raw);
      if (m is Map<String, dynamic>) {
        return AcrCloudRecognitionConfig.fromJson(m);
      }
    } catch (_) {}
    return const AcrCloudRecognitionConfig();
  }

  /// 仅保留主机名，去掉协议与路径。
  static String normalizeHost(String raw) {
    var h = raw.trim();
    if (h.startsWith('https://')) {
      h = h.substring(8);
    } else if (h.startsWith('http://')) {
      h = h.substring(7);
    }
    final slash = h.indexOf('/');
    if (slash >= 0) {
      h = h.substring(0, slash);
    }
    return h.trim();
  }
}
