import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Latar aplikasi: gradien gelap + dua glow lembut (oranye dan teal).
///
/// Gaya ini diambil dari Referensi UI 3: background-nya tidak flat, ada
/// "ambient glow" yang bikin kesan glossy dan berdepth.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(gradient: AppColors.backgroundGradient),
        ),

        // Glow oranye di kanan atas.
        Positioned(
          top: -140,
          right: -110,
          child: _Glow(
            size: 360,
            color: AppColors.accent.withValues(alpha: 0.20),
          ),
        ),

        // Glow teal di kiri bawah.
        Positioned(
          bottom: -170,
          left: -140,
          child: _Glow(
            size: 420,
            color: AppColors.tealGlow.withValues(alpha: 0.15),
          ),
        ),

        // Glow oranye kecil di tengah bawah, biar nggak kosong.
        Positioned(
          bottom: 40,
          right: -80,
          child: _Glow(
            size: 240,
            color: AppColors.accentAlt.withValues(alpha: 0.10),
          ),
        ),
      ],
    );
  }
}

/// Bulatan gradasi radial yang melebar halus sampai transparan.
class _Glow extends StatelessWidget {
  final double size;
  final Color color;

  const _Glow({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    );
  }
}
