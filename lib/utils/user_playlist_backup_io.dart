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

import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:yeah_music/compments/user_playlist_provider.dart';

String safePlaylistBackupFileName(String s) {
  return s.replaceAll(RegExp(r'[<>:"/\\|?*\n\r]'), '_').trim().replaceAll(RegExp(r'\s+'), ' ');
}

String stampForBackupFileName() {
  return DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
}

String suggestedAllPlaylistsFileName() {
  return 'yeah_music_playlists_${stampForBackupFileName()}.json';
}

String suggestedSubsetPlaylistsFileName(UserPlaylistProvider user, Set<String> selectedIds) {
  final stamp = stampForBackupFileName();
  if (selectedIds.length == 1) {
    for (final p in user.playlists) {
      if (p.id == selectedIds.first) {
        return 'yeah_music_${safePlaylistBackupFileName(p.name)}_$stamp.json';
      }
    }
    return 'yeah_music_playlist_1_$stamp.json';
  }
  return 'yeah_music_playlists_${selectedIds.length}个_$stamp.json';
}

String suggestedLibraryAllSongsExportFileName(String localizedTitle) {
  return 'yeah_music_${safePlaylistBackupFileName(localizedTitle)}_${stampForBackupFileName()}.json';
}

/// 将 JSON 写入用户选择的文件；返回路径，取消或失败时可能为 `null`。
Future<String?> pickSaveUserPlaylistJson({
  required String jsonStr,
  required String dialogTitle,
  required String fileName,
}) async {
  return FilePicker.platform.saveFile(
    dialogTitle: dialogTitle,
    fileName: fileName,
    type: FileType.custom,
    allowedExtensions: const ['json'],
    bytes: Uint8List.fromList(utf8.encode(jsonStr)),
  );
}
