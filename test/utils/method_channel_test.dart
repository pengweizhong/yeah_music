import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const MethodChannel _channel = MethodChannel('disk_space');

void main() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final space = await getDiskSpace();
  print("总空间: ${space["total"]! ~/ (1024 * 1024 * 1024)} GB");
  print("可用空间: ${space["free"]! ~/ (1024 * 1024 * 1024)} GB");
}

Future<Map<String, int>> getDiskSpace() async {
  final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('getDiskSpace');
  return {"total": result?["total"] as int, "free": result?["free"] as int};
}
