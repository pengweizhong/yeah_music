import 'dart:io';

import 'package:audio_metadata_reader/audio_metadata_reader.dart'
    show CommonMetadataSetters, MetadataParserException, readAllMetadata;
import 'package:yeah_music/third_party/audio_metadata_reader/write_metadata_with_lyrics.dart';

/// 使用 [audio_metadata_reader] 将常见字段写回音频文件内嵌标签。
/// MP3 / FLAC 会通过补丁写入 USLT / Vorbis LYRICS，便于再次读取歌词。
/// 支持格式以库为准（通常为 MP3 / FLAC / M4A 等）；不支持时会抛出 [MetadataParserException]。
Future<void> writeEmbeddedTagsForPath({
  required String path,
  required String title,
  required String? artist,
  required String? album,
  required DateTime? year,
  required int? trackNumber,
  required int? trackTotal,
  required int? discNumber,
  required int? totalDisc,
  required String? lyrics,
}) async {
  final file = File(path.trim());
  if (!await file.exists()) {
    throw FileSystemException('file not found', path);
  }

  final meta = readAllMetadata(file);
  final nt = title.trim();
  meta.setTitle(nt.isEmpty ? null : nt);
  meta.setArtist(_trimOrNull(artist));
  meta.setAlbum(_trimOrNull(album));
  meta.setYear(year);
  meta.setTrackNumber(trackNumber);
  meta.setTrackTotal(trackTotal);
  meta.setCD(discNumber, totalDisc);
  meta.setLyrics(_trimOrNull(lyrics));
  writeMetadataWithLyricsFix(file, meta);
}

String? _trimOrNull(String? s) {
  if (s == null) return null;
  final t = s.trim();
  return t.isEmpty ? null : t;
}

bool isEmbeddedMetadataWriteFailure(Object e) {
  return e is MetadataParserException || e is FileSystemException;
}
