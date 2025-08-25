import 'package:flutter/material.dart';

import 'config/app_config.dart';
import 'config/theme.dart';
import 'ui/pages/home_page.dart';

void main() {
  runApp(const AppEntry());
}

class AppEntry extends StatelessWidget {
  const AppEntry({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appTitle,
      theme: AppTheme.lightTheme,
      home: const MusicHomePage(),
    );
  }
}
