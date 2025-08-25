import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../models/song.dart';

class SongRepository {
  Future<List<Song>> pickFolder() async {
    final path = await FilePicker.platform.getDirectoryPath();
    if (path == null) return [];
    final dir = Directory(path);
    final files = dir
        .listSync()
        .where((f) =>
    f.path.endsWith(".mp3") ||
        f.path.endsWith(".flac") ||
        f.path.endsWith(".m4a") ||
        f.path.endsWith(".wav"))
        .toList();
    return files.map((f) => Song(f.path)).toList();
  }
}
