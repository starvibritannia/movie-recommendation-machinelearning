import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'tv_mascot.dart';

/// Pembungkus TonTon yang menambahkan animasi "bouncy":
/// lompat berulang (boink-boink), getaran, dan ledakan kecil.
///
/// Semua gerak di sini murni kode (nggak butuh aset), jadi ukuran bundel
/// tetap ringan.
class MascotStage extends StatefulWidget {
  final MascotMood mood;
  final double size;

  /// Tangan kecil: 1 = naik melambai, 0 = turun.
  final double wave;

  /// Berdiri di pijakan (bukan mengambang).
  final bool standing;

  /// Arah pandangan, dinormalisasi -1..1.
  final Offset lookAt;

  /// Lompat berulang.
  final bool jumping;

  /// Token pemicu getaran: tambah nilai untuk memicu.
  final int shakeToken;

  /// Token pemicu ledakan: tambah nilai untuk memicu.
  final int explodeToken;

  const MascotStage({
    super.key,
    this.mood = MascotMood.idle,
    this.size = 220,
    this.wave = 0,
    this.standing = true,
    this.lookAt = Offset.zero,
    this.jumping = false,
    this.shakeToken = 0,
    this.explodeToken = 0,
  });

  @override
  State<MascotStage> createState() => _MascotStageState();
}

class _MascotStageState extends State<MascotStage>
    with TickerProviderStateMixin {
  late final AnimationController _jump = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 820),
  );
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  );
  late final AnimationController _explode = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 720),
  );

  @override
  void initState() {
    super.initState();
    if (widget.jumping) _jump.repeat();
  }

  @override
  void didUpdateWidget(covariant MascotStage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.jumping != oldWidget.jumping) {
      if (widget.jumping) {
        _jump.repeat();
      } else {
        _jump.stop();
        _jump.value = 0;
      }
    }
    if (widget.shakeToken != oldWidget.shakeToken) {
      _shake.forward(from: 0);
    }
    if (widget.explodeToken != oldWidget.explodeToken) {
      _explode.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _jump.dispose();
    _shake.dispose();
    _explode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_jump, _shake, _explode]),
      builder: (context, _) {
        final s = widget.size;

        // ---- lompat boink-boink + squash saat mendarat ----
        var dy = 0.0;
        var scaleX = 1.0;
        var scaleY = 1.0;
        if (_jump.isAnimating) {
          final t = _jump.value;
          final j = math.sin(math.pi * t);
          dy = -s * 0.26 * j;
          scaleY = 1 - 0.10 * (1 - j);
          scaleX = 1 + 0.07 * (1 - j);
        }

        // ---- getar sebelum meledak ----
        var dx = 0.0;
        if (_shake.isAnimating) {
          final t = _shake.value;
          dx = math.sin(t * 46) * 9 * (1 - t);
        }

        // ---- ledakan: membesar lalu kembali ----
        var exScale = 1.0;
        if (_explode.isAnimating) {
          final t = _explode.value;
          exScale = t < 0.38
              ? 1 + 0.28 * (t / 0.38)
              : 1.28 - 0.28 * ((t - 0.38) / 0.62);
        }

        return SizedBox(
          width: s,
          height: s,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              if (_explode.isAnimating)
                Positioned.fill(
                  child: CustomPaint(painter: _BurstPainter(_explode.value)),
                ),
              Transform.translate(
                offset: Offset(dx, dy),
                child: Transform.scale(
                  scaleX: scaleX * exScale,
                  scaleY: scaleY * exScale,
                  alignment: Alignment.bottomCenter,
                  child: TvMascot(
                    mood: widget.mood,
                    size: s,
                    wave: widget.wave,
                    lookAt: widget.lookAt,
                    standing: widget.standing,
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
        ..color = const Color(0xFFFFB03A).withValues(alpha: (1 - p) * 0.75)
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
        Paint()
          ..color = const Color(0xFFFF7A18).withValues(alpha: (1 - p) * 0.9),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BurstPainter oldDelegate) => oldDelegate.t != t;
}
