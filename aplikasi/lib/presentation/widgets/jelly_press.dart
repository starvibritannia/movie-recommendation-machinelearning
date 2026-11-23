import 'package:flutter/material.dart';

/// Pembungkus interaksi "jelly": mengecil saat ditekan, lalu memantul balik
/// dengan sedikit overshoot (ala GoSpeak).
///
/// Dipakai di tombol & target sentuh lain supaya umpan baliknya halus dan hidup.
class JellyPress extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  /// Seberapa kecil saat ditekan (0..1), misal 0.06 = mengecil 6%.
  final double pressedScale;

  const JellyPress({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.06,
  });

  @override
  State<JellyPress> createState() => _JellyPressState();
}

class _JellyPressState extends State<JellyPress>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 120),
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _down() {
    _c.animateTo(
      1,
      duration: const Duration(milliseconds: 90),
      curve: Curves.easeOutQuad,
    );
  }

  void _up() {
    _c.animateTo(
      0,
      duration: const Duration(milliseconds: 460),
      curve: Curves.easeOutBack,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) {
        if (widget.onTap != null) _down();
      },
      onTapUp: (_) {
        _up();
        widget.onTap?.call();
      },
      onTapCancel: _up,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) {
          // _c.value bisa sedikit negatif saat dilepas (easeOutBack), jadi
          // skalanya sempat melebihi 1: itu "pantul"-nya.
          final scale = 1 - widget.pressedScale * _c.value;
          return Transform.scale(scale: scale, child: child);
        },
        child: widget.child,
      ),
    );
  }
}
