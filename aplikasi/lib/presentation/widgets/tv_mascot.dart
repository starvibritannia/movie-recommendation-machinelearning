import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'tonton_engine.dart';

/// Maskot NeVie: TV retro gembul dengan slot mulut ala VCR.
///
/// Desainnya (bentuk TV, layar, antena, kaki, slot mulut) tetap. Semua gerak
/// datang dari [TontonEngine], port fisika "soft-body" ala GoSpeak.
/// TonTon melayang bebas dan bisa diseret kemana saja.
class TvMascot extends StatefulWidget {
  final MascotController controller;
  final double size;

  final bool reducedMotion;

  const TvMascot({
    super.key,
    required this.controller,
    this.size = 220,
    this.reducedMotion = false,
  });

  @override
  State<TvMascot> createState() => _TvMascotState();
}

class _TvMascotState extends State<TvMascot>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _last = Duration.zero;

  @override
  void initState() {
    super.initState();
    widget.controller.engine.reducedMotion = widget.reducedMotion;
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    final dt = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    widget.controller.engine.reducedMotion = widget.reducedMotion;
    widget.controller.tick(dt);
  }

  @override
  void didUpdateWidget(covariant TvMascot oldWidget) {
    super.didUpdateWidget(oldWidget);
    widget.controller.engine.reducedMotion = widget.reducedMotion;
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _toLocal(PointerEvent ev) {
    final scale = 220 / widget.size;
    final p = Offset(ev.localPosition.dx * scale, ev.localPosition.dy * scale);
    if (ev is PointerDownEvent) {
      widget.controller.pointerDown(p);
    } else if (ev is PointerMoveEvent) {
      widget.controller.pointerMove(p);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: _toLocal,
            onPointerMove: _toLocal,
            onPointerUp: (_) => widget.controller.pointerUp(),
            onPointerCancel: (_) => widget.controller.pointerUp(),
            child: CustomPaint(
              painter: _TvMascotPainter(widget.controller.engine),
            ),
          ),
        );
      },
    );
  }
}

/// Penggambar maskot TV gembul.
///
/// Kanvas dianggap 220x220 lalu diskalakan, supaya koordinat mudah dibaca.
class _TvMascotPainter extends CustomPainter {
  final TontonEngine engine;

  _TvMascotPainter(this.engine);

  static const double _base = 220;
  static const Color _screen = Color(0xFF0C1424);
  static const Color _body = Color(0xFFEDEFF5);
  static const Color _bodyShade = Color(0xFFDFE3EC);
  static const Color _metal = Color(0xFFD3D8E4);
  static const Color _face = Color(0xFFFFFFFF);

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / _base;
    canvas.save();
    canvas.scale(scale);

    final e = engine;

    // TonTon melayang bebas (tanpa pijakan). Pivot di tengah badan supaya
    // squash & stretch terasa seperti jelly yang melayang.
    canvas.translate(110 + e.pos.dx, 112 + e.pos.dy + e.bobY);
    canvas.scale(1 + 0.75 * e.sq, 1 - e.sq);
    canvas.rotate(e.lean + e.swayAmt + e.wave * math.sin(e.time * 9) * 0.16);
    canvas.translate(0, e.nodDip * 1.2);
    canvas.rotate(e.nodDip * 0.004);
    final speed = e.vel.distance;
    if (speed > 40) {
      final a = math.atan2(e.vel.dy, e.vel.dx);
      final k = 1 + math.min(0.2, speed * 0.00016).toDouble();
      canvas.rotate(a);
      canvas.scale(k, 1 / k);
      canvas.rotate(-a);
    }
    canvas.translate(-110, -112);

    _drawAntenna(canvas, e);
    _drawBody(canvas, e);
    _drawRipple(canvas, e);

