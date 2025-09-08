import 'package:flutter/material.dart';

class NeuBox extends StatelessWidget {
  final Widget child;

  const NeuBox({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(color: Colors.grey.shade500, blurRadius: 15, offset: const Offset(5, 5)),
          BoxShadow(color: Colors.white, blurRadius: 15, offset: const Offset(-5, -5)),
        ],
      ),
      padding: EdgeInsets.all(12),
      child: child,
    );
  }
}
