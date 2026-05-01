import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeah_music/models/user_playlist_cover_style.dart';
import 'package:yeah_music/themes/gradient_ui_colors.dart';

/// 主题配置提供者
class ThemeConfigProvider extends ChangeNotifier {
  // 主题类型
  ThemeType _themeType = ThemeType.solidColor;
  Color _primaryColor = const Color(0xFF121212);
  Color _secondaryColor = const Color(0xFF1A1A1A);
  /// 与早期版本一致：主对角线 ↘（左上→右下）。
  PlaylistCoverGradientDirection _gradientDirection =
      PlaylistCoverGradientDirection.diagonalTlBr;
  String? _backgroundImagePath;
  /// 背景图模式：0~1，控制虚化和压暗程度，越大字越易读（默认 0.45）
  double _backgroundImageEffect = 0.45;

  ThemeType get themeType => _themeType;
  Color get primaryColor => _primaryColor;
  Color get secondaryColor => _secondaryColor;
  PlaylistCoverGradientDirection get gradientDirection => _gradientDirection;
  String? get backgroundImagePath => _backgroundImagePath;
  double get backgroundImageEffect => _backgroundImageEffect.clamp(0.0, 1.0);

  // 预设颜色
  static const List<Color> presetColors = [
    Color(0xFF121212), // 纯黑
    Color(0xFF1A1A2E), // 深蓝
    Color(0xFF16213E), // 海军蓝
    Color(0xFF0F3460), // 深青
    Color(0xFF1F1F1F), // 深灰
    Color(0xFF2C1810), // 深棕
    Color(0xFF1A1520), // 深紫
    Color(0xFF0D1B2A), // 深蓝黑
  ];

  ThemeConfigProvider() {
    _loadConfig();
  }

  String _themeImageExtension(String filePath) {
    final e = p.extension(filePath).toLowerCase();
    if (e == '.jpeg' || e == '.jpg') return '.jpg';
    if (e == '.png' || e == '.webp') return e;
    return '.jpg';
  }

  /// 应用支持目录下主题壁纸文件名前缀（不含扩展名）；云端恢复写入路径须与此一致。
  static const String themeBackgroundSupportBaseName = 'theme_user_background';

  /// [Image.file] 缓存键随重载递增，路径不变但文件被覆盖时仍能换图。
  int _themeBackgroundImageFrame = 0;

  /// 壁纸文件写入磁盘后的代数（路径不变仅覆盖文件时也会增加）。用于预览图 [ValueKey] 等与全页背景同步刷新。
  int get themeBackgroundImageGeneration => _themeBackgroundImageFrame;

  void _evictThemeBackgroundImageCache(String? path) {
    if (path == null || path.isEmpty) return;
    final f = File(path);
    if (!f.existsSync()) return;
    PaintingBinding.instance.imageCache.evict(FileImage(f));
  }

