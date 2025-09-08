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

  @override
  void initState() {
    super.initState();
    _loadDiskInfo();
  }

  Future<void> _loadDiskInfo() async {
    systemInfo = await SystemUtils.getSystemInfo();
    if (mounted) {
      setState(() {
        systemInfo;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (systemInfo == null || systemInfo?.total == null || systemInfo?.free == null) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: Icon(Icons.adb),
          title: Text("运行平台"),
          subtitle: Text(systemInfo?.platformName ?? 'Unknown'),
        ),
        ListTile(
          leading: Icon(Icons.sd_storage),
          title: Text("总空间"),
          subtitle: Text(
            SystemUtils.formatCapacityDescription(systemInfo?.total),
          ),
        ),
        ListTile(
          leading: Icon(Icons.storage),
          title: Text("已使用"),
          subtitle: Text(
            SystemUtils.formatCapacityDescription(systemInfo?.used),
          ),
        ),
        ListTile(
          leading: Icon(Icons.memory),
          title: Text("剩余空间"),
          subtitle: Text(
            SystemUtils.formatCapacityDescription(systemInfo?.free),
          ),
        ),
      ],
    );
  }
}
