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
    final bodyLen = _synchsafe31(
      fileBytes[offset + 6],
      fileBytes[offset + 7],
      fileBytes[offset + 8],
      fileBytes[offset + 9],
    );
    final tagTotal = 10 + bodyLen;
    if (tagTotal <= 10 || offset + tagTotal > fileBytes.length) {
      break;
    }
    offset += tagTotal;
  }
  return fileBytes.sublist(offset);
}

int _synchsafe31(int a, int b, int c, int d) =>
    ((a & 0x7f) << 21) | ((b & 0x7f) << 14) | ((c & 0x7f) << 7) | (d & 0x7f);
