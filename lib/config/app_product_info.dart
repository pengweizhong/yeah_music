import 'package:package_info_plus/package_info_plus.dart';

/// 对外「产品 / 构建」信息的统一入口（关于页、导出元数据、备份 JSON 等）。
///
/// ### 版本号从哪里来（各平台打包）
///
/// **唯一维护点**是仓库根目录 `pubspec.yaml` 里的 `version:`，格式 **`x.y.z+build`**（例如 `1.2.3+45`）。
/// 执行 `flutter build apk`、`flutter build ipa`、`flutter build macos` 等时，Flutter 会把同一组数字写入：
///
/// - **Android**：`versionName` ← `x.y.z`，`versionCode` ← `build`
/// - **iOS / macOS**：`CFBundleShortVersionString`、`CFBundleVersion`
/// - **Windows / Linux**：嵌入构建产物内的元数据
///
/// **运行时读取**：[`PackageInfo.fromPlatform`]（[`package_info_plus`](https://pub.dev/packages/package_info_plus)）
/// 从**当前已安装实例**读出上述字段；本类只做缓存与命名。**不要在 UI 里手写版本字符串**，应始终通过此处读取。
///
/// ### 名称
///
/// - [displayName]：与本地化 [`AppLocalizations.appTitle`] 对齐的展示名（导出 JSON、关于标题）。
/// - [installerLabel]：安装包报告的 `appName`（可能与系统语言/商店展示一致；不可用时退回 [displayName]）。
abstract final class AppProductInfo {
  AppProductInfo._();

  /// 与 [AppLocalizations.appTitle] 一致的产品名（导出 `app.name`、关于标题）。
  static const String displayName = 'Yeah Music';

  static PackageInfo? _cached;

  /// 在读取 [version] / [buildNumber] 之前调用（已在 [main] 里 `WidgetsFlutterBinding.ensureInitialized` 之后执行）。
  static Future<void> load() async {
    _cached ??= await PackageInfo.fromPlatform();
  }

  /// 语义版本，如 `1.0.0`。
  static String get version => _cached?.version ?? '1.0.0';

  /// 构建号（Android `versionCode`、iOS `CFBundleVersion` 等）。
  static String get buildNumber => _cached?.buildNumber ?? '1';

  /// `pubspec` 风格：`1.0.0+1`（设置列表副标题、调试信息）。
  static String get versionPlusBuild => '$version+$buildNumber';

  /// 安装包内的应用标签（桌面快捷方式 / 启动器名称等）；未加载 [load] 前为空字符串则退回 [displayName]。
  static String get installerLabel =>
      (_cached?.appName ?? '').trim().isEmpty ? displayName : _cached!.appName;

  /// 包名（Android applicationId、iOS bundle identifier 等）。
  static String get packageName => _cached?.packageName ?? '';

  /// 写入导出 JSON / 云备份上的 `app` 对象。
  static Map<String, dynamic> get exportMetadataBlock => {
        'name': displayName,
        'version': version,
        'buildNumber': buildNumber,
        'versionPlusBuild': versionPlusBuild,
        if (packageName.isNotEmpty) 'packageName': packageName,
      };
}
