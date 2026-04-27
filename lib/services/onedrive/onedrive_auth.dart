import 'dart:io';

import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:yeah_music/config/onedrive_config.dart';
import 'package:yeah_music/services/onedrive/onedrive_token_store.dart';

/// Microsoft 登录与刷新（需 [clientId] 非空）。
class OneDriveAuth {
  OneDriveAuth({OneDriveTokenStore? store, FlutterAppAuth? appAuth})
      : _store = store ?? OneDriveTokenStore(),
        _appAuth = appAuth ?? FlutterAppAuth();

  final OneDriveTokenStore _store;
  final FlutterAppAuth _appAuth;

  Future<void> signOut() => _store.clear();

  /// 交互式登录；Linux 等平台无 [FlutterAppAuth] 支持时返回 null。
  Future<({String access, String refresh, DateTime expiry})?> signIn(String clientId) async {
    if (clientId.trim().isEmpty) return null;
    if (Platform.isLinux) return null;

    final AuthorizationTokenResponse? res = await _appAuth.authorizeAndExchangeCode(
      AuthorizationTokenRequest(
        clientId.trim(),
        OneDriveConfig.redirectUrl,
        discoveryUrl: OneDriveConfig.discoveryUrl,
        scopes: OneDriveConfig.scopes,
      ),
    );
    if (res == null) return null;
    final access = res.accessToken;
    final refresh = res.refreshToken;
    if (access == null || refresh == null) return null;
    final expiry = res.accessTokenExpirationDateTime ??
        DateTime.now().add(const Duration(hours: 1));
    await _store.save(
      accessToken: access,
      refreshToken: refresh,
      accessExpiry: expiry,
    );
    return (access: access, refresh: refresh, expiry: expiry);
  }

  Future<String?> getValidAccessToken(String clientId) async {
    if (clientId.trim().isEmpty) return null;
    final access = await _store.readAccessToken();
    final refresh = await _store.readRefreshToken();
    final exp = await _store.readAccessExpiry();
    if (access == null || refresh == null) return null;
    if (exp != null && DateTime.now().isBefore(exp.subtract(const Duration(minutes: 2)))) {
      return access;
    }
    if (Platform.isLinux) return null;
    final TokenResponse? tr = await _appAuth.token(
      TokenRequest(
        clientId.trim(),
        OneDriveConfig.redirectUrl,
        refreshToken: refresh,
        discoveryUrl: OneDriveConfig.discoveryUrl,
        scopes: OneDriveConfig.scopes,
      ),
    );
    final newAccess = tr?.accessToken;
    final newRefresh = tr?.refreshToken ?? refresh;
    if (newAccess == null) return null;
    final newExp = tr?.accessTokenExpirationDateTime ??
        DateTime.now().add(const Duration(hours: 1));
    await _store.save(
      accessToken: newAccess,
      refreshToken: newRefresh,
      accessExpiry: newExp,
    );
    return newAccess;
  }
}
