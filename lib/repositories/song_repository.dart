import 'dart:io';

import 'package:file_picker/file_picker.dart';

import '../config/app_config.dart';
import '../models/song.dart';

class SongRepository {
  Future<List<Song>> pickFolder() async {
    final path = await FilePicker.platform.getDirectoryPath();
    if (path == null) return [];

    final dir = Directory(path);
    final files = dir.listSync().where((f) {
      // 遍历 AppConfig.supportedFormats 做检查
      return AppConfig.supportedFormats.any((ext) => f.path.endsWith(ext));
    }).toList();

    return files.map((f) => Song(f.path)).toList();
  }
}
