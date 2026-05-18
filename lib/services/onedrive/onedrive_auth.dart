import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:http/http.dart' as http;
import 'package:yeah_music/config/onedrive_config.dart';
import 'package:yeah_music/l10n/app_localizations.dart';
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

  static final Uri _deviceCodeEndpoint = Uri.parse(
    'https://login.microsoftonline.com/common/oauth2/v2.0/devicecode',
  );
  static final Uri _tokenEndpoint = Uri.parse(OneDriveConfig.tokenEndpoint);

  /// 避免连点触发多路原生 OAuth，全部挂起且日志重复。
  bool _interactiveSignInInFlight = false;
  String? _lastErrorMessage;

  String? get lastErrorMessage => _lastErrorMessage;

  Future<void> signOut() => _store.clear();

  /// 交互式登录；Linux 等平台无 [FlutterAppAuth] 支持时返回 null。
  Future<({String access, String refresh, DateTime expiry})?> signIn(
    String clientId,
    AppLocalizations l10n,
  ) async {
    _lastErrorMessage = null;
    if (clientId.trim().isEmpty) return null;
    if (Platform.isLinux) {
      return _signInByDeviceCode(clientId.trim(), l10n);
    }

    if (_interactiveSignInInFlight) {
      appLog.w('OneDrive OAuth: 已有登录流程进行中，请勿重复点击');
      _lastErrorMessage = l10n.oneDriveSignInInProgress;
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
      _lastErrorMessage = l10n.oneDriveSignInCancelled;
      return null;
    } on FlutterAppAuthPlatformException catch (e, st) {
      final d = e.platformErrorDetails;
      final errDesc = d.errorDescription ?? '';
      final err = d.error ?? '';
      appLog.e(
        'OneDrive OAuth: ${d.error} ${d.errorDescription} (type=${d.type} code=${d.code})',
        error: e,
        stackTrace: st,
      );
      _lastErrorMessage = errDesc.trim().isNotEmpty
          ? (err.trim().isNotEmpty
              ? l10n.oneDriveOAuthErrorWithDetail(err, errDesc)
              : errDesc)
          : (err.trim().isNotEmpty ? err : l10n.oneDriveOAuthPlatformError);
      return null;
    } catch (e, st) {
      appLog.e('OneDrive OAuth: authorizeAndExchangeCode 异常', error: e, stackTrace: st);
      _lastErrorMessage = '$e';
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
      _lastErrorMessage = l10n.oneDriveSignInMissingAccessToken;
      return null;
    }
    if (refresh == null || refresh.isEmpty) {
      appLog.w(
        'OneDrive OAuth: 缺少 refresh_token（需确认 Microsoft 已授予 offline_access）；无法长期续期令牌',
      );
      _lastErrorMessage = l10n.oneDriveSignInMissingRefreshToken;
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
      _lastErrorMessage = l10n.oneDriveSignInTokenSaveFailed('$e');
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
    if (Platform.isLinux) {
      return _refreshAccessTokenByHttp(
        clientId: clientId.trim(),
        refreshToken: refresh,
      );
    }
    try {
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
    } catch (e, st) {
      appLog.e('OneDrive OAuth: refresh token 续期失败', error: e, stackTrace: st);
      return null;
    }
  }

  Future<String?> _refreshAccessTokenByHttp({
    required String clientId,
    required String refreshToken,
  }) async {
    try {
      final res = await http.post(
        _tokenEndpoint,
        headers: const {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: <String, String>{
          'client_id': clientId,
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
          'scope': OneDriveConfig.scopes.join(' '),
        },
      );
      if (res.statusCode < 200 || res.statusCode >= 300) {
        appLog.w('OneDrive OAuth: Linux refresh 失败 ${res.statusCode}: ${res.body}');
        return null;
      }
      final raw = jsonDecode(res.body);
      if (raw is! Map<String, dynamic>) return null;
      final newAccess = (raw['access_token'] as String?)?.trim();
      final newRefresh = ((raw['refresh_token'] as String?)?.trim().isNotEmpty ?? false)
          ? (raw['refresh_token'] as String).trim()
          : refreshToken;
      final expiresIn = (raw['expires_in'] as num?)?.toInt() ?? 3600;
      if (newAccess == null || newAccess.isEmpty) return null;
      final expiry = DateTime.now().add(Duration(seconds: expiresIn));
      await _store.save(
        accessToken: newAccess,
        refreshToken: newRefresh,
        accessExpiry: expiry,
      );
      return newAccess;
    } catch (e, st) {
      appLog.e('OneDrive OAuth: Linux refresh 异常', error: e, stackTrace: st);
      return null;
    }
  }

  Future<({String access, String refresh, DateTime expiry})?> _signInByDeviceCode(
    String clientId,
    AppLocalizations l10n,
  ) async {
    if (_interactiveSignInInFlight) {
      appLog.w('OneDrive OAuth: 已有登录流程进行中，请勿重复点击');
      _lastErrorMessage = l10n.oneDriveSignInInProgress;
      return null;
    }
    _interactiveSignInInFlight = true;
    try {
      final dc = await http.post(
        _deviceCodeEndpoint,
        headers: const {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: <String, String>{
          'client_id': clientId,
          'scope': OneDriveConfig.scopes.join(' '),
        },
      );
      if (dc.statusCode < 200 || dc.statusCode >= 300) {
        appLog.w('OneDrive OAuth: Linux device code 获取失败 ${dc.statusCode}: ${dc.body}');
        _lastErrorMessage = _friendlyOAuthError(
          dc.body,
          l10n: l10n,
          fallback: l10n.oneDriveSignInDeviceCodeFailed(dc.statusCode),
        );
        return null;
      }
      final m = jsonDecode(dc.body);
      if (m is! Map<String, dynamic>) return null;
      final deviceCode = (m['device_code'] as String?)?.trim();
      final userCode = (m['user_code'] as String?)?.trim();
      final verifyUri = (m['verification_uri_complete'] as String?)?.trim().isNotEmpty == true
          ? (m['verification_uri_complete'] as String).trim()
          : (m['verification_uri'] as String?)?.trim();
      final expiresIn = (m['expires_in'] as num?)?.toInt() ?? 900;
      var interval = (m['interval'] as num?)?.toInt() ?? 5;
      final humanMessage = (m['message'] as String?)?.trim();
      if (deviceCode == null || deviceCode.isEmpty) return null;
      appLog.i('OneDrive Linux 登录：$humanMessage');
      if (verifyUri != null && verifyUri.isNotEmpty) {
        appLog.i('OneDrive Linux 登录地址：$verifyUri');
        try {
          await Process.start(
            'xdg-open',
            <String>[verifyUri],
            runInShell: true,
          );
        } catch (_) {}
      }
      if (userCode != null && userCode.isNotEmpty) {
        appLog.i('OneDrive Linux 用户码：$userCode');
      }

      final deadline = DateTime.now().add(Duration(seconds: expiresIn));
      while (DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(Duration(seconds: interval));
        final tk = await http.post(
          _tokenEndpoint,
          headers: const {
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          body: <String, String>{
            'client_id': clientId,
            'grant_type': 'urn:ietf:params:oauth:grant-type:device_code',
            'device_code': deviceCode,
          },
        );
        if (tk.statusCode >= 200 && tk.statusCode < 300) {
          final raw = jsonDecode(tk.body);
          if (raw is! Map<String, dynamic>) return null;
          final access = (raw['access_token'] as String?)?.trim();
          final refresh = (raw['refresh_token'] as String?)?.trim();
          final ttl = (raw['expires_in'] as num?)?.toInt() ?? 3600;
          if (access == null || access.isEmpty || refresh == null || refresh.isEmpty) {
            return null;
          }
          final expiry = DateTime.now().add(Duration(seconds: ttl));
          await _store.save(
            accessToken: access,
            refreshToken: refresh,
            accessExpiry: expiry,
          );
          appLog.i('OneDrive Linux 登录成功');
          return (access: access, refresh: refresh, expiry: expiry);
        }
        final rawErr = jsonDecode(tk.body);
        final err = rawErr is Map<String, dynamic>
            ? (rawErr['error'] as String?)?.trim()
            : null;
        if (err == 'authorization_pending') continue;
        if (err == 'slow_down') {
          interval += 2;
          continue;
        }
        if (err == 'authorization_declined' ||
            err == 'expired_token' ||
            err == 'bad_verification_code') {
          appLog.w('OneDrive Linux 登录中断: $err');
          _lastErrorMessage = l10n.oneDriveSignInInterrupted(err ?? '');
          return null;
        }
        appLog.w('OneDrive Linux 登录失败: ${tk.body}');
        _lastErrorMessage = _friendlyOAuthError(
          tk.body,
          l10n: l10n,
          fallback: l10n.oneDriveSignInFailed,
        );
        return null;
      }
      appLog.w('OneDrive Linux 登录超时');
      _lastErrorMessage = l10n.oneDriveSignInTimedOut;
      return null;
    } catch (e, st) {
      appLog.e('OneDrive Linux 登录异常', error: e, stackTrace: st);
      _lastErrorMessage = '$e';
      return null;
    } finally {
      _interactiveSignInInFlight = false;
    }
  }

  String _friendlyOAuthError(
    String raw, {
    required AppLocalizations l10n,
    required String fallback,
  }) {
    try {
      final m = jsonDecode(raw);
      if (m is! Map<String, dynamic>) return fallback;
      final err = (m['error'] as String?)?.trim() ?? '';
      final desc = (m['error_description'] as String?)?.trim() ?? '';
      if (err == 'invalid_client' &&
          (desc.contains('must be marked as \'mobile\'') ||
              desc.contains('must be marked as "mobile"') ||
              desc.contains('AADSTS70002'))) {
        return l10n.oneDriveLinuxUnsupported;
      }
      if (desc.isNotEmpty && err.isNotEmpty) {
        return l10n.oneDriveOAuthErrorWithDetail(err, desc);
      }
      if (desc.isNotEmpty) return desc;
      if (err.isNotEmpty) return err;
      return fallback;
    } catch (_) {
      return fallback;
    }
  }
}