    // Layar & wajah tertinggal sedikit di belakang badan (membran jelly),
    // dan "pop" sebentar saat ekspresi berganti.
    canvas.save();
    canvas.translate(e.lagX, e.lagY);
    _drawScreen(canvas, e);
    canvas.save();
    canvas.translate(110, 112);
    canvas.scale(1 + e.exprPop * 0.12);
    canvas.translate(-110, -112);
    _drawFace(canvas, e);
    canvas.restore();
    canvas.restore();

    _drawTapeSlot(canvas, e);

    canvas.restore();
  }

  // ------------------------------------------------------------ antena
  void _drawAntenna(Canvas canvas, TontonEngine e) {
    // Gobang ngikut mood: lebih keok saat kaget/takut, lurus pas senang.
    final expr = e.expression;
    final shaky =
        expr == MascotExpression.horrified || expr == MascotExpression.furious;
    final wobble = math.sin(e.time * (shaky ? 22 : 6)) * (shaky ? 2.2 : 1.6);
    final spread =
        expr == MascotExpression.excited ||
            expr == MascotExpression.furious ||
            expr == MascotExpression.love
        ? 1.12
        : 1.0;
    final droop =
        expr == MascotExpression.sad ||
            expr == MascotExpression.devastated ||
            expr == MascotExpression.asleep
        ? 12.0
        : 0.0;

    final rod = Paint()
      ..color = _metal
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.4
      ..strokeCap = StrokeCap.round;

    for (final side in [-1.0, 1.0]) {
      final base = Offset(110 + side * 22, 44);
      final tip = Offset(110 + side * 52 * spread + wobble * side, 12 + droop);
      canvas.drawLine(base, tip, rod);
      canvas.drawCircle(tip, 5.4, Paint()..color = e.color);
      canvas.drawCircle(
        tip.translate(-1.4, -1.4),
        1.8,
        Paint()..color = Colors.white.withValues(alpha: 0.75),
      );
    }
  }

  // ------------------------------------------------------------ badan
  void _drawBody(Canvas canvas, TontonEngine e) {
    final rect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(34, 42, 152, 138),
      const Radius.circular(32),
    );

    // Bayangan lembut di bawah badan.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(34, 48, 152, 138),
        const Radius.circular(32),
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.22),
    );

    // Kontur jelly: outline bergetar halus, makin kuat saat squash/ripple.
    final path = _jellyPath(rect, e);
    canvas.drawPath(path, Paint()..color = _body);

    // Volume: lapisan terang/gelap biar badan kelihatan gembul.
    canvas.save();
    canvas.clipPath(path);
    canvas.drawRect(
      const Rect.fromLTWH(34, 42, 152, 70),
      Paint()..color = Colors.white.withValues(alpha: 0.55),
    );
    canvas.drawRect(
      const Rect.fromLTWH(34, 150, 152, 30),
      Paint()..color = _bodyShade.withValues(alpha: 0.7),
    );
    canvas.restore();

    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0x40FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );
  }

  /// Bangun ulang outline rounded-rect jadi path yang permukaannya bergetar
  /// seperti jelly (port "soft-body membrane" ala GoSpeak).
  Path _jellyPath(RRect rrect, TontonEngine e) {
    final r = rrect.outerRect;
    final rad = math.min(rrect.tlRadius.x, math.min(r.width, r.height) / 2);
    final amp = 1.1 + e.sq.abs() * 6 + e.ripple * 2.2;

    final pts = <Offset>[];
    final nrm = <Offset>[];

    void push(Offset p, Offset n) {
      if (pts.isNotEmpty && (pts.last - p).distance < 0.01) return;
      pts.add(p);
      nrm.add(n);
    }

    const segs = 10;
    void edge(
      double x0,
      double y0,
      double x1,
      double y1,
      double nx,
      double ny,
    ) {
      for (var i = 0; i <= segs; i++) {
        final t = i / segs;
        push(Offset(x0 + (x1 - x0) * t, y0 + (y1 - y0) * t), Offset(nx, ny));
      }
    }

    void arc(Offset c, double a0, double a1) {
      const steps = 12;
      for (var i = 0; i <= steps; i++) {
        final a = a0 + (a1 - a0) * i / steps;
        final d = Offset(math.cos(a), math.sin(a));
        push(c + d * rad, d);
      }
    }

    edge(r.left + rad, r.top, r.right - rad, r.top, 0, -1); // atas
    arc(Offset(r.right - rad, r.top + rad), -math.pi / 2, 0); // kanan atas
    edge(r.right, r.top + rad, r.right, r.bottom - rad, 1, 0); // kanan
    arc(Offset(r.right - rad, r.bottom - rad), 0, math.pi / 2); // kanan bawah
    edge(r.right - rad, r.bottom, r.left + rad, r.bottom, 0, 1); // bawah
    arc(
      Offset(r.left + rad, r.bottom - rad),
      math.pi / 2,
      math.pi,
    ); // kiri bawah
    edge(r.left, r.bottom - rad, r.left, r.top + rad, -1, 0); // kiri
    arc(Offset(r.left + rad, r.top + rad), math.pi, math.pi * 1.5); // kiri atas

    final out = Path();
    for (var i = 0; i < pts.length; i++) {
      final wob = math.sin(i * 0.42 + e.time * 5.2) * amp;
      final p = pts[i] + nrm[i] * wob;
      if (i == 0) {
        out.moveTo(p.dx, p.dy);
      } else {
        out.lineTo(p.dx, p.dy);
      }
    }
    out.close();
    return out;
  }

  // ------------------------------------------------------------ riak jelly
  void _drawRipple(Canvas canvas, TontonEngine e) {
    if (e.ripple <= 0.01) return;
    final c = const Rect.fromLTWH(34, 42, 152, 138).center;
    final r = 14 + (1 - e.ripple) * 72;
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = Colors.white.withValues(alpha: e.ripple * 0.32)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 + e.ripple * 3.5,
    );
  }

  // ------------------------------------------------------------ layar
  void _drawScreen(Canvas canvas, TontonEngine e) {
    final screen = RRect.fromRectAndRadius(
      const Rect.fromLTWH(52, 56, 116, 94),
      const Radius.circular(24),
    );

    canvas.drawRRect(
      screen.shift(const Offset(0, 1)),
      Paint()..color = e.color.withValues(alpha: 0.26),
    );
    canvas.drawRRect(screen, Paint()..color = _screen);
    canvas.drawRRect(
      screen,
      Paint()
        ..color = e.color.withValues(alpha: 0.32)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );

    final glare = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(58, 150)
      ..lineTo(96, 56)
      ..lineTo(116, 56)
      ..lineTo(78, 150)
      ..close();
    canvas.drawPath(path, glare);

    // Teks yang "masuk" ke layar TV (kata kunci).
    if (e.screenLines.isNotEmpty) {
      final tp = TextPainter(
        text: TextSpan(
          text: e.screenLines.join('\n'),
          style: const TextStyle(
            color: _face,
            fontSize: 9,
            height: 1.3,
            fontWeight: FontWeight.w700,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 106);
      tp.paint(canvas, Offset(110 - tp.width / 2, 60));
    }
  }

  // ------------------------------------------------------------ wajah
  void _drawFace(Canvas canvas, TontonEngine e) {
    final expr = e.expression;
    final gx = e.gazeX;
    final gy = e.gazeY;
    final blink = e.blink;

    final leftEye = Offset(82 + gx * 0.3, 100 + gy * 0.26);
    final rightEye = Offset(138 + gx * 0.3, 100 + gy * 0.26);
    // Mulut ada di layar, sejajar dengan mata (ala GoSpeak).
    final mouth = Offset(110 + gx * 0.14, 124 + gy * 0.14);

    final eye = Paint()..color = _face;
    final line = Paint()
      ..color = _face
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    switch (expr) {
      case MascotExpression.happy:
        _arcEye(canvas, leftEye, 22, 17, eye);
        _arcEye(canvas, rightEye, 22, 17, eye);
        _blush(canvas);
      case MascotExpression.excited:
        _arcEye(canvas, leftEye, 24, 18, eye);
        _arcEye(canvas, rightEye, 24, 18, eye);
        _sparkle(canvas, const Offset(56, 78));
        _sparkle(canvas, const Offset(166, 74));
        _blush(canvas);
      case MascotExpression.love:
        _heart(canvas, leftEye, 12, eye);
        _heart(canvas, rightEye, 12, eye);
        _blush(canvas);
      case MascotExpression.surprised:
        _openEye(canvas, leftEye, 11, 13 * blink, eye);
        _openEye(canvas, rightEye, 11, 13 * blink, eye);
      case MascotExpression.skeptical:
        _roundEye(canvas, leftEye, 14, 12 * blink, eye);
        _roundEye(canvas, rightEye, 14, 12 * blink, eye);
        _brow(canvas, raisedLeft: true);
      case MascotExpression.smug:
        _liddedEye(canvas, leftEye, 14, 16, eye);
        _liddedEye(canvas, rightEye, 14, 16, eye);
      case MascotExpression.sheepish:
        _roundEye(canvas, leftEye.translate(3, 0), 14, 13 * blink, eye);
        _roundEye(canvas, rightEye.translate(3, 0), 14, 13 * blink, eye);
        _sweat(canvas, const Offset(160, 80));
      case MascotExpression.cheeky:
        _roundEye(canvas, leftEye, 14, 16 * blink, eye);
        _arcEye(canvas, rightEye, 19, 13, eye);
      case MascotExpression.thinking:
        _roundEye(canvas, leftEye.translate(0, -4), 13, 13 * blink, eye);
        _roundEye(canvas, rightEye.translate(0, -4), 13, 13 * blink, eye);
        _brow(canvas, raised: true);
      case MascotExpression.talking:
        _roundEye(canvas, leftEye, 14, 16 * blink, eye);
        _roundEye(canvas, rightEye, 14, 16 * blink, eye);
      case MascotExpression.sad:
        _droopyEye(canvas, leftEye, eye);
        _droopyEye(canvas, rightEye, eye);
        _sweat(canvas, const Offset(160, 80));
      case MascotExpression.devastated:
        _closedEye(canvas, leftEye, eye);
        _closedEye(canvas, rightEye, eye);
        _tear(canvas, leftEye.translate(-5, 6));
        _tear(canvas, rightEye.translate(5, 6));
      case MascotExpression.wince:
        _squeezeEye(canvas, leftEye, eye);
        _squeezeEye(canvas, rightEye, eye);
      case MascotExpression.annoyed:
        _roundEye(canvas, leftEye, 14, 11 * blink, eye);
        _roundEye(canvas, rightEye, 14, 11 * blink, eye);
        _angryBrow(canvas);
      case MascotExpression.angry:
        _roundEye(canvas, leftEye, 14, 12 * blink, eye);
        _roundEye(canvas, rightEye, 14, 12 * blink, eye);
        _angryBrow(canvas);
        _angerMark(canvas, const Offset(170, 70));
      case MascotExpression.furious:
        _roundEye(canvas, leftEye, 14, 12 * blink, eye);
        _roundEye(canvas, rightEye, 14, 12 * blink, eye);
        _angryBrow(canvas);
        _angerMark(canvas, const Offset(170, 70));
        _steam(canvas, const Offset(64, 60));
      case MascotExpression.horrified:
        final shake = math.sin(e.time * 40) * 1.8;
        _openEye(canvas, leftEye.translate(shake, 0), 11, 14, eye);
        _openEye(canvas, rightEye.translate(shake, 0), 11, 14, eye);
      case MascotExpression.unamused:
        _liddedEye(canvas, leftEye, 14, 16, eye);
        _liddedEye(canvas, rightEye, 14, 16, eye);
      case MascotExpression.asleep:
        _closedEye(canvas, leftEye, eye);
        _closedEye(canvas, rightEye, eye);
        _zzz(canvas, const Offset(158, 76));
      case MascotExpression.neutral:
        _roundEye(canvas, leftEye, 14, 16 * blink, eye);
        _roundEye(canvas, rightEye, 14, 16 * blink, eye);
        _eyeHighlight(canvas, leftEye);
        _eyeHighlight(canvas, rightEye);
    }

    // ---------------- mulut di layar ----------------
    // Kalau lagi nelan, mulut paksa kebuka lebar (O).
    if (e.gulp > 0.25) {
      _gulpMouth(canvas, mouth, e.gulp, line);
    } else {
      switch (expr) {
        case MascotExpression.happy:
          _smile(canvas, mouth, 24, 15, line);
        case MascotExpression.excited:
          _openSmile(canvas, mouth, 26, 16, line);
        case MascotExpression.love:
          _smile(canvas, mouth, 22, 14, line);
        case MascotExpression.surprised:
          canvas.drawCircle(mouth, 6.5, line..style = PaintingStyle.fill);
        case MascotExpression.skeptical:
          _flatMouth(canvas, mouth, 16, line);
        case MascotExpression.smug:
          _smirk(canvas, mouth, line);
        case MascotExpression.sheepish:
          _wavyMouth(canvas, mouth, line);
        case MascotExpression.cheeky:
          _tongue(canvas, mouth, line);
        case MascotExpression.thinking:
          _flatMouth(canvas, mouth, 12, line);
        case MascotExpression.talking:
          _talkMouth(canvas, mouth, e.mouthOpen, e.mouthRound, line);
        case MascotExpression.sad:
          _frown(canvas, mouth.translate(0, 4), 20, 12, line);
        case MascotExpression.devastated:
          _frown(canvas, mouth.translate(0, 4), 22, 16, line);
        case MascotExpression.wince:
          _wavyMouth(canvas, mouth, line);
        case MascotExpression.annoyed:
          _frown(canvas, mouth, 18, 11, line);
        case MascotExpression.angry:
          _frown(canvas, mouth, 20, 13, line);
        case MascotExpression.furious:
          _frown(canvas, mouth, 20, 15, line);
        case MascotExpression.horrified:
          canvas.drawCircle(mouth, 6.5, line..style = PaintingStyle.fill);
        case MascotExpression.unamused:
          _flatMouth(canvas, mouth, 16, line);
        case MascotExpression.asleep:
          _flatMouth(canvas, mouth.translate(0, 2), 12, line);
        case MascotExpression.neutral:
          _smile(canvas, mouth, 20, 12, line);
      }
    }
  }

  // ------------------------------------------------------------ slot tape
  /// Slot tape ala VCR di bawah layar. Ini BUKAN mulut (mulut ada di layar),
  /// cuma detail retro yang ngeliminasi pas TonTon nelan.
  void _drawTapeSlot(Canvas canvas, TontonEngine e) {
    const slotY = 164.0;
    final open = (e.gulp * 4).clamp(0.0, 4.0);
    const w = 62.0;
    final h = 7.0 + open;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(110, slotY), width: w, height: 14),
        const Radius.circular(7),
      ),
      Paint()
        ..color = e.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: const Offset(110, slotY),
          width: w - 6,
          height: h,
        ),
        Radius.circular(h / 2),
      ),
      Paint()..color = _screen,
    );
  }

  // ---------------- helper mulut (digambar di layar) ----------------
  void _smile(Canvas canvas, Offset c, double w, double h, Paint p) {
    p.style = PaintingStyle.stroke;
    p.strokeWidth = 3.2;
    canvas.drawArc(
      Rect.fromCenter(center: c, width: w, height: h),
      0,
      math.pi,
      false,
      p,
    );
  }

  void _openSmile(Canvas canvas, Offset c, double w, double h, Paint p) {
    p.style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: c, width: w, height: h),
        const Radius.circular(8),
      ),
      p,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: c.translate(0, 3),
          width: w * 0.5,
          height: h * 0.5,
        ),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFFFF6B81),
    );
  }

  /// Mulut paksa kebuka pas nelan.
  void _gulpMouth(Canvas canvas, Offset c, double gulp, Paint p) {
    final r = 6 + gulp * 7;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: c, width: r * 2, height: r * 2),
        Radius.circular(r),
      ),
      Paint()..color = _screen,
    );
    p.style = PaintingStyle.stroke;
    p.strokeWidth = 3;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: c, width: r * 2, height: r * 2),
        Radius.circular(r),
      ),
      p,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: c.translate(0, r * 0.35),
          width: r * 0.9,
          height: r * 0.7,
        ),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFFFF6B81),
    );
  }

  void _frown(Canvas canvas, Offset c, double w, double h, Paint p) {
    p.style = PaintingStyle.stroke;
    p.strokeWidth = 3;
    canvas.drawArc(
      Rect.fromCenter(center: c, width: w, height: h),
      math.pi,
      math.pi,
      false,
      p,
    );
  }

  void _flatMouth(Canvas canvas, Offset c, double w, Paint p) {
    p.style = PaintingStyle.stroke;
    p.strokeWidth = 3;
    canvas.drawLine(c.translate(-w / 2, 0), c.translate(w / 2, 0), p);
  }

  void _smirk(Canvas canvas, Offset c, Paint p) {
    p.style = PaintingStyle.stroke;
    p.strokeWidth = 3.2;
    canvas.drawArc(
      Rect.fromCenter(center: c, width: 20, height: 13),
      0.1,
      math.pi * 0.7,
      false,
      p,
    );
  }

  void _wavyMouth(Canvas canvas, Offset c, Paint p) {
    p.style = PaintingStyle.stroke;
    p.strokeWidth = 3;
    final path = Path()
      ..moveTo(c.dx - 10, c.dy)
      ..quadraticBezierTo(c.dx - 5, c.dy - 5, c.dx, c.dy)
      ..quadraticBezierTo(c.dx + 5, c.dy + 5, c.dx + 10, c.dy);
    canvas.drawPath(path, p);
  }

  void _talkMouth(Canvas canvas, Offset c, double open, double round, Paint p) {
    final h = 3 + open * 11;
    final w = 16 + round * 8;
    p.style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: c, width: w, height: h + 4),
        const Radius.circular(6),
      ),
      p,
    );
    if (open > 0.3) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: c.translate(0, 3),
            width: w * 0.55,
            height: 6 * open,
          ),
          const Radius.circular(4),
        ),
        Paint()..color = const Color(0xFFFF6B81),
      );
    }
  }

  void _tongue(Canvas canvas, Offset c, Paint p) {
    p.style = PaintingStyle.stroke;
    p.strokeWidth = 3;
    canvas.drawArc(
      Rect.fromCenter(center: c, width: 18, height: 11),
      0,
      math.pi,
      false,
      p,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: c.translate(0, 5), width: 8, height: 9),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFFFF6B81),
    );
  }

  // ------------------------------------------------------------ mata
  void _roundEye(Canvas canvas, Offset c, double w, double h, Paint p) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: c, width: w, height: h),
        const Radius.circular(6),
      ),
      p,
    );
  }

  void _openEye(Canvas canvas, Offset c, double r, double h, Paint p) {
    canvas.drawCircle(c, r, p);
    canvas.drawCircle(
      c.translate(2.6, 2.6),
      r * 0.36,
      Paint()..color = _screen,
    );
  }

  void _arcEye(Canvas canvas, Offset c, double w, double h, Paint p) {
    canvas.drawArc(
      Rect.fromCenter(center: c, width: w, height: h),
      math.pi,
      math.pi,
      false,
      p..strokeWidth = 3,
    );
  }

  void _liddedEye(Canvas canvas, Offset c, double w, double h, Paint p) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: c.translate(0, h * 0.22),
          width: w,
          height: h * 0.62,
        ),
        const Radius.circular(5),
      ),
      p,
    );
  }

  void _droopyEye(Canvas canvas, Offset c, Paint p) {
    canvas.drawArc(
      Rect.fromCenter(center: c.translate(0, -2), width: 15, height: 13),
      math.pi,
      math.pi,
      false,
      p..strokeWidth = 3,
    );
  }

  void _closedEye(Canvas canvas, Offset c, Paint p) {
    canvas.drawArc(
      Rect.fromCenter(center: c, width: 17, height: 13),
      0,
      math.pi,
      false,
      p..strokeWidth = 3,
    );
  }

  void _squeezeEye(Canvas canvas, Offset c, Paint p) {
    final line = p..strokeWidth = 3;
    canvas.drawLine(c.translate(-8, -3), c.translate(0, 3), line);
    canvas.drawLine(c.translate(0, 3), c.translate(8, -3), line);
  }

  void _eyeHighlight(Canvas canvas, Offset c) {
    canvas.drawCircle(
      c.translate(-3.4, -4.4),
      2.6,
      // Bayangan lembut di sudut mata (mata TonTon putih, jadi pakai tinta gelap).
      Paint()..color = Colors.black.withValues(alpha: 0.16),
    );
  }

  // ------------------------------------------------------------ alis & afek
  void _brow(Canvas canvas, {bool raised = false, bool raisedLeft = false}) {
    final paint = Paint()
      ..color = _face
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round;
    final dl = raised || raisedLeft ? -6.0 : 0.0;
    final dr = raised || !raisedLeft ? -6.0 : 0.0;
    canvas.drawLine(Offset(74, 88 + dl), Offset(90, 86 + dl), paint);
    canvas.drawLine(Offset(130, 86 + dr), Offset(146, 88 + dr), paint);
  }

  void _angryBrow(Canvas canvas) {
    final paint = Paint()
      ..color = _face
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(72, 94), Offset(92, 86), paint);
    canvas.drawLine(const Offset(148, 94), Offset(128, 86), paint);
  }

  void _blush(Canvas canvas) {
    final paint = Paint()..color = Colors.pinkAccent.withValues(alpha: 0.45);
    canvas.drawCircle(const Offset(66, 122), 5.5, paint);
    canvas.drawCircle(const Offset(154, 122), 5.5, paint);
  }

  void _sweat(Canvas canvas, Offset c) {
    final paint = Paint()..color = _face;
    final path = Path()
      ..moveTo(c.dx, c.dy - 8)
      ..lineTo(c.dx + 6, c.dy + 2)
      ..lineTo(c.dx, c.dy + 10)
      ..lineTo(c.dx - 6, c.dy + 2)
      ..close();
    canvas.drawPath(path, paint);
  }

  void _tear(Canvas canvas, Offset c) {
    final paint = Paint()..color = _face.withValues(alpha: 0.85);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: c, width: 5, height: 10),
        const Radius.circular(2.5),
      ),
      paint,
    );
  }

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

  void _angerMark(Canvas canvas, Offset c) {
    final paint = Paint()
      ..color = const Color(0xFFFF4B3C)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(c.translate(-6, -6), c.translate(-2, -2), paint);
    canvas.drawLine(c.translate(6, -6), c.translate(2, -2), paint);
    canvas.drawLine(c.translate(-6, 6), c.translate(-2, 2), paint);
    canvas.drawLine(c.translate(6, 6), c.translate(2, 2), paint);
  }

  void _steam(Canvas canvas, Offset c) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(c, c.translate(0, -8), paint);
    canvas.drawLine(c.translate(6, 2), c.translate(6, -6), paint);
  }

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

  void _zzz(Canvas canvas, Offset c) {
    final tp = TextPainter(
      text: const TextSpan(
        text: 'z z z',
        style: TextStyle(
          color: _face,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _TvMascotPainter oldDelegate) => true;
}
