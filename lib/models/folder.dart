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
  List<Song>? songPaths; // 文件路径列表或歌曲 id

  @HiveField(3)
  DateTime? createdAt;

  //  必须是普通构造函数
  Folder(this.path);
}
