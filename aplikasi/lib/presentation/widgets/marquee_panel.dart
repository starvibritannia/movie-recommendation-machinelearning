import 'dart:math' as math;
import 'dart:ui' show BlurStyle, ImageFilter, MaskFilter;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Panel gaya papan marquee bioskop.
///
/// Bingkai lampu-lampu kecil yang menyala mengelilingi panel kaca, judul
/// huruf terpisah (letterspaced) bergradasi, dan subtitle kecil. Dipakai
/// sebagai wadah menu genre, slider, dan kata kunci supaya bahasananya
/// konsisten: elegan, fancy, dan nyatu sama identitas sinema NeVie.
class MarqueePanel extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? footer;

  /// Kalau true, [child] dibungkus area scroll supaya panel nggak overflow
  /// di layar pendek. Footer tetap nempel di bawah.
  final bool scrollable;

  /// Widget sudut (misal tiket) yang menempel di pojok kanan atas panel.
  final Widget? cornerBadge;

  final EdgeInsetsGeometry padding;

  const MarqueePanel({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.footer,
    this.scrollable = false,
    this.cornerBadge,
    this.padding = const EdgeInsets.fromLTRB(18, 16, 18, 14),
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: CustomPaint(
              painter: const _MarqueeFramePainter(),
              child: Padding(
                padding: padding,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MarqueeTitle(title: title, subtitle: subtitle),
                    const SizedBox(height: 12),
                    if (scrollable)
                      Flexible(child: SingleChildScrollView(child: child))
                    else
                      child,
                    if (footer != null) ...[
                      const SizedBox(height: 12),
                      footer!,
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        if (cornerBadge != null)
          Positioned(top: -15, right: 14, child: cornerBadge!),
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

/// Bingkai marquee: isi kaca, garis tepi, dan lampu-lampu kecil yang menyala
/// di sepanjang tepi (dihitung dari ukuran panel, bukan jumlah tetap).
class _MarqueeFramePainter extends CustomPainter {
  const _MarqueeFramePainter();

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

    final glow = Paint()
      ..color = AppColors.accentLight.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);
    final bulb = Paint()..color = AppColors.accentLight;

    for (var i = 0; i < nH; i++) {
      final t = nH == 1 ? 0.5 : i / (nH - 1);
      final x = rect.left + t * rect.width;
      canvas.drawCircle(Offset(x, rect.top), 3.4, glow);
      canvas.drawCircle(Offset(x, rect.top), 1.8, bulb);
      canvas.drawCircle(Offset(x, rect.bottom), 3.4, glow);
      canvas.drawCircle(Offset(x, rect.bottom), 1.8, bulb);
    }
    for (var i = 1; i < nV - 1; i++) {
      final t = i / (nV - 1);
      final y = rect.top + t * rect.height;
      canvas.drawCircle(Offset(rect.left, y), 3.4, glow);
      canvas.drawCircle(Offset(rect.left, y), 1.8, bulb);
      canvas.drawCircle(Offset(rect.right, y), 3.4, glow);
      canvas.drawCircle(Offset(rect.right, y), 1.8, bulb);
    }
  }

  @override
  bool shouldRepaint(covariant _MarqueeFramePainter oldDelegate) => false;
}
