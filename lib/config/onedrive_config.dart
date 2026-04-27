/// Microsoft 身份与 Graph 配置。
///
/// 1. 在 [Azure Portal](https://portal.azure.com/) 注册应用 → 「移动和桌面应用程序」。
/// 2. 将重定向 URI 设为 [redirectUrl]（须与本项目各平台配置一致）。
/// 3. 将应用（客户端）ID 填入应用内「OneDrive 设置」，或通过编译参数
///    `--dart-define=ONEDRIVE_CLIENT_ID=你的GUID` 作为默认值。
abstract final class OneDriveConfig {
  /// 编译时默认 Client ID；应用内设置可覆盖。
  static const String defaultClientIdFromEnv = String.fromEnvironment(
    'ONEDRIVE_CLIENT_ID',
    defaultValue: '',
  );

  /// 与 Azure 中「重定向 URI」完全一致（各平台 manifest 已注册此 scheme）。
  static const String redirectUrl = 'com.pengwz.yeahmusic://oauthredirect';

  static const List<String> scopes = <String>[
    'openid',
    'profile',
    'offline_access',
    'Files.Read',
    'User.Read',
  ];

  static const String graphBase = 'https://graph.microsoft.com/v1.0';

  static const String discoveryUrl =
      'https://login.microsoftonline.com/common/v2.0/.well-known/openid-configuration';

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
