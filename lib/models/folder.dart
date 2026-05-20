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

import 'package:hive/hive.dart';
import 'package:yeah_music/models/song.dart';

part "folder.g.dart";

@HiveType(typeId: 0)
class Folder extends HiveObject {
  @HiveField(0)
  String? name;
  @HiveField(1)
  final String path;

  @HiveField(2)
  List<Song>? songList; // 文件路径列表或歌曲 id

  @HiveField(3)
  DateTime? createdAt;

  //  必须是普通构造函数
  Folder(this.path) : songList = [];
}
