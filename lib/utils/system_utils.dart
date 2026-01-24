import 'dart:io';

import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

import '../models/system_info.dart';

const MethodChannel _channel = MethodChannel('disk_space');
var log = Logger(printer: SimplePrinter());

class SystemUtils {
  static Future<SystemInfo> getSystemInfo() async {
    SystemInfo systemInfo = SystemInfo();
    
    if (Platform.isAndroid) {
      try {
        // Android 使用 StatFs 获取存储信息
        final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('getDiskSpace');
        if (result != null) {
          systemInfo.total = (result["total"] as num).toDouble() / (1024 * 1024);
          systemInfo.free = (result["free"] as num).toDouble() / (1024 * 1024);
          systemInfo.used = systemInfo.total! - systemInfo.free!;
        }
        systemInfo.platformName = "Android";
      } catch (e) {
        log.e("获取Android磁盘空间失败：$e");
        // 如果 MethodChannel 失败，尝试使用命令行
        try {
          ProcessResult result = await Process.run('df', ['-m', '/data']);
          if (result.exitCode == 0) {
            List<String> lines = (result.stdout as String).split('\n');
            if (lines.length >= 2) {
              final parts = lines[1].split(RegExp(r'\s+'));
              if (parts.length >= 4) {
                systemInfo.total = double.tryParse(parts[1]) ?? 0;
                systemInfo.used = double.tryParse(parts[2]) ?? 0;
                systemInfo.free = double.tryParse(parts[3]) ?? 0;
              }
            }
          }
        } catch (e2) {
          log.e("使用df命令获取Android磁盘空间也失败：$e2");
        }
        systemInfo.platformName = "Android";
      }
      return systemInfo;
    } else if (Platform.isIOS) {
      try {
        final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('getDiskSpace');
        if (result != null) {
          systemInfo.total = (result["total"] as num).toDouble() / (1024 * 1024);
          systemInfo.free = (result["free"] as num).toDouble() / (1024 * 1024);
          systemInfo.used = systemInfo.total! - systemInfo.free!;
        }
        systemInfo.platformName = "iOS";
      } catch (e) {
        log.e("获取iOS磁盘空间失败：$e");
        systemInfo.platformName = "iOS";
      }
      return systemInfo;
    } else if (Platform.isMacOS) {
      try {
        final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('getDiskSpace');
        if (result != null) {
          systemInfo.total = (result["total"] as num).toDouble() / (1000 * 1000);
          systemInfo.free = (result["free"] as num).toDouble() / (1000 * 1000);
          systemInfo.used = systemInfo.total! - systemInfo.free!;
        }
        systemInfo.platformName = "macOS";
      } catch (e) {
        log.e("获取macOS磁盘空间失败：$e");
        systemInfo.platformName = "macOS";
      }
      return systemInfo;
    } else if (Platform.isLinux) {
      try {
        ProcessResult result = await Process.run('df', ['-m', '/']);
        if (result.exitCode == 0) {
          List<String> lines = (result.stdout as String).split('\n');
          if (lines.length >= 2) {
            final parts = lines[1].split(RegExp(r'\s+'));
            if (parts.length >= 4) {
              systemInfo.total = double.tryParse(parts[1]) ?? 0;
              systemInfo.used = double.tryParse(parts[2]) ?? 0;
              systemInfo.free = double.tryParse(parts[3]) ?? 0;
            }
          }
        }
        systemInfo.platformName = "Linux";
      } catch (e) {
        log.e("获取Linux磁盘空间失败：$e");
        systemInfo.platformName = "Linux";
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
              }
            }
          }
        }
        systemInfo.platformName = "Windows";
      } catch (e) {
        log.e("获取Windows磁盘空间失败：$e");
        systemInfo.platformName = "Windows";
      }
      return systemInfo;
    }

    // 未知平台
    systemInfo.platformName = "Unknown";
    return systemInfo;
  }

  /// 将容量（MB 为单位）格式化为可读字符串
  static String formatCapacityDescription(double? value) {
    if (value == null || value == 0) {
      return "未知";
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
