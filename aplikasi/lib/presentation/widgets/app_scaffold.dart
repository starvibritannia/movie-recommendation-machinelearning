import 'package:flutter/material.dart';

import 'app_background.dart';

/// Scaffold standar aplikasi: latar glow + konten di atasnya.
///
/// Semua halaman pakai ini supaya background glossy konsisten, dan supaya
/// app bar transparan tembus ke glow di belakangnya.
class AppScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget? body;
  final Widget? bottomNavigationBar;
  final bool extendBody;

  const AppScaffold({
    super.key,
    this.appBar,
    this.body,
    this.bottomNavigationBar,
    this.extendBody = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: extendBody,
      appBar: appBar,
      body: Stack(
        fit: StackFit.expand,
        children: [const AppBackground(), ?body],
      ),
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
