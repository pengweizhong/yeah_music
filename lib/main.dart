import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

var log = Logger(printer: SimplePrinter());

void main() {
  log.i('应用启动成功');
  runApp(const YeahMusicApp());
}

class YeahMusicApp extends StatelessWidget {
  const YeahMusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp();
  }
}
