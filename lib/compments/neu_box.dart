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
