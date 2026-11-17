import 'package:flutter/material.dart';

/// Design token warna, mengikuti Referensi UI 3 (KuKu):
/// dark cinematic dengan aksen oranye, panel gelap semi-transparan,
/// dan glow lembut di background.
class AppColors {
  AppColors._();

  // ---------------- background ----------------
  /// Dasar paling gelap aplikasi.
  static const Color background = Color(0xFF0B0E12);

  /// Nada lebih terang, dipakai di ujung gradien background.
  static const Color backgroundAlt = Color(0xFF12161B);

  // ---------------- permukaan ----------------
  /// Permukaan solid (jarang dipakai, semua kartu idealnya glass).
  static const Color surface = Color(0xFF12161B);
  static const Color surfaceVariant = Color(0xFF1A1F26);

  /// Isi panel kaca (putih 6%).
  static const Color glass = Color(0x0FFFFFFF);

  /// Isi panel kaca yang sedikit lebih tegas (putih 8%).
  static const Color glassStrong = Color(0x14FFFFFF);

  /// Garis tepi panel kaca (putih 10%).
  static const Color glassBorder = Color(0x1AFFFFFF);

  // ---------------- aksen ----------------
  /// Oranye utama.
  static const Color accent = Color(0xFFFF7A18);

  /// Oranye-coral, ujung gradien.
  static const Color accentAlt = Color(0xFFFF4D2D);

  /// Oranye terang, awal gradien (dipakai di badge & chip).
  static const Color accentLight = Color(0xFFFFB03A);

  /// Kuning badge popular (dipakai label "10k+", dst).
  static const Color gold = Color(0xFFFFD23F);

  /// Teal untuk glow ambient di background.
  static const Color tealGlow = Color(0xFF2BB3C0);

  // ---------------- teks ----------------
  static const Color textPrimary = Color(0xFFF5F7FA);
  static const Color textSecondary = Color(0xFF8A939E);

  // ---------------- garis & status ----------------
  static const Color outline = Color(0x14FFFFFF);
  static const Color success = Color(0xFF4CCF8B);
  static const Color danger = Color(0xFFFF5A5A);

  // ---------------- gradien ----------------
  /// Gradien aksen oranye, dipakai tombol & highlight.
  static const LinearGradient accentGradient = LinearGradient(
    colors: [accentLight, accent, accentAlt],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Gradien latar aplikasi, gelap di bawah sedikit lebih terang.
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [backgroundAlt, background],
  );
}
