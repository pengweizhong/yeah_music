import 'package:flutter/material.dart';
import 'package:yeah_music/pages/menu_page.dart';

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
      appBar: AppBar(title: Text("主页")),
      drawer: MenuPage(),
      body: Center(child: Text("这里暂时什么也不做")),
    );
  }
}
