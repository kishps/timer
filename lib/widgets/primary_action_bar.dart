import 'package:flutter/material.dart';

class PrimaryActionBar extends StatelessWidget {
  final Widget child;

  const PrimaryActionBar({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: cs.surface,
          border: Border(
            top: BorderSide(color: cs.outlineVariant),
          ),
        ),
        child: child,
      ),
    );
  }
}

