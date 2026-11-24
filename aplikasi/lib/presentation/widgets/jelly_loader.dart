import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Loader splash: blob jelly + deretan titik jelly yang melompat.
///
/// Konsepnya "TonTon lagi nyari film": blob oranye (badan TonTon) yang membek
/// seperti jelly sambil membelikkan mata, dan titik-titik jelly yang melompat
/// bergantian.
class JellyLoader extends StatefulWidget {
  const JellyLoader({super.key});

  @override
  State<JellyLoader> createState() => _JellyLoaderState();
}

class _JellyLoaderState extends State<JellyLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _JellyBlob(controller: _c),
        const SizedBox(height: 24),
        _JellyDots(controller: _c),
      ],
    );
  }
}

/// Blob jelly bergaya TonTon: badan oranye, mata putih yang sesekali berkedip.
class _JellyBlob extends StatelessWidget {
  final AnimationController controller;

  const _JellyBlob({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = controller.value * math.pi * 2;
        final s = math.sin(t * 2);
        final blink = math.sin(t * 1.7) > 0.985 ? 0.15 : 1.0;
        return Transform(
          alignment: Alignment.bottomCenter,
          transform: Matrix4.diagonal3Values(1 + 0.16 * s, 1 - 0.16 * s, 1),
          child: Container(
            width: 78,
            height: 62,
            decoration: BoxDecoration(
              gradient: AppColors.accentGradient,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.35),
                  blurRadius: 26,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [_eye(blink), const SizedBox(width: 12), _eye(blink)],
            ),
          ),
        );
      },
    );
  }

  Widget _eye(double blink) => Container(
    width: 8,
    height: 12 * blink,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(4),
    ),
  );
}

/// Tiga titik jelly yang melompat bergantian (indeterminate, gemoyang).
class _JellyDots extends StatelessWidget {
  final AnimationController controller;

  const _JellyDots({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final phase = controller.value * math.pi * 2 + i * 0.85;
            final k = math.max(0.0, math.sin(phase));
            return Transform.translate(
              offset: Offset(0, -7 * k),
              child: Transform.scale(
                scale: 0.75 + 0.35 * k,
                child: Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    gradient: AppColors.accentGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
