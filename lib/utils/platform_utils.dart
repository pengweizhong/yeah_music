import 'dart:io';

class PlatformUtils {
  ///获取正在运行平台名称
  String getPlatformName() {
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    if (Platform.isLinux) return 'Linux';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isFuchsia) return 'Fuchsia';
    return 'Unknown';
  }
}
