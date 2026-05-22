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

import 'package:path/path.dart' as p;
import 'package:yeah_music/models/song.dart';
import 'package:yeah_music/utils/song_audio_quality.dart';

/// 列表 / [SongSearchDelegate] 共用：按标题、歌手、专辑、文件名或音质档位筛选。
List<Song> filterSongsByListSearchQuery(List<Song> songs, String rawQuery) {
  final q = rawQuery.trim();
  if (q.isEmpty) return List<Song>.from(songs);
  return songs.where((s) => songMatchesListSearchQuery(s, q)).toList();
}

bool songMatchesListSearchQuery(Song song, String rawQuery) {
  final q = rawQuery.trim().toLowerCase();
  if (q.isEmpty) return true;
  if (_songMatchesTextFields(song, q)) return true;
  return songMatchesAudioQualitySearchQuery(song, q);
}

bool _songMatchesTextFields(Song song, String qLower) {
  final title = (song.title ?? '').toLowerCase();
  final artist = (song.artist ?? '').toLowerCase();
  final album = (song.album ?? '').toLowerCase();
  final fileName = p.basename(song.path).toLowerCase();
  return title.contains(qLower) ||
      artist.contains(qLower) ||
      album.contains(qLower) ||
      fileName.contains(qLower);
}

/// 关键词是否对应某一音质档位，且 [song] 经 [classifySongAudioQuality] 判定为该档。
bool songMatchesAudioQualitySearchQuery(Song song, String qLower) {
  final q = qLower.trim().toLowerCase();
  if (q.isEmpty) return false;

  final tier = classifySongAudioQuality(song);
  if (tier == null) return false;

  final code = tier.shortLabel.toLowerCase();
  if (code == q) return true;
  if (q.length >= 2 && code.startsWith(q)) return true;

  final parsed = parseAudioQualityTierSearchQuery(q);
  return parsed != null && parsed == tier;
}

/// 将搜索框整段关键词解析为音质档位（如 `sq`、`hr`、`无损`、`dsd`）。
SongAudioQualityTier? parseAudioQualityTierSearchQuery(String rawQuery) {
  final q = rawQuery.trim().toLowerCase();
  if (q.isEmpty) return null;

  for (final tier in kSongAudioQualityTiersLowToHigh) {
    final code = tier.shortLabel.toLowerCase();
    if (code == q) return tier;
    if (q.length >= 2 && code.startsWith(q)) return tier;
  }

  switch (q) {
    case '流畅':
    case '低音质':
      return SongAudioQualityTier.lq;
    case '标准':
    case '标清':
      return SongAudioQualityTier.std;
    case '高品质':
    case '高品':
      return SongAudioQualityTier.hq;
    case '无损':
    case 'lossless':
    case 'cd':
    case 'cd级':
    case 'flac':
      return SongAudioQualityTier.sq;
    case '高解析':
    case '高解析度':
    case 'hires':
    case 'hi-res':
    case 'hi res':
    case 'hifi':
    case 'hi-fi':
      return SongAudioQualityTier.hr;
    case 'dsd':
    case 'dff':
    case 'dsf':
    case '发烧':
    case '顶级':
      return SongAudioQualityTier.dsd;
    default:
      return null;
  }
}
