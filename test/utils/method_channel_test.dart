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

// import 'package:flutter/services.dart';
// import 'package:flutter_test/flutter_test.dart';
//
// const MethodChannel _channel = MethodChannel('disk_space');
//
// void main() async {
//   TestWidgetsFlutterBinding.ensureInitialized();
//   final space = await getDiskSpace();
//   print("总空间: ${space["total"]! ~/ (1024 * 1024 * 1024)} GB");
//   print("可用空间: ${space["free"]! ~/ (1024 * 1024 * 1024)} GB");
// }
//
// Future<Map<String, int>> getDiskSpace() async {
//   final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('getDiskSpace');
//   return {"total": result?["total"] as int, "free": result?["free"] as int};
// }
