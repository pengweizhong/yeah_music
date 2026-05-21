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

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:yeah_music/l10n/app_localizations.dart';
import 'package:yeah_music/compments/frosted_glass_panel.dart';
import 'package:yeah_music/pages/albums_page.dart';
import 'package:yeah_music/pages/artists_page.dart';
import 'package:yeah_music/pages/playlist_page.dart';
import 'package:yeah_music/pages/setting_page.dart';
import 'package:yeah_music/pages/statistics_page.dart';
import 'package:yeah_music/pages/storage_playlist_page.dart';

import '../pages/setting/folder_page_setting.dart';
import 'package:yeah_music/themes/gradient_ui_colors.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  static const double _kDrawerContentMaxWidth = 340;

  /// 略加大左侧留白、收紧右侧，让图标+文字整块视觉上更落在抽屉中线偏右（仍左对齐文案）。
  static const double _kListPadLeft = 34;
  static const double _kListPadRight = 12;
  static const double _kIconTextGap = 24;

  Widget _menuTile({
    required BuildContext context,
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      minLeadingWidth: 32,
      horizontalTitleGap: _kIconTextGap,
      leading: Icon(icon, color: context.gradFg()),
      title: Text(
        label,
        textAlign: TextAlign.left,
        style: context.gradTileTitleStyle(fontSize: 15),
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Drawer(
      backgroundColor: Colors.transparent,
      child: FrostedGlassPanel.drawer(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final drawerW = constraints.maxWidth;
              final contentW = math.min(_kDrawerContentMaxWidth, drawerW);
              // 窄于 max 时略偏右对齐，避免几何居中仍显「贴左」；与左右非对称 padding 一起做视觉平衡
              final alignX = contentW < drawerW - 1 ? 0.14 : 0.08;
              return Align(
                alignment: Alignment(alignX, -1),
                child: SizedBox(
                  width: contentW,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      _kListPadLeft,
                      12,
                      _kListPadRight,
                      12,
                    ),
                    children: [
                      SizedBox(
                        height: 168,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.12),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                child: Image.asset(
                                  'assets/icons/yeah_music1.png',
                                  height: 112,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _menuTile(
                        context: context,
                        icon: Icons.home,
                        label: l10n.menuHome,
                        onTap: () => Navigator.pop(context),
                      ),
                      _menuTile(
                        context: context,
                        icon: Icons.list,
                        label: l10n.menuSongList,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => const PlayListPage(),
                            ),
                          );
                        },
                      ),
                      _menuTile(
                        context: context,
                        icon: Icons.person_outline_rounded,
                        label: l10n.menuArtists,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => const ArtistsBrowserPage(),
                            ),
                          );
                        },
                      ),
                      _menuTile(
                        context: context,
                        icon: Icons.album_outlined,
                        label: l10n.menuAlbums,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => const AlbumsBrowserPage(),
                            ),
                          );
                        },
                      ),
                      _menuTile(
                        context: context,
                        icon: Icons.folder_copy_outlined,
                        label: l10n.menuPlaylists,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => const StoragePlayListPage(),
                            ),
                          );
                        },
                      ),
                      _menuTile(
                        context: context,
                        icon: Icons.source,
                        label: l10n.menuMusicSource,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => FolderPageSettings(),
                            ),
                          );
                        },
                      ),
                      _menuTile(
                        context: context,
                        icon: Icons.insights_outlined,
                        label: l10n.menuStatistics,
                        onTap: () {
                          Navigator.push<void>(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => const StatisticsPage(),
                            ),
                          );
                        },
                      ),
                      _menuTile(
                        context: context,
                        icon: Icons.settings,
                        label: l10n.menuSettings,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => SettingPage(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
