import 'dart:io';
import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show ImageFilter, PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeah_music/models/user_playlist_cover_style.dart';
import 'package:yeah_music/themes/app_theme_mode_provider.dart';
import 'package:yeah_music/themes/gradient_ui_colors.dart';
import 'package:yeah_music/themes/light_user_gradient_content_theme.dart';
import 'package:yeah_music/themes/wallpaper_readable_scope.dart';
import 'package:yeah_music/themes/user_theme_gradient_foreground_scope.dart';
import 'package:yeah_music/utils/wallpaper_image_bytes.dart';
import 'package:yeah_music/utils/wallpaper_readable_sampler.dart';

/// 主题配置提供者
class ThemeConfigProvider extends ChangeNotifier {
  /// 壁纸自适应字色首帧猜色（采样完成前）：亮系统偏墨、暗系统偏白，减轻首屏闪动。
  static Color _wallpaperInitialFg() =>
      PlatformDispatcher.instance.platformBrightness == Brightness.light
          ? kGradLightInk
          : Colors.white;

  static Color _wallpaperInitialFgMuted() =>
      PlatformDispatcher.instance.platformBrightness == Brightness.light
          ? kGradLightInkMuted
          : const Color(0xFFD2DEEE);

  /// 仅主色已持久化、辅色缺失时：按全局亮/暗补足辅色。
  static const Color _kDefaultGradientSecondaryLight = Color(0xFFDCE4F0);
  static const Color _kDefaultGradientSecondaryDark = Color(0xFF252B34);

  static Color _defaultSecondaryForThemeMode(ThemeMode mode) {
    final light = switch (mode) {
      ThemeMode.light => true,
      ThemeMode.dark => false,
      ThemeMode.system =>
        PlatformDispatcher.instance.platformBrightness == Brightness.light,
    };
    return light
        ? _kDefaultGradientSecondaryLight
        : _kDefaultGradientSecondaryDark;
  }

  // 预设种子色（深色为主，白字在暗色 App 主题下可读；浅色模式选浅灰类时由 [lightUserGradientNeedsInkForeground] 切墨字）
  static const List<Color> presetColors = [
    Color(0xFF7C2D12), // 活力橙（默认，与前版列表末项一致）
    Color(0xFF121212), // 经典黑
    Color(0xFF0A2540), // 深海蓝
    Color(0xFF4C1D95), // 深紫
    Color(0xFF14532D), // 森林绿
    Color(0xFF0F3D4C), // 深青蓝
    Color(0xFF2D1F3D), // 暗紫
    Color(0xFF6B4423), // 焦糖棕
  ];

  /// 与主题设置页预设点选一致：由种子色推导辅色。
  static Color secondaryFromPresetPrimary(Color primary) {
    final hsl = HSLColor.fromColor(primary);
    final sat = hsl.saturation < 0.38 ? 0.38 : hsl.saturation;
    return hsl
        .withHue((hsl.hue + 28.0) % 360.0)
        .withSaturation(sat.clamp(0.0, 0.92))
        .withLightness((hsl.lightness + 0.11).clamp(0.12, 0.52))
        .toColor();
  }

  // 主题类型
  ThemeType _themeType = ThemeType.solidColor;
  Color _primaryColor = ThemeConfigProvider.presetColors.first;
  Color _secondaryColor =
      ThemeConfigProvider.secondaryFromPresetPrimary(
          ThemeConfigProvider.presetColors.first);
  /// 与早期版本一致：主对角线 ↘（左上→右下）。
  PlaylistCoverGradientDirection _gradientDirection =
      PlaylistCoverGradientDirection.diagonalTlBr;
  String? _backgroundImagePath;
  /// 背景图模式：0~1，控制虚化和压暗程度，越大字越易读（默认 0.45）；壁纸下仍保留底衬压暗与渐晕
  double _backgroundImageEffect = 0.45;
  /// 根据壁纸缩略图 WCAG 对比度在「高亮白 / 深墨」间自动择一（及对应次级色）
  Color _wallpaperAdaptiveFg = ThemeConfigProvider._wallpaperInitialFg();
  Color _wallpaperAdaptiveFgMuted = ThemeConfigProvider._wallpaperInitialFgMuted();

  Timer? _wallpaperReadableSampleDebounce;

  ThemeType get themeType => _themeType;
  Color get primaryColor => _primaryColor;
  Color get secondaryColor => _secondaryColor;
  PlaylistCoverGradientDirection get gradientDirection => _gradientDirection;
  String? get backgroundImagePath => _backgroundImagePath;
  double get backgroundImageEffect => _backgroundImageEffect.clamp(0.0, 1.0);

