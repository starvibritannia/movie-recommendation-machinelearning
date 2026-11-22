import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Ekspresi maskot.
///
/// Maskot TV ini digambar murni dengan [CustomPaint], jadi latarnya
/// transparan: yang terlihat cuma maskotnya di atas background aplikasi.
enum MascotMood { idle, talking, thinking, happy, love, excited, sad, scared }

/// Maskot NeVie berbentuk kepala TV retro.
///
/// Semua gerak dihasilkan dari satu [AnimationController] berulang, jadi
/// nggak butuh aset eksternal dan nggak menambah ukuran bundel.
class TvMascot extends StatefulWidget {
  final MascotMood mood;
  final double size;

  /// Tangan kecil: 1 = naik melambai, 0 = turun ke sisi badan.
  final double wave;

  /// Arah pandangan mata, dinormalisasi -1..1 (kitchen sink: maskot bisa
  /// "ngelirik" objek di sekitarnya).
  final Offset lookAt;

  /// true = berdiri di pijakan (nggak mengambang), false = mengambang.
  final bool standing;

  const TvMascot({
    super.key,
    this.mood = MascotMood.idle,
    this.size = 220,
    this.wave = 0,
    this.lookAt = Offset.zero,
    this.standing = false,
  });

  @override
  State<TvMascot> createState() => _TvMascotState();
}

class _TvMascotState extends State<TvMascot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _TvMascotPainter(
              t: _controller.value * 4,
              mood: widget.mood,
              lookAt: widget.lookAt,
              wave: widget.wave,
              standing: widget.standing,
            ),
          );
        },
      ),
    );
  }
}

/// Penggambar maskot TV.
///
/// Kanvas dianggap 220x220 lalu diskalakan, supaya koordinat mudah dibaca.
class _TvMascotPainter extends CustomPainter {
  final double t;
  final MascotMood mood;
  final Offset lookAt;
  final double wave;
  final bool standing;

  _TvMascotPainter({
    required this.t,
    required this.mood,
    this.lookAt = Offset.zero,
    this.wave = 0,
    this.standing = false,
  });

  static const double _base = 220;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / _base;
    canvas.save();
    canvas.scale(scale);

    // Gerak mengambang + goyang halus, beda tiap mood.
    // Kalau berdiri, maskot nggak "ngapung": cuma napas kecil, pijakan diam.
    final sway = standing ? 0.0 : math.sin(t * 1.7) * 2.4;
    final bob = standing ? math.sin(t * 2.0) * 0.8 : math.sin(t * 1.15) * 2.2;
    var dx = sway;
    var dy = bob;
    var tilt = math.sin(t * 0.9) * 0.035;

    switch (mood) {
      case MascotMood.happy:
      case MascotMood.love:
      case MascotMood.excited:
        dy -= math.max(0, math.sin(t * 5.0)) * 9;
        tilt = math.sin(t * 5.0) * 0.06;
      case MascotMood.sad:
        tilt = 0.10;
        dy += 2.5;
      case MascotMood.scared:
        dx += math.sin(t * 26) * 2.2;
        tilt = math.sin(t * 22) * 0.03;
      case MascotMood.thinking:
        tilt = -0.12;
      case MascotMood.talking:
        dy += math.sin(t * 8.0) * 1.1;
      case MascotMood.idle:
        break;
    }

    // Bayangan pijakan: pijakannya sendiri tidak digambar, cuma bayangannya
    // supaya maskot kelihatan "nyangkak" di tanah.
    if (standing) _drawShadow(canvas);

    canvas.translate(110 + dx, 112 + dy);
    canvas.rotate(tilt);
    canvas.translate(-110, -112);

    _drawAntenna(canvas);
    _drawBody(canvas);
    if (wave > 0.01) _drawArm(canvas);
    _drawScreen(canvas);
    _drawFace(canvas);
    _drawLegs(canvas);

