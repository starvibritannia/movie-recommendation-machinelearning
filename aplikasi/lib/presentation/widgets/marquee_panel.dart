import 'dart:math' as math;
import 'dart:ui' show BlurStyle, ImageFilter, MaskFilter;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Panel gaya papan marquee bioskop.
///
/// Bingkai lampu-lampu kecil mengelilingi panel kaca, judul huruf terpisah
/// (letterspaced) bergradasi, dan subtitle kecil. Dipakai sebagai wadah menu
/// genre, slider, dan kata kunci supaya bahasanya konsisten.
///
/// [animateIn] menyalakan lampu satu per satu saat panel muncul, [chase]
/// menjalankan efek cahaya berjalan di bingkai (dipakai saat panel menghilang).
class MarqueePanel extends StatefulWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? footer;

  /// Kalau true, [child] dibungkus area scroll supaya panel nggak overflow
  /// di layar pendek. Footer tetap nempel di bawah.
  final bool scrollable;

  /// Widget sudut (misal tiket) yang menempel di pojok kanan atas panel.
  final Widget? cornerBadge;

  final bool animateIn;
  final bool chase;
  final EdgeInsetsGeometry padding;

  const MarqueePanel({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.footer,
    this.scrollable = false,
    this.cornerBadge,
    this.animateIn = false,
    this.chase = false,
    this.padding = const EdgeInsets.fromLTRB(18, 16, 18, 14),
  });

  @override
  State<MarqueePanel> createState() => _MarqueePanelState();
}

class _MarqueePanelState extends State<MarqueePanel>
    with TickerProviderStateMixin {
  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late final AnimationController _chase = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animateIn) _enter.forward();
  }

  @override
  void didUpdateWidget(covariant MarqueePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.chase && !oldWidget.chase) _chase.forward(from: 0);
  }

  @override
  void dispose() {
    _enter.dispose();
    _chase.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: AnimatedBuilder(
              animation: Listenable.merge([_enter, _chase]),
              builder: (context, _) => CustomPaint(
                painter: _MarqueeFramePainter(
                  enterT: widget.animateIn ? _enter.value : null,
                  chaseT: widget.chase ? _chase.value : null,
                ),
                child: Padding(
                  padding: widget.padding,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _MarqueeTitle(
                        title: widget.title,
                        subtitle: widget.subtitle,
                      ),
                      const SizedBox(height: 12),
                      if (widget.scrollable)
                        Flexible(
                          child: SingleChildScrollView(child: widget.child),
                        )
                      else
                        widget.child,
                      if (widget.footer != null) ...[
                        const SizedBox(height: 12),
                        widget.footer!,
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (widget.cornerBadge != null)
          Positioned(top: -15, right: 14, child: widget.cornerBadge!),
      ],
    );
  }
}

/// Judul marquee: gradien putih-ke-oranye dengan glow halus.
class _MarqueeTitle extends StatelessWidget {
  final String title;
  final String? subtitle;

  const _MarqueeTitle({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShaderMask(
          shaderCallback: (r) => const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Colors.white, AppColors.accentLight, AppColors.accent],
          ).createShader(r),
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.26,
              height: 1.1,
            ),
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 5),
          Text(
            subtitle!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 9.5,
              letterSpacing: 0.16,
              height: 1.3,
            ),
          ),
        ],
      ],
    );
  }
}

/// Bingkai marquee: isi kaca, garis tepi, dan lampu-lampu kecil di sepanjang
/// tepi. Lampunya bisa menyala berurutan ([enterT]) atau berjalan ([chaseT]).
class _MarqueeFramePainter extends CustomPainter {
  final double? enterT;
  final double? chaseT;

  const _MarqueeFramePainter({this.enterT, this.chaseT});

  static const Color _off = Color(0x2EFFFFFF);

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(24),
    );

    canvas.drawRRect(rrect, Paint()..color = AppColors.glassStrong);
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = AppColors.glassBorder,
    );

    const inset = 7.0;
    final rect = Rect.fromLTWH(
      inset,
      inset,
      math.max(0, size.width - inset * 2),
      math.max(0, size.height - inset * 2),
    );

    final nH = (rect.width / 34).round().clamp(4, 18);
    // Sisi vertikal dilewati ujungnya supaya lampu sudut nggak dobel.
    final nV = (rect.height / 34).round().clamp(8, 26);

    final positions = <Offset>[];
    for (var i = 0; i < nH; i++) {
      final t = nH == 1 ? 0.5 : i / (nH - 1);
      final x = rect.left + t * rect.width;
      positions.add(Offset(x, rect.top));
      positions.add(Offset(x, rect.bottom));
    }
    for (var i = 1; i < nV - 1; i++) {
      final t = i / (nV - 1);
      final y = rect.top + t * rect.height;
      positions.add(Offset(rect.left, y));
      positions.add(Offset(rect.right, y));
    }

    final total = positions.length;
    for (var i = 0; i < total; i++) {
      _paintBulb(canvas, positions[i], i / total);
    }
  }

  void _paintBulb(Canvas canvas, Offset at, double p) {
    double lit;
    if (chaseT != null) {
      // Cahaya berjalan: ada "kepala" terang yang muter mengelilingi bingkai.
      final d = ((p - chaseT!) % 1.0 + 1.0) % 1.0;
      lit = 0.22 + 0.78 * math.pow(1 - d, 3).clamp(0.0, 1.0);
    } else if (enterT != null) {
      // Nyala satu per satu mengikuti urutan lampu.
      lit = 0.18 + 0.82 * ((enterT! * 1.5 - p * 0.5) * 1.6).clamp(0.0, 1.0);
    } else {
      lit = 1.0;
    }

    final color = Color.lerp(_off, AppColors.accentLight, lit)!;
    canvas.drawCircle(
      at,
      1.4 + 2.4 * lit,
      Paint()
        ..color = color.withValues(alpha: 0.35 * lit)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5),
    );
    canvas.drawCircle(at, 1.7, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _MarqueeFramePainter oldDelegate) =>
      oldDelegate.enterT != enterT || oldDelegate.chaseT != chaseT;
}
