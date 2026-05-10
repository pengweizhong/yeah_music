import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DiagnosticLogStore {
  DiagnosticLogStore._();

  static const _enabledKey = 'diagnostic_log_enabled_v1';
  static const _fileName = 'yeah_music_diagnostic.log';
  static const _maxBytes = 1024 * 1024;
  static const _keepBytes = 512 * 1024;

  static bool? _enabledCache;
  static Future<File>? _fileFuture;

  /// 从 SharedPreferences 重新读取开关并刷新 [_enabledCache]（诊断页、启动同步应使用此方法，
  /// 避免仅用内存缓存导致重启后开关显示错误）。
  static Future<bool> loadEnabledFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      await prefs.reload();
    } catch (_) {}
    final enabled = prefs.getBool(_enabledKey) ?? false;
    _enabledCache = enabled;
    return enabled;
  }

  static Future<bool> isEnabled() async {
    final cached = _enabledCache;
    if (cached != null) return cached;
    return loadEnabledFromPrefs();
  }

  /// 写入持久化后再更新内存缓存并追加首条日志；失败时回滚缓存并返回 false。
  static Future<bool> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    final ok = await prefs.setBool(_enabledKey, enabled);
    if (!ok) {
      _enabledCache = prefs.getBool(_enabledKey) ?? false;
      return false;
    }
    _enabledCache = enabled;
    if (enabled) {
      await append('diagnostic logging enabled');
    }
    return true;
  }

  static Future<File> file() {
    return _fileFuture ??= _resolveFile();
  }

  static Future<File> _resolveFile() async {
    final dir = await getApplicationSupportDirectory();
    return File(p.join(dir.path, _fileName));
  }

  static Future<String> read() async {
    try {
      final f = await file();
      if (!await f.exists()) return '';
      return f.readAsString();
    } catch (_) {
      return '';
    }
  }

  static Future<void> clear() async {
    try {
      final f = await file();
      if (await f.exists()) {
        await f.delete();
      }
    } catch (_) {}
  }

  static Future<void> append(String message) async {
    if (!await isEnabled()) return;
    await _appendRaw('${DateTime.now().toIso8601String()} $message\n');
  }

  static Future<void> appendLines(List<String> lines) async {
    if (lines.isEmpty || !await isEnabled()) return;
    final ts = DateTime.now().toIso8601String();
    await _appendRaw(lines.map((line) => '$ts $line\n').join());
  }

  static Future<void> _appendRaw(String text) async {
    try {
      final f = await file();
      await f.parent.create(recursive: true);
      if (await f.exists() && await f.length() > _maxBytes) {
        final old = await f.readAsString();
        await f.writeAsString(
          old.length > _keepBytes
              ? old.substring(old.length - _keepBytes)
              : old,
        );
      }
      await f.writeAsString(text, mode: FileMode.append, flush: true);
    } catch (_) {}
  }
}
