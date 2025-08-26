import 'dart:io';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import '../models/song.dart';

class SongRepository {
  /// 从文件夹加载歌曲列表
  Future<List<Song>> loadSongs(String folderPath) async {
    final dir = Directory(folderPath);
    if (!await dir.exists()) {
      throw Exception('文件夹不存在: $folderPath');
    }

    // 筛选支持的音频文件格式
    final files = dir.listSync().where(
          (f) =>
      f.path.endsWith(".mp3") ||
          f.path.endsWith(".flac") ||
          f.path.endsWith(".m4a") ||
          f.path.endsWith(".wav"),
    );

    List<Song> songs = [];
    for (var file in files) {
      try {
        // 使用 ffmpeg_kit_flutter_new 提取元数据
        final metadata = await _extractMetadata(file.path);
        songs.add(
          Song(
            path: file.path,
            title: metadata['title'] ?? file.uri.pathSegments.last,
            artist: metadata['artist']?.join(", ") ?? "未知歌手",
            album: metadata['album'] ?? "未知专辑",
            uri: file.uri,
            cover: metadata['albumArt'], // 需要额外处理封面图
            lyrics: null, // FFmpeg 默认不直接提取歌词
            year: metadata['year'],
          ),
        );
      } catch (e, st) {
        // 错误处理：添加默认值并记录错误
        songs.add(
          Song(
            path: file.path,
            title: file.uri.pathSegments.last,
            artist: "未知歌手",
            album: "未知专辑",
            uri: file.uri,
          ),
        );
        print("解析歌曲失败: ${file.path}\n$e\n$st");
      }
    }
    return songs;
  }

  /// 使用 ffmpeg_kit_flutter_new 提取元数据
  Future<Map<String, dynamic>> _extractMetadata(String filePath) async {
    try {
      // 执行 FFmpeg 命令提取元数据
      final session = await FFmpegKit.execute(
        '-i "$filePath" -f ffmetadata -',
      );

      // 检查命令执行结果
      final returnCode = await session.getReturnCode();
      if (!ReturnCode.isSuccess(returnCode)) {
        throw Exception('FFmpeg 命令执行失败: Return code $returnCode');
      }

      // 获取元数据输出
      final output = await session.getOutput();
      if (output == null) {
        throw Exception('无法获取元数据输出');
      }

      // 解析 ffmetadata 格式的输出
      final metadata = <String, dynamic>{};
      final lines = output.split('\n');
      for (var line in lines) {
        line = line.trim();
        if (line.startsWith('title=')) {
          metadata['title'] = line.substring(6);
        } else if (line.startsWith('artist=')) {
          metadata['artist'] = [line.substring(7)]; // 转换为列表以匹配原逻辑
        } else if (line.startsWith('album=')) {
          metadata['album'] = line.substring(6);
        } else if (line.startsWith('date=')) {
          metadata['year'] = line.substring(5);
        }
        // 封面图需要单独提取，详见下方说明
      }

      // 提取封面图（如果需要）
      final coverPath = await _extractAlbumArt(filePath);
      if (coverPath != null) {
        metadata['albumArt'] = File(coverPath).readAsBytesSync();
      }

      return metadata;
    } catch (e) {
      rethrow; // 抛出异常以便上层捕获
    }
  }

  /// 提取封面图（可选）
  Future<String?> _extractAlbumArt(String filePath) async {
    try {
      // 临时文件路径用于保存封面图
      final tempDir = Directory.systemTemp.path;
      final outputPath = '$tempDir/cover_${filePath.hashCode}.jpg';

      // 执行 FFmpeg 命令提取封面图
      final session = await FFmpegKit.execute(
        '-i "$filePath" -an -vcodec copy "$outputPath"',
      );

      // 检查命令执行结果
      final returnCode = await session.getReturnCode();
      if (ReturnCode.isSuccess(returnCode) && await File(outputPath).exists()) {
        return outputPath;
      }
      return null; // 没有封面图
    } catch (e) {
      print('提取封面图失败: $e');
      return null;
    }
  }
}