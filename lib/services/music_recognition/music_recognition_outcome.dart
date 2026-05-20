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

/// 统一识曲结果（各后端映射到此结构，供 UI / 历史写入）。
class MusicRecognitionOutcome {
  const MusicRecognitionOutcome({
    required this.rawStatus,
    this.title,
    this.artist,
    this.album,
    this.releaseDate,
    this.appleMusicUrl,
    this.spotifyUrl,
    this.errorMessage,
  });

  /// `success`：请求成功（可能无标题即无匹配）；`error`：调用或协议错误。
  final String rawStatus;
  final String? title;
  final String? artist;
  final String? album;
  final String? releaseDate;
  final String? appleMusicUrl;
  final String? spotifyUrl;
  final String? errorMessage;

  bool get hasMatch => title != null && title!.trim().isNotEmpty;

  bool get isSuccess => rawStatus == 'success' && hasMatch;

  bool get isNoMatch => rawStatus == 'success' && !hasMatch;
}
