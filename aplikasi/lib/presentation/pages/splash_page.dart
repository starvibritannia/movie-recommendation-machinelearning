import 'dart:async';

import 'package:flutter/material.dart';

import '../widgets/app_scaffold.dart';
import '../widgets/jelly_loader.dart';
import '../widgets/poster_collage.dart';
import '../widgets/wordmark.dart';
import 'main_shell.dart';

/// Halaman pembuka: mosaik poster film di latar (langsung tampil dari aset),
/// logo NeVie, dan loader jelly.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 3000), _goToHome);
  }

  void _goToHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 560),
        pageBuilder: (_, _, _) => const MainShell(),
        transitionsBuilder: (_, anim, _, child) => FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1).animate(
              CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Latar: mosaik poster (aset lokal, nggak perlu nunggu jaringan).
          const PosterCollage(),

          // Konten di atas mosaik.
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.9, end: 1),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutBack,
                    builder: (context, scale, child) =>
                        Transform.scale(scale: scale, child: child),
                    child: const Wordmark(fontSize: 56, showTagline: true),
                  ),
                  const SizedBox(height: 36),
                  const JellyLoader(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
