import 'package:flutter/material.dart';

import '../compments/menu_drawer.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: false,
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(title: Text("播放列表")),
      drawer: MenuDrawer(),
    );
  }
}
