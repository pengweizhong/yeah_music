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

import 'dart:typed_data';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:hive/hive.dart';

part "song.g.dart";

@HiveType(typeId: 1)
class Song extends HiveObject {
  ///文件路径
  @HiveField(0)
  String path;

  /// 曲目标题, 如果为空，则用文件名替代
  @HiveField(1)
  String? title;

  /// 专辑名称
  @HiveField(2)
  String? album;

  /// 专辑/曲目发行年份
  @HiveField(3)
  DateTime? year;

  /// 曲目语言
  String? language;

  /// 曲目主唱
  /// 对于古典音乐，则是作曲家
  /// 对于流行音乐，通常是乐队或歌手
  @HiveField(4)
  String? artist;

  /// 曲目中包含但不被视为主唱的艺术家
  /// 例如，在“Dr. Dre - Still D.R.E. ft. Snoop Dogg”中，Snoop Dogg 是
  /// 表演者
  @HiveField(5)
  final List<String> performers = [];

  /// 专辑中曲目的顺序
  int? trackNumber;

  /// 专辑中曲目总数
  int? trackTotal;

  /// 曲目时长（毫秒，持久化到 Hive，供统计与列表展示）。
  @HiveField(10)
  int? durationMs;

  /// 曲目时长
  Duration? get duration {
    final ms = durationMs;
    if (ms == null || ms <= 0) return null;
    return Duration(milliseconds: ms);
  }

  set duration(Duration? value) {
    final ms = value?.inMilliseconds;
    durationMs = (ms == null || ms <= 0) ? null : ms;
  }

  /// 包含此曲目的唱片编号
  int? discNumber;

  /// 专辑的唱片编号
  int? totalDisc;

  /// 嵌入式歌词（仅内存；播放/展示时从音频文件读取，不入 Hive）。
  String? lyrics;

  /// 比特率（标签原始值，供音质分级与统计）。
  @HiveField(11)
  int? bitrate;

  /// 采样率（Hz，供音质分级与统计）。
  @HiveField(12)
  int? sampleRate;

  /// 歌曲中包含的图片
  // @HiveField(7)
  List<Picture>? pictures;

  /// 列表/播放展示用内嵌图字节（内存 + [SongLibraryMetadataHydrator] 缓存）。
  /// [HiveField(7)] 仅兼容旧版 hive 读出；[FolderHiveLightweight.saveFolder] 写入前会剥离，不落盘。
  @HiveField(7)
  Uint8List? imageBytes;

  ///歌曲创建时间
  @HiveField(8)
  DateTime? createDateTime;

  ///歌曲更新时间
  @HiveField(9)
  DateTime? updateDateTime;

  /// 仅内存：自建歌单解析时路径不在合并曲库且本机无该文件（占位行）；不入 Hive。
  bool playlistEntryMissingOnDevice = false;

  Song(this.path);

  @override
  String toString() {
    return 'Song{'
        'path: $path, '
        'title: $title, '
        'album: $album, '
        'year: $year, '
        'language: $language, '
        'artist: $artist, '
        'performers: $performers, '
        'trackNumber: $trackNumber, '
        'trackTotal: $trackTotal, '
        'duration: $duration, '
        'discNumber: $discNumber, '
        'totalDisc: $totalDisc, '
        'lyrics: $lyrics, '
        'bitrate: $bitrate, '
        'sampleRate: $sampleRate, '
        'createDateTime: $createDateTime, '
        'updateDateTime: $updateDateTime, '
        'picturesSize: ${pictures?.length}'
        '}';
  }
}
