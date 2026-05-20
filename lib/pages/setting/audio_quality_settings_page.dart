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
import 'package:yeah_music/l10n/app_localizations.dart';
import 'package:yeah_music/themes/gradient_ui_colors.dart';
import 'package:yeah_music/utils/song_audio_quality.dart';
import 'package:yeah_music/widgets/song_audio_quality_badge.dart';

/// 音质分级说明：从低到高展示标识样式与判定规则。
class AudioQualitySettingsPage extends StatelessWidget {
  const AudioQualitySettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Consumer<ThemeConfigProvider>(
      builder: (context, themeConfig, _) {
        return themeConfig.buildThemedBackground(
          context: context,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: Text(
                l10n.settingsAudioQualityTitle,
                style: TextStyle(color: context.gradFg()),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: IconThemeData(color: context.gradFg()),
            ),
            body: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                Text(
                  l10n.settingsAudioQualityHelp,
                  style: TextStyle(
                    color: context.gradFg(0.72),
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 20),
                ...kSongAudioQualityTiersLowToHigh.map(
                  (tier) => _TierReferenceTile(tier: tier),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TierReferenceTile extends StatelessWidget {
  const _TierReferenceTile({required this.tier});

  final SongAudioQualityTier tier;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.gradFg(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.gradBorder(0.14)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SongAudioQualityBadge(tier: tier, compact: false),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      songAudioQualityLocalizedTitle(l10n, tier),
                      style: TextStyle(
                        color: context.gradFg(),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tier.shortLabel,
                      style: TextStyle(
                        color: songAudioQualityAccent(tier, context)
                            .withValues(alpha: 0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      songAudioQualityLocalizedDescription(l10n, tier),
                      style: TextStyle(
                        color: context.gradFg(0.65),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