  /// [ResizeImage(FileImage)] 等与路径绑定的解码缓存需在换壁纸后失效。
  /// 禁止在 [notifyListeners] 触发的同步布局阶段调用 [ImageCache.clear]，部分机型会断言崩溃；
  /// 延后到当前帧绘制结束再清空。
  void _scheduleDeferredWallpaperImageCacheClear() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        PaintingBinding.instance.imageCache.clear();
      } catch (_) {}
    });
  }

  /// 外部队路径、相册/云盘路径在冷启动后可能 [Operation not permitted]；可读的会复制到应用支持目录
  Future<void> _ensureBackgroundCacheOrClear() async {
    if (_backgroundImagePath == null) return;
    final raw = _backgroundImagePath!;
    final f = File(raw);
    if (!f.existsSync()) {
      _backgroundImagePath = null;
      await _prefsRemoveBackgroundPath();
      return;
    }
    try {
      final r = await f.open(mode: FileMode.read);
      await r.close();
    } catch (_) {
      _backgroundImagePath = null;
      await _prefsRemoveBackgroundPath();
      return;
    }
    if (_isInAppSupportCache(p.basename(raw))) {
      return;
    }
    try {
      final support = await getApplicationSupportDirectory();
      final ext = _themeImageExtension(raw);
      final dest = File(p.join(support.path, '$themeBackgroundSupportBaseName$ext'));
      await f.copy(dest.path);
      _backgroundImagePath = dest.path;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('background_image_path', dest.path);
    } catch (_) {
      _backgroundImagePath = null;
      await _prefsRemoveBackgroundPath();
    }
  }

  bool _isInAppSupportCache(String basename) {
    return basename.startsWith('$themeBackgroundSupportBaseName.');
  }

  Future<void> _prefsRemoveBackgroundPath() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('background_image_path');
  }

  Future<void> _removeOldThemeCacheFiles() async {
    final support = await getApplicationSupportDirectory();
    for (final name in <String>[
      '$themeBackgroundSupportBaseName.jpg',
      '$themeBackgroundSupportBaseName.jpeg',
      '$themeBackgroundSupportBaseName.png',
      '$themeBackgroundSupportBaseName.webp',
    ]) {
      final f = File(p.join(support.path, name));
      if (f.existsSync()) {
        _evictThemeBackgroundImageCache(f.path);
        try {
          await f.delete();
        } catch (_) {}
      }
    }
  }

  /// [applyCloudBackupMap] / 外链恢复 prefs 后与冷启动一致的再读盘。
  Future<void> reloadFromStorage() async {
    await _loadConfig();
  }

  /// 加载配置
  Future<void> _loadConfig() async {
    final prefs = await SharedPreferences.getInstance();

    // 加载主题类型
    final typeIndex = prefs.getInt('theme_type') ?? 0;
    _themeType = ThemeType.values[typeIndex];

    // 加载颜色
    final primaryColorValue = prefs.getInt('primary_color') ?? 0xFF121212;
    _primaryColor = Color(primaryColorValue);

    final secondaryColorValue = prefs.getInt('secondary_color') ?? 0xFF1A1A1A;
    _secondaryColor = Color(secondaryColorValue);

    final dirRaw = prefs.getInt('theme_gradient_direction');
    _gradientDirection = dirRaw == null
        ? PlaylistCoverGradientDirection.diagonalTlBr
        : PlaylistCoverGradientDirection.fromStorage(dirRaw);

    // 加载背景图片路径
    _backgroundImagePath = prefs.getString('background_image_path');
    _backgroundImageEffect =
        prefs.getDouble('background_image_effect') ?? 0.45;

    await _ensureBackgroundCacheOrClear();
    if (_backgroundImagePath == null &&
        prefs.getString('background_image_path') != null) {
      await prefs.remove('background_image_path');
    }

    _themeBackgroundImageFrame++;
    _evictThemeBackgroundImageCache(_backgroundImagePath);
    notifyListeners();
  }

  /// 设置主题类型
  Future<void> setThemeType(ThemeType type) async {
    _themeType = type;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_type', type.index);
    notifyListeners();
  }

  /// 设置主色调
  Future<void> setPrimaryColor(Color color) async {
    _primaryColor = color;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('primary_color', color.value);
    notifyListeners();
  }

  /// 设置次色调
  Future<void> setSecondaryColor(Color color) async {
    _secondaryColor = color;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('secondary_color', color.value);
    notifyListeners();
  }

  /// 一次性写入双色与渐变方向（与 RGB 渐变对话框配套）。
  Future<void> setGradientColorsAndDirection(
    Color primary,
    Color secondary,
    PlaylistCoverGradientDirection direction,
  ) async {
    _primaryColor = primary;
    _secondaryColor = secondary;
    _gradientDirection = direction;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('primary_color', primary.value);
    await prefs.setInt('secondary_color', secondary.value);
    await prefs.setInt('theme_gradient_direction', direction.index);
    notifyListeners();
  }

  /// 设置背景图片（写入应用支持目录固定文件名，避免 OneDrive/相册等路径冷启动后无权限）
  Future<void> setBackgroundImage(String? path) async {
    final prefs = await SharedPreferences.getInstance();
    if (path == null) {
      _evictThemeBackgroundImageCache(_backgroundImagePath);
      await _removeOldThemeCacheFiles();
      _backgroundImagePath = null;
      await prefs.remove('background_image_path');
      _themeBackgroundImageFrame++;
      _scheduleDeferredWallpaperImageCacheClear();
      notifyListeners();
      return;
    }
    try {
      final source = File(path);
      if (!source.existsSync()) {
        return;
      }
      await _removeOldThemeCacheFiles();
      final support = await getApplicationSupportDirectory();
      final ext = _themeImageExtension(path);
      final destPath = p.join(support.path, '$themeBackgroundSupportBaseName$ext');
      // 不用 File.copy：覆盖固定缓存路径时部分环境下解码缓存不易失效；读出再写入并 bump frame。
      final rawBytes = await source.readAsBytes();
      await File(destPath).writeAsBytes(rawBytes, flush: true);
      _backgroundImagePath = destPath;
      await prefs.setString('background_image_path', destPath);
      _themeBackgroundImageFrame++;
      _scheduleDeferredWallpaperImageCacheClear();
    } catch (e) {
      rethrow;
    }
    notifyListeners();
  }

  /// 裁剪页输出的字节直接写入应用支持目录（当前为 PNG），避免临时文件再读取造成峰值内存翻倍。
  Future<void> setBackgroundImageFromBytes(Uint8List bytes) async {
    if (bytes.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await _removeOldThemeCacheFiles();
    final support = await getApplicationSupportDirectory();
    final destPath = p.join(support.path, '$themeBackgroundSupportBaseName.png');
    await File(destPath).writeAsBytes(bytes, flush: true);
    _backgroundImagePath = destPath;
    await prefs.setString('background_image_path', destPath);
    _themeBackgroundImageFrame++;
    _scheduleDeferredWallpaperImageCacheClear();
    notifyListeners();
  }

  /// 背景图雾化/压暗强度 0~1（虚化 + 深色蒙层）
  Future<void> setBackgroundImageEffect(double value) async {
    final n = value.clamp(0.0, 1.0);
    if (n == _backgroundImageEffect) return;
    _backgroundImageEffect = n;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('background_image_effect', _backgroundImageEffect);
  }

  /// 全页背景：自定义图时用 [ImageFiltered] + 蒙层，其它与 [getBackgroundDecoration] 一致。
  /// 必须传入 [context]，以响应 [AppThemeModeProvider] / [ThemeMode] 的亮暗。
  Widget buildThemedBackground({
    required BuildContext context,
    required Widget child,
  }) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    if (_themeType == ThemeType.backgroundImage &&
        _backgroundImagePath != null &&
        File(_backgroundImagePath!).existsSync()) {
      final e = _backgroundImageEffect.clamp(0.0, 1.0);
      final sigma = e * 12.0;
      final scrim = e * 0.68;
      return Stack(
        key: ValueKey<int>(_themeBackgroundImageFrame),
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
              child: Builder(
                builder: (ctx) {
                  final sz = MediaQuery.sizeOf(ctx);
                  final dpr = MediaQuery.devicePixelRatioOf(ctx);
                  final w = (sz.width * dpr).round().clamp(1, 4096);
                  final h = (sz.height * dpr).round().clamp(1, 4096);
                  return Image.file(
                    File(_backgroundImagePath!),
                    key: ValueKey<String>(
                      'ym_theme_bg_${_backgroundImagePath}_$_themeBackgroundImageFrame',
                    ),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    alignment: Alignment.center,
                    filterQuality: FilterQuality.low,
                    cacheWidth: w,
                    cacheHeight: h,
                  );
                },
              ),
            ),
          ),
          if (isLight)
            Positioned.fill(
              child: IgnorePointer(
                child: ColoredBox(
                  color: kGradLightInk.withValues(alpha: 0.045),
                ),
              ),
            ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Color.fromRGBO(0, 0, 0, scrim),
                ),
              ),
            ),
          ),
          _ThemedOnGradientContent(child: child),
        ],
      );
    }
    if (isLight) {
      // 白昼：提亮冷灰渐变，避免「发乌」与中灰字糊在一起（与全局浅色 [Theme] 对齐）
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE8ECF3),
              Color(0xFFD9E0EA),
              Color(0xFFC8D2DF),
            ],
            stops: [0.0, 0.45, 1.0],
          ),
        ),
        child: _ThemedOnGradientContent(child: child),
      );
    }
    return Container(
      decoration: getBackgroundDecoration(),
      child: _ThemedOnGradientContent(child: child),
    );
  }

  LinearGradient _themeBackgroundLinearGradient() => playlistCoverLinearGradient(
        [_primaryColor, _secondaryColor],
        direction: _gradientDirection,
      );

  /// 获取背景装饰
  BoxDecoration getBackgroundDecoration() {
    switch (_themeType) {
      case ThemeType.solidColor:
        return BoxDecoration(gradient: _themeBackgroundLinearGradient());
      case ThemeType.customColor:
        return BoxDecoration(gradient: _themeBackgroundLinearGradient());
      case ThemeType.backgroundImage:
        if (_backgroundImagePath != null && File(_backgroundImagePath!).existsSync()) {
          // 实际渲染见 [buildThemedBackground]
          return const BoxDecoration(color: Colors.transparent);
        }
        // 如果图片不存在，回退到纯色
        return BoxDecoration(gradient: _themeBackgroundLinearGradient());
    }
  }
}

class _ThemedOnGradientContent extends StatelessWidget {
  const _ThemedOnGradientContent({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final c = isLight ? kGradLightInk : Colors.white;
    return DefaultTextStyle(
      style: TextStyle(color: c, height: 1.3),
      child: IconTheme(
        data: IconThemeData(color: c),
        child: child,
      ),
    );
  }
}

/// 主题类型枚举
enum ThemeType {
  solidColor,      // 纯色
  customColor,     // 自定义颜色
  backgroundImage, // 背景图片
}
