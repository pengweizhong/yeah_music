// Copyright (c) 2025 Yeah Music
//
// This file is part of Yeah Music.
//
// Yeah Music is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Yeah Music is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yeah_music/compments/theme_config_provider.dart';
import 'package:yeah_music/themes/gradient_ui_colors.dart';
import 'package:yeah_music/themes/platform_typography.dart';

/// 设置子页统一外壳：渐变背景 + 平台 [Theme] + [DefaultTextStyle]。
class SettingPageScaffold extends StatelessWidget {
  const SettingPageScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.leading,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeConfigProvider>(
      builder: (context, themeConfig, _) {
        return themeConfig.buildThemedBackground(
          context: context,
          child: PlatformTypography.desktopFontScope(
            context: context,
            defaultColor: context.gradFg(),
            child: Scaffold(
              backgroundColor: Colors.transparent,
              extendBody: true,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                iconTheme: IconThemeData(color: context.gradFg()),
                leading:
                    leading ??
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios_new,
                        color: context.gradFg(),
                        size: 20,
                      ),
                      onPressed: () => Navigator.maybePop(context),
                    ),
                title: Text(
                  title,
                  style: context.gradAppBarTitleStyle(fontSize: 18),
                ),
                actions: actions,
              ),
              body: body,
            ),
          ),
        );
      },
    );
  }
}
