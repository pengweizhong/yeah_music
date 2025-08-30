
import 'package:audio_metadata_reader/audio_metadata_reader.dart';

class Song {
  ///文件路径
  final String path;

  /// 曲目标题, 如果为空，则用文件名替代
  late String title;

  /// 专辑名称
  String? album;

  /// 专辑/曲目发行年份
  DateTime? year;

  /// 曲目语言
  String? language;

  /// 曲目主唱
  /// 对于古典音乐，则是作曲家
  /// 对于流行音乐，通常是乐队或歌手
  String? artist;

  /// 曲目中包含但不被视为主唱的艺术家
  /// 例如，在“Dr. Dre - Still D.R.E. ft. Snoop Dogg”中，Snoop Dogg 是
  /// 表演者
  final List<String> performers = [];

  /// 专辑中曲目的顺序
  int? trackNumber;

  /// 专辑中曲目总数
  int? trackTotal;

  /// 曲目时长
  Duration? duration;

  /// 包含此曲目的唱片编号
  int? discNumber;

  /// 专辑的唱片编号
  int? totalDisc;

  /// 曲目的歌词。可以是普通文本或歌词。
  String? lyrics;

  /// 比特率
  int? bitrate;

  /// 采样率
  int? sampleRate;

  /// 歌曲中包含的图片
  List<Picture>? pictures;

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
        'picturesSize: ${pictures?.length}'
        '}';
  }
}
