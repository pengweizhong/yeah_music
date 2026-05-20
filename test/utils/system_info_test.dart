// Copyright (c) 2025 Yeah Music
//
// This file is part of Yeah Music.
//
// Yeah Music is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Yeah Music is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.

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
