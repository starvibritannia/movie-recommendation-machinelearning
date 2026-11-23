import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'tonton_engine.dart';
import 'tv_mascot.dart';

/// Pembungkus TonTon: karakter + efek ledakan kecil pas genre muncul.
///
/// Semua gerak Badan TonTon datang dari [MascotController] (engine fisika).
/// Wrapper ini cuma menempatkan TonTon dan overlay visual tambahan.
class MascotStage extends StatefulWidget {
  final MascotController controller;
  final double size;

  /// Token pemicu ledakan: tambah nilai untuk memicu.
  final int explodeToken;

  /// Hormati sistem "keluar dari animasi" (reduced motion).
  final bool reducedMotion;

  const MascotStage({
    super.key,
    required this.controller,
    this.size = 220,
    this.explodeToken = 0,
    this.reducedMotion = false,
  });

  @override
  State<MascotStage> createState() => _MascotStageState();
}

class _MascotStageState extends State<MascotStage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _explode = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 720),
  );

  @override
  void initState() {
    super.initState();
    if (widget.explodeToken > 0) _explode.forward(from: 0);
  }

  @override
  void didUpdateWidget(covariant MascotStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.explodeToken != oldWidget.explodeToken) {
      _explode.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _explode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          if (_explode.isAnimating)
            Positioned.fill(
              child: CustomPaint(painter: _BurstPainter(_explode.value)),
            ),
          TvMascot(
            controller: widget.controller,
            size: widget.size,
            reducedMotion: widget.reducedMotion,
          ),
        ],
      ),
    );
  }
}

/// Ledakan kecil: cincin mengembang + partikel berhamburan.
class _BurstPainter extends CustomPainter {
  final double t;

  const _BurstPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final p = t.clamp(0.0, 1.0);

    final ringRadius = size.width * 0.16 + p * size.width * 0.55;
    canvas.drawCircle(
      center,
      ringRadius,
      Paint()
        ..color = AppColors.accentLight.withValues(alpha: (1 - p) * 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5 * (1 - p) + 1,
    );

    for (var i = 0; i < 12; i++) {
      final angle = i / 12 * math.pi * 2;
      final dist = size.width * 0.12 + p * size.width * 0.48;
      final pos =
          center + Offset(math.cos(angle) * dist, math.sin(angle) * dist);
      canvas.drawCircle(
        pos,
        4.5 * (1 - p) + 0.5,
        Paint()..color = AppColors.accent.withValues(alpha: (1 - p) * 0.9),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BurstPainter oldDelegate) => oldDelegate.t != t;
}
