// import 'package:system_info2/system_info2.dart';
//
// const int megaByte = 1024 * 1024;
//
// void main() {
//   print(
//     '总物理内存   '
//     ': ${formatCapacityDescription(SysInfo.getTotalPhysicalMemory())}',
//   );
//   print(
//     '可用物理内存    '
//     ': ${formatCapacityDescription(SysInfo.getFreePhysicalMemory())}',
//   );
//   print(
//     '总虚拟内存    '
//     ': ${formatCapacityDescription(SysInfo.getTotalVirtualMemory())}',
//   );
//   print(
//     '可用虚拟内存     '
//     ': ${formatCapacityDescription(SysInfo.getFreeVirtualMemory())}',
//   );
//   print(
//     '虚拟内存大小     '
//     ': ${formatCapacityDescription(SysInfo.getVirtualMemorySize())}',
//   );
// }
//
// /// 将容量（MB 为单位）格式化为可读字符串
// String formatCapacityDescription(int? value) {
//   if (value == null) {
//     return "-- MB";
//   }
//   if (value < megaByte) {
//     return "${(value / megaByte).toStringAsFixed(2)} MB";
//   }
//   // 转换为 GB
//   double gb = value / megaByte / 1024;
//   return "${gb.toStringAsFixed(2)} GB";
// }
