import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Wordmark "NeVie" bercahaya.
///
/// "Ne" putih susu dengan glow putih lembut, "Vie" diisi gradien oranye madu
/// (#FFB765 → #FF8A3D → #FF5C4D) dengan glow oranye. Dipakai di header/app bar
/// dan halaman splash.
class Wordmark extends StatelessWidget {
  /// Ukuran teks wordmark.
  final double fontSize;

  /// Tampilkan tagline "NEXT MOVIE" + garis gradien di bawahnya (buat splash).
  final bool showTagline;

  const Wordmark({super.key, this.fontSize = 20, this.showTagline = false});

  @override
  Widget build(BuildContext context) {
    final letterSpacing = -fontSize * 0.033;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            // "Ne" — putih susu bercahaya.
            Text(
              'Ne',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: fontSize,
                fontWeight: FontWeight.w800,
                letterSpacing: letterSpacing,
                height: 1,
                shadows: [
                  Shadow(
                    color: Colors.white.withValues(alpha: 0.5),
                    blurRadius: fontSize * 0.42,
                  ),
                ],
              ),
            ),
            // "Vie" — gradien oranye + glow.
            _GradientGlowText(
              text: 'Vie',
              fontSize: fontSize,
              letterSpacing: letterSpacing,
            ),
          ],
        ),
        if (showTagline) ...[
          SizedBox(height: fontSize * 0.16),
          Text(
            'NEXT MOVIE',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: fontSize * 0.2,
              fontWeight: FontWeight.w600,
              letterSpacing: fontSize * 0.2 * 0.42,
            ),
          ),
          SizedBox(height: fontSize * 0.2),
          Container(
            height: 3,
            width: fontSize * 2.5,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: AppColors.accentGradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.55),
                  blurRadius: 12,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Teks gradien dengan glow: lapisan blur di belakang + lapisan tajam di depan.
class _GradientGlowText extends StatelessWidget {
  final String text;
  final double fontSize;
  final double letterSpacing;

  const _GradientGlowText({
    required this.text,
    required this.fontSize,
    required this.letterSpacing,
  });

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      color: Colors.white,
      fontSize: fontSize,
      fontWeight: FontWeight.w800,
      letterSpacing: letterSpacing,
      height: 1,
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        ImageFiltered(
          imageFilter: ImageFilter.blur(
            sigmaX: fontSize * 0.26,
            sigmaY: fontSize * 0.26,
          ),
          child: ShaderMask(
            shaderCallback: (r) => AppColors.accentGradient.createShader(r),
            child: Text(text, style: style),
          ),
        ),
        ShaderMask(
          shaderCallback: (r) => AppColors.accentGradient.createShader(r),
          child: Text(text, style: style),
        ),
      ],
    );
  }
}
