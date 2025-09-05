import 'package:flutter/material.dart';

import '../models/song.dart';

class SongRepository extends ChangeNotifier {
  List<Song> songList = [];
}
