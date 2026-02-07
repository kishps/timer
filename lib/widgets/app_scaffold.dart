import 'package:flutter/material.dart';

class AppScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? bottom;

  const AppScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      body: SafeArea(
        bottom: bottom == null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: body,
        ),
      ),
      bottomNavigationBar: bottom,
    );
  }
}

