import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:yeah_music/l10n/app_localizations.dart';
import 'package:yeah_music/logging/app_log.dart';
import 'package:yeah_music/models/system_info.dart';
import 'package:yeah_music/utils/system_utils.dart';

class _DeviceLine {
  const _DeviceLine(this.key, this.value);
  final String key;
  final String value;
}

String _deviceLabel(AppLocalizations l10n, String key) {
  switch (key) {
    case 'deviceModel':
      return l10n.settingsSysinfoDeviceModel;
    case 'manufacturer':
      return l10n.settingsSysinfoManufacturer;
    case 'systemVersion':
      return l10n.settingsSysinfoOsVersion;
    case 'sdkVersion':
      return l10n.settingsSysinfoSdkVersion;
    case 'deviceName':
      return l10n.settingsSysinfoDeviceName;
    case 'hostName':
      return l10n.settingsSysinfoHostName;
    case 'kernelVersion':
      return l10n.settingsSysinfoKernelVersion;
    case 'distroVersion':
      return l10n.settingsSysinfoDistroLabel;
    case 'buildNumber':
      return l10n.settingsSysinfoBuildNumber;
    default:
      return key;
  }
}

class DiskSpaceView extends StatefulWidget {
  const DiskSpaceView({super.key});

  @override
  State<DiskSpaceView> createState() => _DiskSpaceViewState();
}

class _DiskSpaceViewState extends State<DiskSpaceView> {
  SystemInfo? systemInfo;
  final List<_DeviceLine> _deviceLines = [];
  bool _deviceFetchFailed = false;
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

    try {
      systemInfo = await SystemUtils.getSystemInfo();
    } catch (e) {
      appLog.e('加载系统/磁盘信息失败', error: e);
    }

    final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
    _deviceLines.clear();
    _deviceFetchFailed = false;

    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        _deviceLines.addAll([
          _DeviceLine('deviceModel', androidInfo.model),
          _DeviceLine('manufacturer', androidInfo.manufacturer),
          _DeviceLine(
            'systemVersion',
            'Android ${androidInfo.version.release}',
          ),
          _DeviceLine('sdkVersion', androidInfo.version.sdkInt.toString()),
        ]);
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        _deviceLines.addAll([
          _DeviceLine('deviceModel', iosInfo.model),
          _DeviceLine('deviceName', iosInfo.name),
          _DeviceLine(
            'systemVersion',
            '${iosInfo.systemName} ${iosInfo.systemVersion}',
          ),
        ]);
      } else if (Platform.isMacOS) {
        final macInfo = await deviceInfoPlugin.macOsInfo;
        _deviceLines.addAll([
          _DeviceLine('deviceModel', macInfo.model),
          _DeviceLine('hostName', macInfo.computerName),
          _DeviceLine('systemVersion', 'macOS ${macInfo.osRelease}'),
          _DeviceLine('kernelVersion', macInfo.kernelVersion),
        ]);
      } else if (Platform.isLinux) {
        final linuxInfo = await deviceInfoPlugin.linuxInfo;
        _deviceLines.addAll([
          _DeviceLine('deviceName', linuxInfo.name),
          _DeviceLine('distroVersion', linuxInfo.version ?? 'Unknown'),
          _DeviceLine('kernelVersion', linuxInfo.versionId ?? 'Unknown'),
        ]);
      } else if (Platform.isWindows) {
        final windowsInfo = await deviceInfoPlugin.windowsInfo;
        _deviceLines.addAll([
          _DeviceLine('deviceName', windowsInfo.computerName),
          _DeviceLine(
            'systemVersion',
            'Windows ${windowsInfo.majorVersion}.${windowsInfo.minorVersion}',
          ),
          _DeviceLine('buildNumber', windowsInfo.buildNumber.toString()),
        ]);
      }
    } catch (e) {
      appLog.e('获取设备信息失败', error: e);
      _deviceFetchFailed = true;
      _deviceLines.clear();
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              l10n.settingsSysinfoSectionDevice,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _buildInfoTile(
            Icons.phone_android,
            l10n.settingsSysinfoPlatformLabel,
            systemInfo?.platformName ?? 'Unknown',
          ),
          if (_deviceFetchFailed)
            _buildInfoTile(
              Icons.error_outline,
              l10n.settingsSysinfoError,
              l10n.settingsSysinfoFetchFailed,
            )
          else
            ..._deviceLines.map(
              (e) => _buildInfoTile(
                Icons.info_outline,
                _deviceLabel(l10n, e.key),
                e.value,
              ),
            ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              l10n.settingsSysinfoSectionStorage,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (systemInfo?.total != null && systemInfo!.total! > 0) ...[
            _buildInfoTile(
              Icons.sd_storage,
              l10n.settingsSysinfoTotalSpace,
              SystemUtils.formatCapacityDescription(systemInfo?.total),
            ),
            _buildInfoTile(
              Icons.storage,
              l10n.settingsSysinfoUsedSpace,
              SystemUtils.formatCapacityDescription(systemInfo?.used),
              subtitle: systemInfo?.total != null && systemInfo?.used != null
                  ? '${((systemInfo!.used! / systemInfo!.total!) * 100).toStringAsFixed(1)}%'
                  : null,
            ),
            _buildInfoTile(
              Icons.memory,
              l10n.settingsSysinfoFreeSpace,
              SystemUtils.formatCapacityDescription(systemInfo?.free),
              subtitle: systemInfo?.total != null && systemInfo?.free != null
                  ? '${((systemInfo!.free! / systemInfo!.total!) * 100).toStringAsFixed(1)}%'
                  : null,
            ),
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
                      backgroundColor: Colors.grey.withValues(alpha: 0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getStorageColor(systemInfo!.used! / systemInfo!.total!),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                l10n.settingsSysinfoStorageUnavailable,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(
    IconData icon,
    String title,
    String value, {
    String? subtitle,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white.withValues(alpha: 0.7), size: 20),
      title: Text(
        title,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.7),
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
                color: Colors.white.withValues(alpha: 0.5),
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
