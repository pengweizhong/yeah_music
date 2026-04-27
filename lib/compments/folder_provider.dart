import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:yeah_music/compments/bookmark_service.dart';
import 'package:yeah_music/models/constants.dart';
import 'package:yeah_music/models/song.dart';
import 'package:yeah_music/utils/file_utils.dart';
import 'package:yeah_music/utils/hive_utils.dart';

import '../config/app_config.dart';
import '../models/folder.dart';

var log = Logger(printer: SimplePrinter());

class FolderProvider extends ChangeNotifier {
  //main 里调用了 ..init()，也不能保证 UI 构建时 _box 已经就绪。
  late Box<Folder>? _box;
  bool _initialized = false;

  List<Folder> get folders {
    if (_box == null || !_box!.isOpen) return [];
    return _box!.values.toList();
  }

  bool get initialized => _initialized;

  /// 初始化 Hive Box
  Future<void> init() async {
    if (_initialized && _box != null && _box!.isOpen) {
      return;
    }
    _box = await HiveUtils.openBox<Folder>(Constant.hiveFolderBox);
    _initialized = true;
    notifyListeners();
  }

  /// 添加文件夹 ,添加成功就返回Folder（优化版本，支持大量歌曲）
  Future<Folder?> addFolder(String folder) async {
    //检验文件夹是否已经存在
    if (await existFolder(_box!, folder)) {
      log.d("用户添加了重复的文件夹：$folder");
      return null;
    }
    String folderName = folder.split('/').last;
    final f = Folder(folder);
    f.name = folderName;
    f.createdAt = DateTime.now();
    
    try {
      await flushSongToFolder(f, false, save: false);
      await HiveUtils.add(_box!, f);
      notifyListeners();
      return f;
    } catch (e) {
      log.e("添加文件夹失败：$folder，错误：$e");
      // 如果添加失败，不保存到数据库
      rethrow;
    }
  }

  /// 删除文件夹
  Future<void> deleteFolder(Folder folder) async {
    await folder.delete();
    notifyListeners();
  }

  /// 修改文件夹名称
  Future<void> renameFolder(Folder folder, String newName) async {
    folder.name = newName;
    await folder.save();
    notifyListeners();
  }

  /// 添加歌曲到文件夹（优化版本，支持大量歌曲）
  Future<void> flushSongToFolder(Folder folder, bool listen, {bool save = true}) async {
    String folderPath = folder.path;
    if (Platform.isMacOS) {
      // macOS需要先恢复权限，如果失败则记录错误
      try {
        final restored = await BookmarkService.restoreBookmark(folderPath);
        if (restored == null) {
          log.w("无法恢复macOS权限，路径：$folderPath");
          // 即使权限恢复失败，也尝试访问，可能会触发系统权限请求
        }
      } catch (e) {
        log.e("恢复macOS权限时出错：$e");
      }
    } else if (Platform.isAndroid) {
      // 筛选支持的音频文件格式
      // 获取当前目录及子目录下所有文件
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      int sdkInt = androidInfo.version.sdkInt;
      if (sdkInt >= 33) {
        // Android 13+
        await [Permission.audio, Permission.photos, Permission.videos].request();
      } else {
        // Android 12 及以下
        await Permission.storage.request().isGranted;
      }
    }
    //加载歌曲
    try {
      final dir = Directory(folderPath);
      // 先检查目录是否存在和可访问
      if (!await dir.exists()) {
        log.e("文件夹不存在：$folderPath");
        folder.songList = [];
        if (save) await folder.save();
        if (listen) notifyListeners();
        return;
      }
      
      // 使用异步方式列出文件，避免阻塞UI
      final songFiles = await _listAudioFilesAsync(dir);
      log.d("文件夹${dir.path}下找到了${songFiles.length}首歌曲");
      
      // 批量处理歌曲，避免一次性加载过多导致内存溢出
      List<Song> songlist = [];
      const batchSize = 50; // 每批处理50首歌曲
      
      for (int i = 0; i < songFiles.length; i += batchSize) {
        final end = (i + batchSize < songFiles.length) ? i + batchSize : songFiles.length;
        final batch = songFiles.sublist(i, end);
        
        // 批量加载元数据
        final batchSongs = await _loadSongBatch(batch);
        songlist.addAll(batchSongs);
        
        // 每处理一批后，让出控制权，避免阻塞UI
        await Future.delayed(Duration.zero);
        
        // 可选：每批处理后通知进度（如果需要显示进度条）
        log.d("已加载 ${songlist.length}/${songFiles.length} 首歌曲");
      }
      
      folder.songList = songlist;
      if (save) {
        await folder.save();
      }
      if (listen) {
        notifyListeners();
      }
    } catch (e) {
      log.e("访问文件夹时出错：$folderPath，错误：$e");
      // 权限错误时，清空歌曲列表，避免显示错误数据
      folder.songList = [];
      if (save) {
        try {
          await folder.save();
        } catch (_) {}
      }
      if (listen) {
        notifyListeners();
      }
      rethrow; // 重新抛出异常，让调用者知道出错了
    }
  }

  /// 异步列出音频文件
  Future<List<File>> _listAudioFilesAsync(Directory dir) async {
    final List<File> audioFiles = [];
    
    try {
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          final path = entity.path;
          if (AppConfig.supportedFormats.any((format) => path.endsWith(format))) {
            audioFiles.add(entity);
          }
        }
        
        // 每处理100个文件，让出控制权
        if (audioFiles.length % 100 == 0) {
          await Future.delayed(Duration.zero);
        }
      }
    } catch (e) {
      log.e("列出文件时出错：$e");
    }
    
    return audioFiles;
  }

  /// 批量加载歌曲元数据
  Future<List<Song>> _loadSongBatch(List<File> files) async {
    final List<Song> songs = [];
    
    for (var file in files) {
      try {
        Song song = Song(file.path);
        FileUtils.loadSongMeta(song);
        songs.add(song);
      } catch (e) {
        log.w("加载歌曲元数据失败：${file.path}，错误：$e");
        // 即使元数据加载失败，也添加基本信息
        try {
          Song song = Song(file.path);
          song.title = file.path.split('/').last.replaceAll(RegExp(r'\.\w+$'), '');
          songs.add(song);
        } catch (_) {
          // 完全失败，跳过这首歌
        }
      }
    }
    
    return songs;
  }

  ///文件夹是否已经存在
  ///存在 true，否则 false
  Future<bool> existFolder(Box box, String folder) async {
    return box.values.any((f) => f.path == folder);
  }
}
