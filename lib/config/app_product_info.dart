import 'package:package_info_plus/package_info_plus.dart';

/// 应用对外标识：**关于对话框**、**设置页关于一行**、**歌单导出 / 设置备份 JSON** 等与构建信息对齐的统一入口。
///
/// 版本号来自 [PackageInfo]（与 `pubspec.yaml` 的 `version:` 及各平台构建号一致）。
abstract final class AppProductInfo {
  AppProductInfo._();

  /// 与 [AppLocalizations.appTitle] 一致的产品名（导出 `app.name`、关于标题）。
  static const String displayName = 'Yeah Music';

  static PackageInfo? _cached;

  /// 在依赖版本字符串之前调用（[main] 中 `WidgetsFlutterBinding.ensureInitialized` 之后）。
  static Future<void> load() async {
    _cached ??= await PackageInfo.fromPlatform();
  }

  /// 语义版本，如 `1.0.0`。
  static String get version => _cached?.version ?? '1.0.0';

  /// 构建号，如 Android versionCode。
  static String get buildNumber => _cached?.buildNumber ?? '1';

  /// `pubspec` 风格：`1.0.0+1`
  static String get versionPlusBuild => '$version+$buildNumber';

  /// 写入导出 JSON / 云备份上的 `app` 对象。
  static Map<String, dynamic> get exportMetadataBlock => {
        'name': displayName,
        'version': version,
        'buildNumber': buildNumber,
        'versionPlusBuild': versionPlusBuild,
      };
}
