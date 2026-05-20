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
import 'package:yeah_music/l10n/app_localizations.dart';
import 'package:yeah_music/pages/albums_page.dart';
import 'package:yeah_music/pages/artists_page.dart';
import 'package:yeah_music/pages/playlist_page.dart';
import 'package:yeah_music/pages/setting/folder_page_setting.dart';
import 'package:yeah_music/pages/setting_page.dart';
import 'package:yeah_music/pages/statistics_page.dart';
import 'package:yeah_music/pages/storage_playlist_page.dart';
import 'package:yeah_music/widgets/app_themed_branding_logo.dart';

/// macOS 主页左侧栏：对应原抽屉 [MenuPage] 的入口，桌面端固定显示、可展开标签。
class MacosMainSidebar extends StatelessWidget {
  const MacosMainSidebar({
    super.key,
    required this.extended,
  });

  final bool extended;

  void _push(BuildContext context, Widget page) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surface.withValues(alpha: 0.42),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(
              color: scheme.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 14,
              offset: const Offset(4, 0),
            ),
          ],
        ),
        child: NavigationRail(
          extended: extended,
          backgroundColor: Colors.transparent,
          selectedIndex: 0,
          groupAlignment: -1,
          minWidth: extended ? 216 : 72,
          minExtendedWidth: 220,
          labelType: NavigationRailLabelType.none,
          leading: extended
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(12, 20, 12, 20),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: AppThemedBrandingLogo(
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          filterQuality: FilterQuality.medium,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.appTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: scheme.onSurface.withValues(alpha: 0.92),
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: AppThemedBrandingLogo(
                      width: 36,
                      height: 36,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.medium,
                    ),
                  ),
                ),
          destinations: [
            NavigationRailDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home_rounded),
              label: Text(l10n.menuHome),
            ),
            NavigationRailDestination(
              icon: const Icon(Icons.library_music_outlined),
              selectedIcon: const Icon(Icons.library_music_rounded),
              label: Text(l10n.menuSongList),
            ),
            NavigationRailDestination(
              icon: const Icon(Icons.person_outline_rounded),
              selectedIcon: const Icon(Icons.person_rounded),
              label: Text(l10n.menuArtists),
            ),
            NavigationRailDestination(
              icon: const Icon(Icons.album_outlined),
              selectedIcon: const Icon(Icons.album_rounded),
              label: Text(l10n.menuAlbums),
            ),
            NavigationRailDestination(
              icon: const Icon(Icons.folder_copy_outlined),
              selectedIcon: const Icon(Icons.folder_copy_rounded),
              label: Text(l10n.menuPlaylists),
            ),
            NavigationRailDestination(
              icon: const Icon(Icons.source),
              selectedIcon: const Icon(Icons.source),
              label: Text(l10n.menuMusicSource),
            ),
            NavigationRailDestination(
              icon: const Icon(Icons.insights_outlined),
              selectedIcon: const Icon(Icons.insights_rounded),
              label: Text(l10n.menuStatistics),
            ),
            NavigationRailDestination(
              icon: const Icon(Icons.settings_outlined),
              selectedIcon: const Icon(Icons.settings_rounded),
              label: Text(l10n.menuSettings),
            ),
          ],
          onDestinationSelected: (index) {
            switch (index) {
              case 0:
                break;
              case 1:
                _push(context, const PlayListPage());
                break;
              case 2:
                _push(context, const ArtistsBrowserPage());
                break;
              case 3:
                _push(context, const AlbumsBrowserPage());
                break;
              case 4:
                _push(context, const StoragePlayListPage());
                break;
              case 5:
                _push(context, FolderPageSettings());
                break;
              case 6:
                _push(context, const StatisticsPage());
                break;
              case 7:
                _push(context, SettingPage());
                break;
            }
          },
        ),
      ),
    );
  }
}
