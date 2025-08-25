class Song {
  final String path;
  final String title;

  Song(this.path) : title = path.split('/').last;
}
