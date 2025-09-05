import 'package:disk_space_2/disk_space_2.dart';
import 'package:flutter/material.dart';

class DiskSpaceView extends StatefulWidget {
  const DiskSpaceView({super.key});

  @override
  State<DiskSpaceView> createState() => _DiskSpaceViewState();
}

class _DiskSpaceViewState extends State<DiskSpaceView> {
  double? _total;
  double? _free;
  double? _used;
  String? _platformVersion;

  final _diskSpacePlugin = DiskSpace();

  @override
  void initState() {
    super.initState();
    _loadDiskInfo();
  }

  Future<void> _loadDiskInfo() async {
    double? total = await DiskSpace.getTotalDiskSpace;
    double? free = await DiskSpace.getFreeDiskSpace;
    double? used = total != null && free != null ? total - free : null;
    _platformVersion = await _diskSpacePlugin.getPlatformVersion();

    if (mounted) {
      setState(() {
        _total = total;
        _free = free;
        _used = used;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_total == null || _free == null) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(leading: Icon(Icons.adb), title: Text("运行平台"), subtitle: Text(_platformVersion ?? 'Unknown')),
        ListTile(
          leading: Icon(Icons.sd_storage),
          title: Text("总空间"),
          subtitle: Text(formatCapacityDescription(_total)),
        ),
        ListTile(leading: Icon(Icons.storage), title: Text("已使用"), subtitle: Text(formatCapacityDescription(_used))),
        ListTile(leading: Icon(Icons.memory), title: Text("剩余空间"), subtitle: Text(formatCapacityDescription(_free))),
      ],
    );
  }

  /// 将容量（MB 为单位）格式化为可读字符串
  String formatCapacityDescription(double? value) {
    if (value == null) {
      return "-- MB";
    }

    if (value < 1000) {
      return "${value.toStringAsFixed(2)} MB"; // 保留两位小数
    } else {
      // 转换为 GB
      double gb = value / 1000;
      return "${gb.toStringAsFixed(2)} GB";
    }
  }
}
