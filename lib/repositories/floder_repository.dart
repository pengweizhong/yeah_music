import 'package:flutter/material.dart';

import '../models/song.dart';

class FolderRepository extends StatelessWidget {
  List<Song> songList = [];

  FolderRepository({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(title: Text("文件夹")),
    );
  }
}
