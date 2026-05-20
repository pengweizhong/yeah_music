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

import 'dart:math' show pi, sin;

import 'package:flutter/material.dart';
import 'package:yeah_music/services/music_service.dart';

/// 与播放页队列行尾一致：随节拍上下起伏的竖条
class PlayingBarsIndicator extends StatefulWidget {
  const PlayingBarsIndicator({super.key, required this.color});

  final Color color;

  @override
  State<PlayingBarsIndicator> createState() => _PlayingBarsIndicatorState();
}

class _PlayingBarsIndicatorState extends State<PlayingBarsIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value * 2 * pi;
        const barCount = 4;
        return SizedBox(
          width: 22,
          height: 22,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(barCount, (i) {
              final wave = sin(t + i * 0.85);
              final h = 4.0 + 12.0 * ((wave + 1) / 2);
              return Container(
                width: 3,
                height: h,
                margin: const EdgeInsets.symmetric(horizontal: 0.5),
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(1.5),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

/// 曲库/歌单等列表行用：仅在实际播放中显示动态条，暂停时不占位出“在播”提示
class ListRowPlayingIndicator extends StatelessWidget {
  const ListRowPlayingIndicator({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: MusicService.playingStream,
      initialData: MusicService.isPlaying,
      builder: (context, snap) {
        if (snap.data != true) {
          return const SizedBox(width: 22, height: 22);
        }
        return PlayingBarsIndicator(color: color);
      },
    );
  }
}
