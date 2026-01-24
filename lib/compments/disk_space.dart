import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:yeah_music/models/system_info.dart';
import 'package:yeah_music/utils/system_utils.dart';

class DiskSpaceView extends StatefulWidget {
  const DiskSpaceView({super.key});

  @override
  State<DiskSpaceView> createState() => _DiskSpaceViewState();
}

class _DiskSpaceViewState extends State<DiskSpaceView> {
  SystemInfo? systemInfo;
  Map<String, String> deviceInfo = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSystemInfo();
  }

  Future<void> _loadSystemInfo() async {
    setState(() {
      isLoading = true;
    });

    // 加载磁盘信息
    try {
      systemInfo = await SystemUtils.getSystemInfo();
    } catch (e) {
      print("加载系统信息失败: $e");
    }
    
    // 加载设备信息
    final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
    
    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        deviceInfo = {
          '设备型号': androidInfo.model,
          '制造商': androidInfo.manufacturer,
          '系统版本': 'Android ${androidInfo.version.release}',
          'SDK版本': androidInfo.version.sdkInt.toString(),
        };
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        deviceInfo = {
          '设备型号': iosInfo.model,
          '设备名称': iosInfo.name,
          '系统版本': '${iosInfo.systemName} ${iosInfo.systemVersion}',
        };
      } else if (Platform.isMacOS) {
        final macInfo = await deviceInfoPlugin.macOsInfo;
        deviceInfo = {
          '设备型号': macInfo.model,
          '主机名': macInfo.computerName,
          '系统版本': 'macOS ${macInfo.osRelease}',
          '内核版本': macInfo.kernelVersion,
        };
      } else if (Platform.isLinux) {
        final linuxInfo = await deviceInfoPlugin.linuxInfo;
        deviceInfo = {
          '设备名称': linuxInfo.name,
          '版本': linuxInfo.version ?? 'Unknown',
          '内核版本': linuxInfo.versionId ?? 'Unknown',
        };
      } else if (Platform.isWindows) {
        final windowsInfo = await deviceInfoPlugin.windowsInfo;
        deviceInfo = {
          '设备名称': windowsInfo.computerName,
          '系统版本': 'Windows ${windowsInfo.majorVersion}.${windowsInfo.minorVersion}',
          '构建号': windowsInfo.buildNumber.toString(),
        };
      }
    } catch (e) {
      print("获取设备信息失败: $e");
      deviceInfo = {'错误': '无法获取设备信息'};
    }
    
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 设备信息标题
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              "设备信息",
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // 平台信息
          _buildInfoTile(
            Icons.phone_android,
            "运行平台",
            systemInfo?.platformName ?? 'Unknown',
          ),
          
          // 设备详细信息
          if (deviceInfo.isNotEmpty)
            ...deviceInfo.entries.map((entry) => _buildInfoTile(
              Icons.info_outline,
              entry.key,
              entry.value,
            )),
          
          const SizedBox(height: 8),
          
          // 存储信息标题
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              "存储空间",
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // 检查是否有存储信息
          if (systemInfo?.total != null && systemInfo!.total! > 0) ...[
            // 总空间
            _buildInfoTile(
              Icons.sd_storage,
              "总空间",
              SystemUtils.formatCapacityDescription(systemInfo?.total),
            ),
            
            // 已使用
            _buildInfoTile(
              Icons.storage,
              "已使用",
              SystemUtils.formatCapacityDescription(systemInfo?.used),
              subtitle: systemInfo?.total != null && systemInfo?.used != null
                  ? "${((systemInfo!.used! / systemInfo!.total!) * 100).toStringAsFixed(1)}%"
                  : null,
            ),
            
            // 剩余空间
            _buildInfoTile(
              Icons.memory,
              "剩余空间",
              SystemUtils.formatCapacityDescription(systemInfo?.free),
              subtitle: systemInfo?.total != null && systemInfo?.free != null
                  ? "${((systemInfo!.free! / systemInfo!.total!) * 100).toStringAsFixed(1)}%"
                  : null,
            ),
            
            // 存储使用进度条
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: systemInfo!.used! / systemInfo!.total!,
                      minHeight: 8,
                      backgroundColor: Colors.grey.withOpacity(0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getStorageColor(systemInfo!.used! / systemInfo!.total!),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // 没有存储信息时显示提示
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                "存储信息暂时无法获取",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String value, {String? subtitle}) {
    return ListTile(
      leading: Icon(icon, color: Colors.white.withOpacity(0.7), size: 20),
      title: Text(
        title,
        style: TextStyle(
          color: Colors.white.withOpacity(0.7),
          fontSize: 13,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
        ],
      ),
      dense: true,
      visualDensity: VisualDensity.compact,
    );
  }

  Color _getStorageColor(double usage) {
    if (usage > 0.9) return Colors.red;
    if (usage > 0.7) return Colors.orange;
    return Colors.green;
  }
}
