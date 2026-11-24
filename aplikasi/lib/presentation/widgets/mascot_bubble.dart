import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Gelembung chat maskot: panel gelap keemasan yang duduk di bawah sorotan
/// hangat dari atas.
///
/// Sengaja ringkas dan tanpa ekor/panah — TonTon "menyalakan sorotnya", jadi
/// kesan keluar dari maskot tetap terasa lewat animasi naik + cahayanya.
/// Teks mengetik huruf demi huruf dengan kursor berkedip.
class MascotBubble extends StatefulWidget {
  final String text;

  const MascotBubble({super.key, required this.text});

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

    // Animasi "sorosan nyala": naik pelan + membesar dari sisi bawah.
    return FadeTransition(
      opacity: CurvedAnimation(parent: _enter, curve: Curves.easeOut),
      child: ScaleTransition(
        alignment: Alignment.bottomCenter,
        scale: Tween<double>(
          begin: 0.78,
          end: 1,
        ).animate(CurvedAnimation(parent: _enter, curve: Curves.easeOutBack)),
        child: SlideTransition(
          position:
              Tween<Offset>(
                begin: const Offset(0, 0.24),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: _enter, curve: Curves.easeOutCubic),
              ),
          child: Align(
            alignment: Alignment.topCenter,
            widthFactor: 1,
            heightFactor: 1,
            child: AnimatedBuilder(
              animation: _float,
              builder: (context, child) => Transform.translate(
                offset: Offset(0, -2 + 4 * _float.value),
                child: child,
              ),
              child: _SpotlightBubble(text: shown, typing: typing),
            ),
          ),
        ),
      ),
    );
  }
}

/// Sorotan hangat + panel gelap tempat teksnya muncul.
class _SpotlightBubble extends StatelessWidget {
  final String text;
  final bool typing;

  const _SpotlightBubble({required this.text, required this.typing});

  @override
  Widget build(BuildContext context) {
    return Container(
      // Ruang di atas panel buat cahaya sorotannya.
      padding: const EdgeInsets.only(top: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: RadialGradient(
          center: Alignment.topCenter,
          radius: 1.15,
          colors: [
            const Color(0xFFFFE3B4).withValues(alpha: 0.34),
            const Color(0xFFFFE3B4).withValues(alpha: 0),
          ],
        ),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 232),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0E13).withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFFFD6A0).withValues(alpha: 0.45),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFC482).withValues(alpha: 0.22),
              blurRadius: 22,
              spreadRadius: 1,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: Colors.white,
                ),
              ),
            ),
            if (typing) ...[const SizedBox(width: 3), const _Caret()],
          ],
        ),
      ),
    );
  }
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
