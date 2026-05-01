import 'dart:async';
import 'dart:io';

import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:yeah_music/config/onedrive_config.dart';
import 'package:yeah_music/logging/app_log.dart';
import 'package:yeah_music/services/onedrive/onedrive_token_store.dart';

/// Microsoft OAuth2（common）终结点；显式配置，避免 OIDC 发现与 id_token `iss` 不一致。
final AuthorizationServiceConfiguration _msOAuth2 = AuthorizationServiceConfiguration(
  authorizationEndpoint: OneDriveConfig.authorizationEndpoint,
  tokenEndpoint: OneDriveConfig.tokenEndpoint,
);

/// Microsoft 登录与刷新（需 [clientId] 非空）。
class OneDriveAuth {
  OneDriveAuth({OneDriveTokenStore? store, FlutterAppAuth? appAuth})
      : _store = store ?? OneDriveTokenStore(),
        _appAuth = appAuth ?? FlutterAppAuth();

  final OneDriveTokenStore _store;
  final FlutterAppAuth _appAuth;

  /// 避免连点触发多路原生 OAuth，全部挂起且日志重复。
  bool _interactiveSignInInFlight = false;

  Future<void> signOut() => _store.clear();

  /// 交互式登录；Linux 等平台无 [FlutterAppAuth] 支持时返回 null。
  Future<({String access, String refresh, DateTime expiry})?> signIn(String clientId) async {
    if (clientId.trim().isEmpty) return null;
    if (Platform.isLinux) return null;

    if (_interactiveSignInInFlight) {
      appLog.w('OneDrive OAuth: 已有登录流程进行中，请勿重复点击');
      return null;
    }
    _interactiveSignInInFlight = true;

    appLog.i(
      'OneDrive OAuth: 开始授权…（macOS 将在系统浏览器中打开 Microsoft 登录页，完成后跳回本应用）',
    );

    Timer? desktopHangWatch;
    if (!Platform.isLinux && !Platform.isIOS && !Platform.isAndroid) {
      desktopHangWatch = Timer.periodic(const Duration(seconds: 25), (_) {
        appLog.w(
          'OneDrive OAuth: 仍在等待：请在已打开的浏览器中完成登录并同意权限；若无浏览器窗口请先切到 Dock/其它桌面。',
        );
      });
    }

    late final AuthorizationTokenResponse res;
    try {
      res = await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          clientId.trim(),
          OneDriveConfig.redirectUrl,
          serviceConfiguration: _msOAuth2,
          scopes: OneDriveConfig.scopes,
        ),
      );
    } on FlutterAppAuthUserCancelledException {
      appLog.w(
        'OneDrive OAuth: 用户取消或系统关闭了登录页（release 模式下此前用 d 级日志会完全不显示）',
      );
      return null;
    } on FlutterAppAuthPlatformException catch (e, st) {
      final d = e.platformErrorDetails;
      appLog.e(
        'OneDrive OAuth: ${d.error} ${d.errorDescription} (type=${d.type} code=${d.code})',
        error: e,
        stackTrace: st,
      );
      return null;
    } catch (e, st) {
      appLog.e('OneDrive OAuth: authorizeAndExchangeCode 异常', error: e, stackTrace: st);
      return null;
    } finally {
      desktopHangWatch?.cancel();
      _interactiveSignInInFlight = false;
    }

    appLog.i('OneDrive OAuth: 授权页返回，正在校验 token 响应');
    final access = res.accessToken;
    final refresh = res.refreshToken;
    if (access == null) {
      appLog.w('OneDrive OAuth: 响应缺少 access_token');
      return null;
    }
    if (refresh == null || refresh.isEmpty) {
      appLog.w(
        'OneDrive OAuth: 缺少 refresh_token（需确认 Microsoft 已授予 offline_access）；无法长期续期令牌',
      );
      return null;
    }
    final expiry = res.accessTokenExpirationDateTime ??
        DateTime.now().add(const Duration(hours: 1));
    try {
      await _store.save(
        accessToken: access,
        refreshToken: refresh,
        accessExpiry: expiry,
      );
    } catch (e, st) {
      appLog.e(
        'OneDrive OAuth: 令牌写入安全存储失败（macOS 钥匙串权限/不可用会导致静默登录失败）',
        error: e,
        stackTrace: st,
      );
      return null;
    }
    appLog.i('OneDrive OAuth: 登录成功');
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
    final tr = await _appAuth.token(
      TokenRequest(
        clientId.trim(),
        OneDriveConfig.redirectUrl,
        refreshToken: refresh,
        serviceConfiguration: _msOAuth2,
        scopes: OneDriveConfig.scopes,
      ),
    );
    final newAccess = tr.accessToken;
    final newRefresh = tr.refreshToken ?? refresh;
    if (newAccess == null) return null;
    final newExp = tr.accessTokenExpirationDateTime ??
        DateTime.now().add(const Duration(hours: 1));
    await _store.save(
      accessToken: newAccess,
      refreshToken: newRefresh,
      accessExpiry: newExp,
    );
    return newAccess;
  }
}
