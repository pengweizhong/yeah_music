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

  static Future<bool> isEnabled() async {
    final cached = _enabledCache;
    if (cached != null) return cached;
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_enabledKey) ?? false;
    _enabledCache = enabled;
    return enabled;
  }

  static Future<void> setEnabled(bool enabled) async {
    _enabledCache = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
    if (enabled) {
      await append('diagnostic logging enabled');
    }
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
      await f.writeAsString(text, mode: FileMode.append, flush: false);
    } catch (_) {}
  }
}
