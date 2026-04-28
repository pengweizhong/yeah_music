/// Microsoft 身份与 Graph 配置。
///
/// 1. 在 [Azure Portal](https://portal.azure.com/) 注册应用 → 「移动和桌面应用程序」。
/// 2. 「身份验证」中添加与 [redirectUrl] 完全一致的重定向 URI（须与各平台 manifest 一致）。
/// 3. 「API 权限」中 Microsoft Graph **委托**：`offline_access`、`User.Read`、读文件权限（如
///    `Files.Read.All`）。请求范围见 [scopes]（不含 `openid`/`profile`，见类注释）。
/// 4. 将应用（客户端）ID 填入应用内「OneDrive 设置」，或通过编译参数
///    `--dart-define=ONEDRIVE_CLIENT_ID=你的GUID` 作为默认值。
abstract final class OneDriveConfig {
  /// 编译时默认 Client ID；应用内设置可覆盖。
  static const String defaultClientIdFromEnv = String.fromEnvironment(
    'ONEDRIVE_CLIENT_ID',
    defaultValue: '',
  );

  /// 与 Azure 中「重定向 URI」完全一致（各平台 manifest 已注册此 scheme）。
  static const String redirectUrl = 'com.pengwz.yeahmusic://oauthredirect';

  /// OAuth 2.0 所用 scope。**不包含** `openid`/`profile`：若走 OIDC 发现并重验 id_token，
  /// 「/common」多租户下文稿中的 issuer 与用户 token 内 `iss`（租户专有）不一致，会触发
  /// Android AppAuth **Invalid ID Token / Issuer mismatch**。我们只依赖 access_token 调 Graph。
  static const List<String> scopes = <String>[
    'offline_access',
    'Files.Read.All',
    'User.Read',
  ];

  static const String graphBase = 'https://graph.microsoft.com/v1.0';

  /// Microsoft OAuth2 v2 「common」租户（工作或个人账户）。仅用授权/令牌 URL，不使用 OIDC
  /// `.well-known`（原因见 [scopes]）。
  static const String authorizationEndpoint =
      'https://login.microsoftonline.com/common/oauth2/v2.0/authorize';

  /// 与 [authorizationEndpoint] 同属 common 端点的令牌终结点。
  static const String tokenEndpoint =
      'https://login.microsoftonline.com/common/oauth2/v2.0/token';

  static bool isAudioFileName(String name) {
    final lower = name.toLowerCase();
    return lower.endsWith('.mp3') ||
        lower.endsWith('.flac') ||
        lower.endsWith('.m4a') ||
        lower.endsWith('.aac') ||
        lower.endsWith('.wav') ||
        lower.endsWith('.ogg') ||
        lower.endsWith('.opus') ||
        lower.endsWith('.wma');
  }
}
