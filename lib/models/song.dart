class Song {
  final String path; // 文件路径
  // final String filename; //文件名
  final String title; //歌曲标题

  Song(this.path, this.title);

  @override
  String toString() {
    return 'Song{path: $path, title: $title}';
  }
}