    canvas.restore();
  }

  // ------------------------------------------------------------ pijakan
  void _drawShadow(Canvas canvas) {
    final rect = Rect.fromCenter(
      center: const Offset(110, 190),
      width: 104,
      height: 13,
    );
    canvas.drawOval(
      rect,
      Paint()..color = Colors.black.withValues(alpha: 0.38),
    );
  }

  /// Tangan kecil: wave = 1 naik melambai, wave = 0 turun ke sisi badan.
  void _drawArm(Canvas canvas) {
    final raise = wave.clamp(0.0, 1.0);
    final swing = math.sin(t * 7.0) * 0.28 * raise;
    final angle = -0.95 + (1 - raise) * 1.45 + swing;
    final armLen = 15.0 + raise * 13.0;

    canvas.save();
    canvas.translate(176, 124);
    canvas.rotate(angle);

    final arm = Paint()
      ..color = const Color(0xFFE9ECF3)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    final armEnd = Offset(armLen, -armLen * 0.6);
    canvas.drawLine(Offset.zero, armEnd, arm);

    final handPaint = Paint()..color = const Color(0xFFE9ECF3);
    final border = Paint()
      ..color = const Color(0x40FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final handCenter = armEnd + const Offset(6, -6);
    // Tiga jari kecil.
    for (var i = 0; i < 3; i++) {
      final c = handCenter + Offset(-5.0 + i * 5.0, -7.5);
      canvas.drawCircle(c, 3.0, handPaint);
      canvas.drawCircle(c, 3.0, border);
    }
    // Telapak + ibu jari.
    canvas.drawCircle(handCenter, 7.6, handPaint);
    canvas.drawCircle(handCenter, 7.6, border);
    canvas.drawCircle(handCenter + const Offset(-8, 2.5), 3.2, handPaint);
    canvas.drawCircle(handCenter + const Offset(-8, 2.5), 3.2, border);

    canvas.restore();
  }

  // ------------------------------------------------------------ bagian TV
  void _drawAntenna(Canvas canvas) {
    final paint = Paint()
      ..color = const Color(0xFFD8DCE6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.4
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(const Offset(84, 46), const Offset(58, 14), paint);
    canvas.drawLine(const Offset(136, 46), const Offset(162, 14), paint);

    final tip = Paint()..color = const Color(0xFFFF7A18);
    canvas.drawCircle(const Offset(58, 13), 4.6, tip);
    canvas.drawCircle(const Offset(162, 13), 4.6, tip);
  }

  void _drawBody(Canvas canvas) {
    final body = Paint()..color = const Color(0xFFE9ECF3);
    final border = Paint()
      ..color = const Color(0x33FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    final rect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(42, 44, 136, 128),
      const Radius.circular(26),
    );
    // Shadow lembut di bawah badan.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(42, 49, 136, 128),
        const Radius.circular(26),
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.28),
    );
    canvas.drawRRect(rect, body);
    canvas.drawRRect(rect, border);

    // Strip aksen oranye di bawah TV.
    final accent = Paint()..color = const Color(0xFFFF7A18);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(42, 150, 136, 22),
        const Radius.circular(12),
      ),
      accent,
    );

    // Tombol & speaker di sisi kanan badan.
    final button = Paint()..color = const Color(0xFFFF7A18);
    canvas.drawCircle(const Offset(164, 128), 4.2, button);
    final led = Paint()..color = const Color(0xFF2BB3C0);
    canvas.drawCircle(const Offset(164, 141), 2.6, led);

    // Garis speaker.
    final speaker = Paint()
      ..color = const Color(0xFFB7BECB)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 3; i++) {
      final y = 112.0 + i * 7;
      canvas.drawLine(Offset(150, y), Offset(158, y), speaker);
    }
  }

  void _drawScreen(Canvas canvas) {
    final screen = RRect.fromRectAndRadius(
      const Rect.fromLTWH(58, 62, 104, 88),
      const Radius.circular(18),
    );

    // Glow layar.
    canvas.drawRRect(
      screen.shift(const Offset(0, 1)),
      Paint()..color = const Color(0x33FF7A18),
    );
    canvas.drawRRect(screen, Paint()..color = const Color(0xFF0C1424));

    // Kilau diagonal tipis.
    final glare = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(62, 150)
      ..lineTo(96, 62)
      ..lineTo(116, 62)
      ..lineTo(82, 150)
      ..close();
    canvas.drawPath(path, glare);
  }

  // ------------------------------------------------------------ wajah
  void _drawFace(Canvas canvas) {
    final eyeWhite = Paint()..color = const Color(0xFF7DF3FF);
    final mouth = Paint()
      ..color = const Color(0xFF7DF3FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final blink = _blink();
    final mouthOpen = _mouthOpen();

    // Posisi mata bergeser saat "thinking" dan mengikuti arah pandang.
    final lookUp = mood == MascotMood.thinking ? -10.0 : 0.0;
    final leftEye = Offset(
      84 + lookAt.dx * 3.4,
      104 + lookUp + lookAt.dy * 3.0,
    );
    final rightEye = Offset(
      136 + lookAt.dx * 3.4,
      104 + lookUp + lookAt.dy * 3.0,
    );

    switch (mood) {
      case MascotMood.happy:
        // Mata ^ ^
        canvas.drawArc(
          Rect.fromCenter(center: leftEye, width: 20, height: 16),
          math.pi,
          math.pi,
          false,
          eyeWhite..strokeWidth = 3,
        );
        canvas.drawArc(
          Rect.fromCenter(center: rightEye, width: 20, height: 16),
          math.pi,
          math.pi,
          false,
          eyeWhite..strokeWidth = 3,
        );
        _blush(canvas);
      case MascotMood.love:
        _heart(canvas, leftEye, 11, eyeWhite);
        _heart(canvas, rightEye, 11, eyeWhite);
        _blush(canvas);
      case MascotMood.excited:
        // Mata ^ ^ + kilau bintang di samping.
        canvas.drawArc(
          Rect.fromCenter(center: leftEye, width: 22, height: 17),
          math.pi,
          math.pi,
          false,
          eyeWhite..strokeWidth = 3.2,
        );
        canvas.drawArc(
          Rect.fromCenter(center: rightEye, width: 22, height: 17),
          math.pi,
          math.pi,
          false,
          eyeWhite..strokeWidth = 3.2,
        );
        _sparkle(canvas, const Offset(58, 84));
        _sparkle(canvas, const Offset(164, 80));
        _blush(canvas);
      case MascotMood.sad:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: leftEye, width: 13, height: 13 * blink),
            const Radius.circular(6),
          ),
          eyeWhite,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: rightEye, width: 13, height: 13 * blink),
            const Radius.circular(6),
          ),
          eyeWhite,
        );
        _sweat(canvas);
      case MascotMood.scared:
        canvas.drawCircle(leftEye, 9.5, eyeWhite);
        canvas.drawCircle(rightEye, 9.5, eyeWhite);
        canvas.drawCircle(
          leftEye.translate(2.5, 2.5),
          3.2,
          Paint()..color = const Color(0xFF0C1424),
        );
        canvas.drawCircle(
          rightEye.translate(2.5, 2.5),
          3.2,
          Paint()..color = const Color(0xFF0C1424),
        );
      case MascotMood.thinking:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: leftEye, width: 12, height: 12 * blink),
            const Radius.circular(6),
          ),
          eyeWhite,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: rightEye, width: 12, height: 12 * blink),
            const Radius.circular(6),
          ),
          eyeWhite,
        );
        _brows(canvas, raised: true);
      default:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: leftEye, width: 13, height: 15 * blink),
            const Radius.circular(6),
          ),
          eyeWhite,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: rightEye, width: 13, height: 15 * blink),
            const Radius.circular(6),
          ),
          eyeWhite,
        );
        _eyeHighlight(canvas, leftEye);
        _eyeHighlight(canvas, rightEye);
    }

    // Mulut.
    final mouthCenter = Offset(110 + lookAt.dx * 1.6, 132 + lookAt.dy * 1.2);
    switch (mood) {
      case MascotMood.happy:
      case MascotMood.love:
      case MascotMood.excited:
        canvas.drawArc(
          Rect.fromCenter(center: mouthCenter, width: 26, height: 20),
          0,
          math.pi,
          false,
          mouth..strokeWidth = 3.4,
        );
      case MascotMood.sad:
        canvas.drawArc(
          Rect.fromCenter(
            center: mouthCenter.translate(0, 6),
            width: 22,
            height: 14,
          ),
          math.pi,
          math.pi,
          false,
          mouth,
        );
      case MascotMood.scared:
        canvas.drawCircle(mouthCenter, 6.5, mouth..style = PaintingStyle.fill);
      case MascotMood.thinking:
        canvas.drawLine(
          mouthCenter.translate(-6, 0),
          mouthCenter.translate(6, 0),
          mouth,
        );
      default:
        // Senyum / ngobrol: mulut terbuka tutup, plus lidah pas terbuka.
        final h = 4 + mouthOpen * 10;
        canvas.drawArc(
          Rect.fromCenter(center: mouthCenter, width: 22, height: h + 6),
          0,
          math.pi,
          false,
          mouth,
        );
        if (mouthOpen > 0.35) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: mouthCenter.translate(0, 4),
                width: 13,
                height: 9 * mouthOpen,
              ),
              const Radius.circular(4),
            ),
            Paint()..color = const Color(0xFFFF6B81),
          );
        }
    }
  }

  void _brows(Canvas canvas, {required bool raised}) {
    final paint = Paint()
      ..color = const Color(0xFF7DF3FF)
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;
    final dy = raised ? -6.0 : 0.0;
    canvas.drawLine(Offset(76, 92 + dy), Offset(92, 90 + dy), paint);
    canvas.drawLine(Offset(128, 90 + dy), Offset(144, 92 + dy), paint);
  }

  void _blush(Canvas canvas) {
    final paint = Paint()..color = Colors.pinkAccent.withValues(alpha: 0.45);
    canvas.drawCircle(const Offset(72, 124), 5, paint);
    canvas.drawCircle(const Offset(148, 124), 5, paint);
  }

  void _sweat(Canvas canvas) {
    final paint = Paint()..color = const Color(0xFF7DF3FF);
    final path = Path()
      ..moveTo(150, 92)
      ..lineTo(156, 102)
      ..lineTo(150, 110)
      ..lineTo(144, 102)
      ..close();
    canvas.drawPath(path, paint);
  }

  /// Mata berbentuk hati.
  void _heart(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path()
      ..moveTo(center.dx, center.dy + size * 0.55)
      ..cubicTo(
        center.dx - size * 1.15,
        center.dy - size * 0.25,
        center.dx - size * 0.45,
        center.dy - size * 1.05,
        center.dx,
        center.dy - size * 0.35,
      )
      ..cubicTo(
        center.dx + size * 0.45,
        center.dy - size * 1.05,
        center.dx + size * 1.15,
        center.dy - size * 0.25,
        center.dx,
        center.dy + size * 0.55,
      )
      ..close();
    canvas.drawPath(path, paint..style = PaintingStyle.fill);
  }

  /// Kilau kecil di mata supaya terlihat hidup.
  void _eyeHighlight(Canvas canvas, Offset center) {
    canvas.drawCircle(
      center.translate(-3.2, -4.2),
      2.4,
      Paint()..color = Colors.white.withValues(alpha: 0.9),
    );
  }

  /// Kilau bintang 4 sudut.
  void _sparkle(Canvas canvas, Offset center) {
    final paint = Paint()
      ..color = const Color(0xFFFFE08A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    const r = 7.0;
    canvas.drawLine(center.translate(0, -r), center.translate(0, r), paint);
    canvas.drawLine(center.translate(-r, 0), center.translate(r, 0), paint);
  }

  void _drawLegs(Canvas canvas) {
    final paint = Paint()..color = const Color(0xFFD8DCE6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(68, 172, 16, 14),
        const Radius.circular(5),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(136, 172, 16, 14),
        const Radius.circular(5),
      ),
      paint,
    );
  }

  // ------------------------------------------------------------ animasi
  /// Kedip: sebagian besar waktu mata terbuka, sesekali menutup singkat.
  double _blink() {
    final phase = (t * 1.0) % 3.7;
    if (phase > 3.35) {
      return 0.12;
    }
    return 1.0;
  }

  double _mouthOpen() {
    if (mood != MascotMood.talking) return 0;
    return (math.sin(t * 11) * 0.5 + 0.5).clamp(0.0, 1.0);
  }

  @override
  bool shouldRepaint(covariant _TvMascotPainter oldDelegate) {
    return oldDelegate.mood != mood ||
        oldDelegate.t != t ||
        oldDelegate.lookAt != lookAt ||
        oldDelegate.wave != wave ||
        oldDelegate.standing != standing;
  }
}
