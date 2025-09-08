import 'dart:io';

import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

import '../models/system_info.dart';

const MethodChannel _channel = MethodChannel('disk_space');
var log = Logger(printer: SimplePrinter());

class SystemUtils {
  static Future<SystemInfo> getSystemInfo() async {
    SystemInfo systemInfo = SystemInfo();
    if (Platform.isMacOS) {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'getDiskSpace',
      );
      systemInfo.total = (result?["total"] as int).toDouble() / (1000 * 1000);
      systemInfo.free = (result?["free"] as int).toDouble() / (1000 * 1000);
      systemInfo.platformName = "macOS";
      systemInfo.used = systemInfo.total! - systemInfo.free!;
      return systemInfo;
    } else if (Platform.isLinux) {
      try {
        ProcessResult result = await Process.run('df', ['-m', '/']);
        if (result.exitCode == 0) {
          List<String> lines = (result.stdout as String).split('\n');
          if (lines.length >= 2) {
            final parts = lines[1].split(RegExp(r'\s+'));
            final total = double.parse(parts[1]);
            final used = double.parse(parts[2]);
            final free = double.parse(parts[3]);
            systemInfo.total = total;
            systemInfo.free = free;
            systemInfo.used = used;
            systemInfo.platformName = "Linux";
          }
        }
      } catch (e) {
        log.e("获取Linux磁盘空间失败：$e");
      }
      return systemInfo;
    } else if (Platform.isWindows) {
      try {
        ProcessResult result = await Process.run('wmic', [
          'logicaldisk',
          'get',
          'size,freespace,caption',
        ], runInShell: true);
        if (result.exitCode == 0) {
          List<String> lines = (result.stdout as String).split('\n');
          // 取 C: 盘为示例
          for (var line in lines) {
            if (line.trim().startsWith('C:')) {
              final parts = line.trim().split(RegExp(r'\s+'));
              if (parts.length >= 3) {
                final free = double.parse(parts[1]) / (1024 * 1024);
                final total = double.parse(parts[2]) / (1024 * 1024);
                final used = total - free;
                systemInfo.total = total;
                systemInfo.free = free;
                systemInfo.used = used;
                systemInfo.platformName = "Windows";
              }
            }
          }
        }
      } catch (e) {
        log.e("获取Windows磁盘空间失败：$e");
      }
    }

    return systemInfo;
  }

  /// 将容量（MB 为单位）格式化为可读字符串
  static String formatCapacityDescription(double? value) {
    if (value == null) {
      return "-- MB";
    }

    if (value < 1024) {
      return "${value.toStringAsFixed(2)} MB"; // 保留两位小数
    } else {
      // 转换为 GB
      double gb = value / 1024;
      return "${gb.toStringAsFixed(2)} GB";
    }
  }
}
