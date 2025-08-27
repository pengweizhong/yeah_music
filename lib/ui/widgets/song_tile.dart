import 'package:flutter/material.dart';

class SongTitle extends StatelessWidget {
  final String title;

  const SongTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: const TextStyle(fontWeight: FontWeight.bold));
  }
}
