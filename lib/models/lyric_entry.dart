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

/// 一个时间戳对应的一组歌词（支持同一时间戳多语言/多行）
class LyricEntry {
  final Duration? timestamp;
  final List<String> lines;
  bool isActive;

  LyricEntry({
    required this.timestamp,
    required this.lines,
    this.isActive = false,
  });

  @override
  String toString() {
    return 'LyricEntry{timestamp: $timestamp, lines: $lines, isActive: $isActive}';
  }
}

