import 'package:flutter/material.dart';

/// Design token warna NeVie — **Jelly Midnight**.
///
/// Gelap sinematik yang sedikit dihangatkan, panel kaca transparan, aksen
/// oranye madu (identitas TonTon), plus glow ambient es.
/// TonTon sebagai aksen sekunder.
class AppColors {
  AppColors._();

  // ---------------- background ----------------
  /// Dasar paling gelap aplikasi.
  static const Color background = Color(0xFF0C1015);

  /// Nada lebih terang, dipakai di ujung gradien background.
  static const Color backgroundAlt = Color(0xFF151A21);

  // ---------------- permukaan ----------------
  /// Permukaan solid (jarang dipakai, semua kartu idealnya glass).
  static const Color surface = Color(0xFF171C24);
  static const Color surfaceVariant = Color(0xFF1E242E);

  /// Isi panel kaca (putih 5%).
  static const Color glass = Color(0x0DFFFFFF);

  /// Isi panel kaca yang sedikit lebih tegas (putih 7%).
  static const Color glassStrong = Color(0x12FFFFFF);

  /// Garis tepi panel kaca (putih 14%) — sedikit lebih menyala biar "jelly".
  static const Color glassBorder = Color(0x24FFFFFF);

  // ---------------- aksen ----------------
  /// Oranye madu utama (jelly, tidak neon).
  static const Color accent = Color(0xFFFF8A3D);

  /// Oranye-coral, ujung gradien.
  static const Color accentAlt = Color(0xFFFF5C4D);

  /// Oranye terang, awal gradien (dipakai di badge & chip).
  static const Color accentLight = Color(0xFFFFB765);

  /// Kuning badge popular (dipakai label "10k+", dst).
  static const Color gold = Color(0xFFFFD98A);

  /// Glow ambient es (wajah TonTon sekarang putih; ini murni aksen latar).
  static const Color tealGlow = Color(0xFF7DF3FF);

  // ---------------- teks ----------------
  static const Color textPrimary = Color(0xFFF7F5F1);
  static const Color textSecondary = Color(0xFF9AA4B0);

  // ---------------- garis & status ----------------
  static const Color outline = Color(0x1AFFFFFF);
  static const Color success = Color(0xFF6FE3B0);
  static const Color danger = Color(0xFFFF6B6B);

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