  /// 浅色模式 + 预设/自定义双色渐变：主辅色整体偏亮时用墨色 UI，避免与白字糊成一片。
  bool get lightUserGradientNeedsInkForeground {
    final a = _primaryColor.computeLuminance();
    final b = _secondaryColor.computeLuminance();
    final w = math.max(a, b) * 0.62 + math.min(a, b) * 0.38;
    return w > 0.50;
  }

  ThemeConfigProvider() {
    _loadConfig();
  }

  @override
  void dispose() {
    _wallpaperReadableSampleDebounce?.cancel();
    super.dispose();
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

  /// 换壁纸后仅驱逐该路径的 [FileImage]，避免 [ImageCache.clear] 与正在解码的预览/全页背景抢缓存导致红屏报错。
  void _scheduleDeferredWallpaperImageCacheClear([String? path]) {
    final pth = path ?? _backgroundImagePath;
    if (pth == null || pth.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _evictThemeBackgroundImageCache(pth);
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

    final globalAppearance =
        AppThemeModeProvider.themeModeFromStorage(
          prefs.getInt(AppThemeModeProvider.prefsKey),
        );

    // 加载颜色（无持久化键时按全局亮/暗主题取默认，改善浅色模式首次进入可读性）
    final primaryColorValue = prefs.getInt('primary_color');
    final secondaryColorValue = prefs.getInt('secondary_color');

    if (primaryColorValue != null) {
      _primaryColor = Color(primaryColorValue);
      _secondaryColor = secondaryColorValue != null
          ? Color(secondaryColorValue)
          : ThemeConfigProvider._defaultSecondaryForThemeMode(globalAppearance);
    } else {
      // 无持久化主色时：默认「活力橙」及配套辅色（与预设首项一致）
      _primaryColor = presetColors.first;
      _secondaryColor = secondaryColorValue != null
          ? Color(secondaryColorValue)
          : ThemeConfigProvider.secondaryFromPresetPrimary(presetColors.first);
    }

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
    _resetWallpaperAdaptiveToPlatformGuess();
    _scheduleWallpaperReadableSample();
    notifyListeners();
  }

  /// 设置主题类型
  Future<void> setThemeType(ThemeType type) async {
    _themeType = type;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_type', type.index);
    _resetWallpaperAdaptiveToPlatformGuess();
    if (type == ThemeType.backgroundImage) {
      _scheduleWallpaperReadableSample();
    }
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
      _resetWallpaperAdaptiveToPlatformGuess();
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
      _scheduleDeferredWallpaperImageCacheClear(destPath);
    } catch (e) {
      rethrow;
    }
    notifyListeners();
    _scheduleWallpaperReadableSample();
  }

  /// 裁剪页输出的字节直接写入应用支持目录（当前为 PNG），避免临时文件再读取造成峰值内存翻倍。
  Future<void> setBackgroundImageFromBytes(Uint8List bytes) async {
    if (bytes.isEmpty) return;
    final normalized = await normalizeWallpaperImageBytes(bytes);
    if (!await canDecodeWallpaperImageBytes(normalized)) {
      throw StateError('invalid wallpaper image bytes');
    }
    final prefs = await SharedPreferences.getInstance();
    final previousPath = _backgroundImagePath;
    _evictThemeBackgroundImageCache(previousPath);
    await _removeOldThemeCacheFiles();
    final support = await getApplicationSupportDirectory();
    final destPath = p.join(support.path, '$themeBackgroundSupportBaseName.png');
    await File(destPath).writeAsBytes(normalized, flush: true);
    _backgroundImagePath = destPath;
    await prefs.setString('background_image_path', destPath);
    _themeBackgroundImageFrame++;
    _resetWallpaperAdaptiveToPlatformGuess();
    _scheduleDeferredWallpaperImageCacheClear(destPath);
    notifyListeners();
    _scheduleWallpaperReadableSample();
  }

  /// 背景图雾化/压暗强度 0~1（虚化 + 深色蒙层）
  Future<void> setBackgroundImageEffect(double value) async {
    final n = value.clamp(0.0, 1.0);
    if (n == _backgroundImageEffect) return;
    _backgroundImageEffect = n;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('background_image_effect', _backgroundImageEffect);
    _scheduleWallpaperReadableSample(debounce: true);
  }

  void _resetWallpaperAdaptiveToPlatformGuess() {
    _wallpaperAdaptiveFg = ThemeConfigProvider._wallpaperInitialFg();
    _wallpaperAdaptiveFgMuted = ThemeConfigProvider._wallpaperInitialFgMuted();
  }

  /// [debounce]：雾化滑条连续拖动时延后合并，避免解码尖峰。
  void _scheduleWallpaperReadableSample({bool debounce = false}) {
    if (_themeType != ThemeType.backgroundImage) return;
    final pth = _backgroundImagePath;
    if (pth == null || !File(pth).existsSync()) return;

    void runMicro() {
      final e = _backgroundImageEffect.clamp(0.0, 1.0);
      final scrim = (0.11 + e * 0.57).clamp(0.0, 0.78);
      final lumaScale = (1.0 - scrim * 0.48).clamp(0.38, 1.0);
      Future.microtask(() async {
        final sample = await sampleWallpaperReadableColors(
          pth,
          sampleLumaScale: lumaScale,
        );
        if (_themeType != ThemeType.backgroundImage || _backgroundImagePath != pth) return;
        if (sample == null) return;
        if (_wallpaperAdaptiveFg == sample.foreground &&
            _wallpaperAdaptiveFgMuted == sample.foregroundMuted) {
          return;
        }
        _wallpaperAdaptiveFg = sample.foreground;
        _wallpaperAdaptiveFgMuted = sample.foregroundMuted;
        notifyListeners();
      });
    }

    if (debounce) {
      _wallpaperReadableSampleDebounce?.cancel();
      _wallpaperReadableSampleDebounce = Timer(const Duration(milliseconds: 280), runMicro);
      return;
    }
    runMicro();
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
      // 虚化略加强，削弱纹理与细字竞争；滑块为 0 时仍无模糊，由底衬蒙层保证最低可读性
      final sigma = e * 14.0;
      // 统一压暗：低档亦保留底衬，避免壁纸亮部/花纹与固定色字（白/墨）直接抢对比
      final scrim = (0.11 + e * 0.57).clamp(0.0, 0.78);
      // 顶/底略重，减轻状态栏、底部导航与长列表中部「偶发撞色」
      final vignette = (0.045 + e * 0.11).clamp(0.045, 0.22);
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
                  final cacheW =
                      (sz.width * dpr).round().clamp(1, kWallpaperImageMaxSide);
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
                    cacheWidth: cacheW,
                    errorBuilder: (context, error, stackTrace) {
                      return ColoredBox(
                        color: const Color(0xFF121820),
                        child: Center(
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            color: Colors.white.withValues(alpha: 0.35),
                            size: 48,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
          if (isLight)
            Positioned.fill(
              child: IgnorePointer(
                child: ColoredBox(
                  color: kGradLightInk.withValues(alpha: 0.028 + e * 0.10),
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
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.fromRGBO(0, 0, 0, vignette * 0.88),
                      Color.fromRGBO(0, 0, 0, vignette * 0.28),
                      Color.fromRGBO(0, 0, 0, vignette),
                    ],
                    stops: const [0.0, 0.48, 1.0],
                  ),
                ),
              ),
            ),
          ),
          WallpaperReadableScope(
            foreground: _wallpaperAdaptiveFg,
            foregroundMuted: _wallpaperAdaptiveFgMuted,
            child: _ThemedOnGradientContent(child: child),
          ),
        ],
      );
    }
    final useLightUserGradientFg = isLight &&
        !(_themeType == ThemeType.backgroundImage &&
            _backgroundImagePath != null &&
            File(_backgroundImagePath!).existsSync());

    Widget tree = _ThemedOnGradientContent(child: child);
    if (useLightUserGradientFg) {
      if (lightUserGradientNeedsInkForeground) {
        tree = Theme(
          data: themeForBrightLightGradientOverlay(context),
          child: tree,
        );
      } else {
        tree = UserThemeGradientForegroundScope(
          child: Theme(
            data: themeForLightUserGradientShell(context),
            child: tree,
          ),
        );
      }
    }

    return Container(
      decoration: getBackgroundDecoration(),
      child: tree,
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
    final wp = WallpaperReadableScope.maybeOf(context);
    final Color c;
    if (wp != null) {
      c = wp.foreground;
    } else if (UserThemeGradientForegroundScope.maybeOf(context) != null) {
      c = Colors.white;
    } else {
      c = Theme.of(context).brightness == Brightness.light
          ? kGradLightInk
          : Colors.white;
    }
    return Theme(
      data: Theme.of(context).copyWith(
        switchTheme: gradOnBackgroundSwitchTheme(context),
      ),
      child: DefaultTextStyle(
        style: TextStyle(color: c, height: 1.3),
        child: IconTheme(
          data: IconThemeData(color: c),
          child: child,
        ),
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
