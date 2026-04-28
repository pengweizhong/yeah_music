/// Microsoft 身份与 Graph 配置。
///
/// **正式发布**：在 Azure 注册「公共客户端 / 移动和桌面」应用，将应用程序（客户端）ID 填入
/// [embeddedApplicationClientId]（可嵌入应用，与常见消费级 App 一致）；或通过 CI 传入
/// `--dart-define=ONEDRIVE_CLIENT_ID=...` 覆盖。
///
/// 1. 「身份验证」平台：**移动和桌面应用程序**，重定向 URI 与 [redirectUrl] **逐字一致**。
/// 2. 「API 权限」Microsoft Graph 委托：`offline_access`、`User.Read`、`Files.Read.All`
///    （后续若需云端备份写入再增加 `Files.ReadWrite` 等）。请求范围见 [scopes]。
abstract final class OneDriveConfig {
  /// 商店包内置的 Azure 应用程序（客户端）ID。开源仓库可留空，改用 dart-define。
  static const String embeddedApplicationClientId = '';

  /// 编译参数覆盖（优先于 [embeddedApplicationClientId]）。
  static const String _clientIdFromEnvironment = String.fromEnvironment(
    'ONEDRIVE_CLIENT_ID',
    defaultValue: '',
  );

  /// 实际用于 OAuth 的 Client ID。
  static String get applicationClientId {
    if (_clientIdFromEnvironment.isNotEmpty) {
      return _clientIdFromEnvironment;
    }
    return embeddedApplicationClientId;
  }

  /// 与 Azure 中「重定向 URI」完全一致（各平台 manifest 已注册此 scheme）。
  /// 注意：除 Android 外，在 **应用注册 → 身份验证 → 移动和桌面应用程序** 中须**再添加同一条**
  /// `com.pengwz.yeahmusic://oauthredirect`（与 Android 包名无关）；仅配 Android 时 macOS/Windows 会无法完成授权。
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
