import 'package:disk_space_2/disk_space_2.dart';
import 'package:flutter_test/flutter_test.dart';

void main() async {
  // 初始化 Flutter 测试环境
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FileUtils', () {
    test("获取磁盘空间", () async {
      double? freeDiskSpace = await DiskSpace.getFreeDiskSpace;
      print('Free disk space: $freeDiskSpace');

      double? totalDiskSpace = await DiskSpace.getTotalDiskSpace;
      print('Total disk space: $totalDiskSpace');
    });
  });
}
