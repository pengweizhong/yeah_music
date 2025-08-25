import 'package:flutter/material.dart';
import '../../models/song.dart';

class SongTile extends StatelessWidget {
  final Song song;
  final bool selected;
  final VoidCallback onTap;

  const SongTile({
    super.key,
    required this.song,
    this.selected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(song.title),
      selected: selected,
      onTap: onTap,
    );
  }
}
