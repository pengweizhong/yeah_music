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

/// MP3：剔除开头的 ID3v2 标签块（可能有多段），便于在前面重写单个 ID3 标签区，
/// 避免 [旧 ID3 | 音频…] 再被写成 [新 ID3 | 旧 ID3 | 音频…]。
Uint8List stripLeadingId3v2Blocks(Uint8List fileBytes) {
  var offset = 0;
  while (offset + 10 <= fileBytes.length) {
    if (fileBytes[offset] != 0x49 ||
        fileBytes[offset + 1] != 0x44 ||
        fileBytes[offset + 2] != 0x33) {
      break;
    }
    final flags = fileBytes[offset + 5];
    final bodyLen = _synchsafe31(
      fileBytes[offset + 6],
      fileBytes[offset + 7],
      fileBytes[offset + 8],
      fileBytes[offset + 9],
    );
    var tagTotal = 10 + bodyLen;
    // ID3v2.4 footer：标签体后还有 10 字节 "3DI" 尾标，剥离时须一并去掉。
    if ((flags & 0x10) != 0) {
      tagTotal += 10;
    }
    if (tagTotal <= 10 || offset + tagTotal > fileBytes.length) {
      break;
    }
    offset += tagTotal;
  }
  return fileBytes.sublist(offset);
}

/// 去掉文件末尾 128 字节 ID3v1（`TAG`），避免重写 ID3v2 后尾部残留旧标签。
Uint8List stripTrailingId3v1(Uint8List fileBytes) {
  if (fileBytes.length < 128) return fileBytes;
  final start = fileBytes.length - 128;
  if (fileBytes[start] == 0x54 &&
      fileBytes[start + 1] == 0x41 &&
      fileBytes[start + 2] == 0x47) {
    return fileBytes.sublist(0, start);
  }
  return fileBytes;
}

int _synchsafe31(int a, int b, int c, int d) =>
    ((a & 0x7f) << 21) | ((b & 0x7f) << 14) | ((c & 0x7f) << 7) | (d & 0x7f);
