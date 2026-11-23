import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'glass_card.dart';

/// Arah ekor bubble: ke bawah (maskot di bawah), ke kiri (maskot di kiri),
/// atau ke atas (maskot di atas bubble).
enum BubbleTail { bottom, left, top }

/// Gelembung chat maskot yang muncul dari maskotnya.
///
/// Bubble diletakkan di samping maskot dengan ekor menunjuk ke arahnya, jadi
/// kesan "keluar dari maskot" terasa nyata. Teks mengetik huruf demi huruf
/// dengan kursor berkedip.
class MascotBubble extends StatefulWidget {
  final String text;
  final BubbleTail tail;

  const MascotBubble({
    super.key,
    required this.text,
    this.tail = BubbleTail.bottom,
  });

  @override
  State<MascotBubble> createState() => _MascotBubbleState();
}

class _MascotBubbleState extends State<MascotBubble>
    with TickerProviderStateMixin {
  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );

  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  Timer? _timer;
  int _shown = 0;

  @override
  void initState() {
    super.initState();
    _enter.forward();
    _float.repeat(reverse: true);
    _startTyping();
  }

  @override
  void didUpdateWidget(covariant MascotBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _startTyping();
    }
  }

  void _startTyping() {
    _timer?.cancel();
    setState(() => _shown = 0);
    _timer = Timer.periodic(const Duration(milliseconds: 14), (timer) {
      if (!mounted) return;
      setState(() => _shown++);
      if (_shown >= widget.text.length) {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _enter.dispose();
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shown = widget.text.substring(0, _shown.clamp(0, widget.text.length));
    final typing = _shown < widget.text.length;
    final fromLeft = widget.tail == BubbleTail.left;
    final fromTop = widget.tail == BubbleTail.top;
    final Alignment origin = fromLeft
        ? Alignment.centerLeft
        : fromTop
        ? Alignment.bottomCenter
        : Alignment.topCenter;
    final Offset slideBegin = fromLeft
        ? const Offset(-0.25, 0)
        : fromTop
        ? const Offset(0, 0.3)
        : const Offset(0, 0.3);

    final card = GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      radius: 18,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 280),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: Text(
                shown,
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
            ),
            if (typing) ...[const SizedBox(width: 3), const _Caret()],
          ],
        ),
      ),
    );

    final bubble = Stack(
      clipBehavior: Clip.none,
      children: [
        card,
        if (widget.tail == BubbleTail.bottom)
          Positioned(
            left: 8,
            top: -1,
            child: const CustomPaint(
              size: Size(26, 12),
              painter: _BubbleTailPainter.down(),
            ),
          ),
        if (widget.tail == BubbleTail.top)
          Positioned(
            left: 8,
            bottom: -1,
            child: const CustomPaint(
              size: Size(26, 12),
              painter: _BubbleTailPainter.down(),
            ),
          ),
        if (widget.tail == BubbleTail.left)
          const Positioned(
            left: -13,
            top: 26,
            child: CustomPaint(
              size: Size(14, 18),
              painter: _BubbleTailPainter.left(),
            ),
          ),
      ],
    );

    // Animasi "keluar dari maskot": slide + scale mulai dari sisi maskot.
    return FadeTransition(
      opacity: CurvedAnimation(parent: _enter, curve: Curves.easeOut),
      child: ScaleTransition(
        alignment: origin,
        scale: Tween<double>(
          begin: 0.72,
          end: 1,
        ).animate(CurvedAnimation(parent: _enter, curve: Curves.easeOutBack)),
        child: SlideTransition(
          position: Tween<Offset>(begin: slideBegin, end: Offset.zero).animate(
            CurvedAnimation(parent: _enter, curve: Curves.easeOutCubic),
          ),
          child: Align(
            alignment: fromLeft
                ? Alignment.centerLeft
                : fromTop
                ? Alignment.bottomCenter
                : Alignment.topLeft,
            widthFactor: 1,
            heightFactor: 1,
            child: AnimatedBuilder(
              animation: _float,
              builder: (context, child) => Transform.translate(
                offset: Offset(0, -2 + 4 * _float.value),
                child: child,
              ),
              child: bubble,
            ),
          ),
        ),
      ),
    );
  }
}

/// Ekor bubble. Dua arah: ke bawah (segitiga) dan ke kiri.
class _BubbleTailPainter extends CustomPainter {
  final BubbleTail tail;

  const _BubbleTailPainter.down() : tail = BubbleTail.bottom;
  const _BubbleTailPainter.left() : tail = BubbleTail.left;

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..color = const Color(0x14FFFFFF);
    final border = Paint()
      ..color = const Color(0x1AFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    if (tail == BubbleTail.bottom) {
      final path = Path()
        ..moveTo(2, 0)
        ..lineTo(22, 0)
        ..lineTo(8, size.height)
        ..close();
      canvas.drawPath(path, fill);
      canvas.drawLine(const Offset(2, 0), Offset(8, size.height), border);
      canvas.drawLine(const Offset(22, 0), Offset(8, size.height), border);
      return;
    }

    final path = Path()
      ..moveTo(0, 4)
      ..lineTo(0, size.height - 4)
      ..lineTo(size.width, size.height / 2)
      ..close();
    canvas.drawPath(path, fill);
    canvas.drawLine(
      const Offset(0, 4),
      Offset(size.width, size.height / 2),
      border,
    );
    canvas.drawLine(
      Offset(0, size.height - 4),
      Offset(size.width, size.height / 2),
      border,
    );
  }

  @override
  bool shouldRepaint(covariant _BubbleTailPainter oldDelegate) =>
      oldDelegate.tail != tail;
}

/// Kursor kecil yang berdenyut saat teks lagi mengetik.
class _Caret extends StatefulWidget {
  const _Caret();

  @override
  State<_Caret> createState() => _CaretState();
}

class _CaretState extends State<_Caret> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _c,
      child: Container(
        width: 2,
        height: 15,
        margin: const EdgeInsets.only(bottom: 2),
        color: AppColors.accent,
      ),
    );
  }
}
