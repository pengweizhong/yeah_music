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

class NeuBox extends StatelessWidget {
  final Widget child;
  double? width;
  double? height;
  final EdgeInsetsGeometry? padding;

  NeuBox({super.key, required this.child, this.width, this.height, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(color: Colors.grey.shade500, blurRadius: 10, offset: const Offset(3, 3)),
          BoxShadow(color: Colors.white, blurRadius: 10, offset: const Offset(-3, -3)),
        ],
      ),
      padding: padding ?? EdgeInsets.all(12),
      width: width,
      height: height,
      child: child,
    );
  }
}
