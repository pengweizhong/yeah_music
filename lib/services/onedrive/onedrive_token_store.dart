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

import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 安全保存 OneDrive OAuth 令牌。
class OneDriveTokenStore {
  OneDriveTokenStore({FlutterSecureStorage? storage})
      : _storage = storage ?? _defaultSecureStorage;

  /// macOS 沙盒下默认的 Data Protection 钥匙串会触发 -34018（缺少 entitlement），
  /// 与 OneDrive 登录后写令牌路径一致，故在桌面 macOS 关闭该标志。
  static final FlutterSecureStorage _defaultSecureStorage =
      !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS
          ? const FlutterSecureStorage(
              mOptions: MacOsOptions(useDataProtectionKeyChain: false),
            )
          : const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _kAccess = 'onedrive_access_token';
  static const _kRefresh = 'onedrive_refresh_token';
  static const _kExpiry = 'onedrive_access_expiry_ms';

  Future<void> save({
    required String accessToken,
    required String refreshToken,
    required DateTime accessExpiry,
  }) async {
    await _storage.write(key: _kAccess, value: accessToken);
    await _storage.write(key: _kRefresh, value: refreshToken);
    await _storage.write(
      key: _kExpiry,
      value: accessExpiry.millisecondsSinceEpoch.toString(),
    );
  }

  Future<String?> readAccessToken() => _storage.read(key: _kAccess);

  Future<String?> readRefreshToken() => _storage.read(key: _kRefresh);

  Future<DateTime?> readAccessExpiry() async {
    final s = await _storage.read(key: _kExpiry);
    if (s == null) return null;
    final n = int.tryParse(s);
    if (n == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(n);
  }

  Future<void> clear() async {
    await _storage.delete(key: _kAccess);
    await _storage.delete(key: _kRefresh);
    await _storage.delete(key: _kExpiry);
  }
}
