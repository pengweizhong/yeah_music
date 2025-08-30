import 'dart:io';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:yeah_music/models/song.dart' hide readMetadata;

class SongUtils {
  static void loadMeta(Song song) {
    final metadata = readMetadata(File(song.path), getImage: true);
    song.album = metadata.album;
    song.artist = metadata.artist;
    song.title = metadata.title ?? song.path.split("/").last;
    song.duration = metadata.duration;
    song.year = metadata.year;
    song.trackNumber = metadata.trackNumber;
    song.discNumber = metadata.discNumber;
    song.lyrics = metadata.lyrics;
    song.sampleRate = metadata.sampleRate;
    song.bitrate = metadata.bitrate;
    song.pictures = metadata.pictures;
  }
}
