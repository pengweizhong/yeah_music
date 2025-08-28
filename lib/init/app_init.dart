import 'dart:ffi' as ffi;
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:logger/logger.dart';

var log = Logger(printer: SimplePrinter());

class AppInit {
  ///初始化JustAudio 音频播放插件
  void initJustAudio() {
    if (Platform.isLinux) {
      log.d("初始化 Linux setlocale C");
      // 强制设置 locale
      ffi.DynamicLibrary.process();
      // 仅在 Linux 桌面需要
      // 很多 Linux 系统（尤其是中文环境，LANG=zh_CN.UTF-8 之类）会把小数点当作逗号 ，而 FFmpeg 只认 .
      try {
        ffi.DynamicLibrary.open("libc.so.6").lookupFunction<
          ffi.Pointer<ffi.Int8> Function(ffi.Int32, ffi.Pointer<ffi.Int8>),
          ffi.Pointer<ffi.Int8> Function(int, ffi.Pointer<ffi.Int8>)
        >("setlocale")(6, "C".toNativeUtf8().cast()); // 6 = LC_NUMERIC
      } catch (_) {}
    }
    log.d("初始化AudioPlayer");
    //初始化AudioPlayer
    JustAudioMediaKit.ensureInitialized(
      linux: true,
      // default: true  - dependency: media_kit_libs_linux
      windows: true,
      // default: true  - dependency: media_kit_libs_windows_audio
      android: true,
      // default: false - dependency: media_kit_libs_android_audio
      iOS: true,
      // default: false - dependency: media_kit_libs_ios_audio
      macOS: true, // default: false - dependency: media_kit_libs_macos_audio
    );
  }
}
