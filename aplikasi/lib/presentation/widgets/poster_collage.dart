import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Poster film yang dipakai sebagai latar splash.
///
/// Disimpan sebagai **aset lokal** (bukan diunduh saat runtime) supaya langsung
/// tampil saat splash dibuka, tanpa menunggu jaringan.
const List<({String asset, String title})> kSplashPosters = [
  (asset: 'assets/splash_posters/p01.jpg', title: 'Inception'),
  (asset: 'assets/splash_posters/p02.jpg', title: 'Interstellar'),
  (asset: 'assets/splash_posters/p03.jpg', title: 'The Dark Knight'),
  (asset: 'assets/splash_posters/p04.jpg', title: 'The Shawshank Redemption'),
  (asset: 'assets/splash_posters/p05.jpg', title: 'Fight Club'),
  (asset: 'assets/splash_posters/p06.jpg', title: 'Forrest Gump'),
  (asset: 'assets/splash_posters/p07.jpg', title: 'Avengers: Endgame'),
  (asset: 'assets/splash_posters/p08.jpg', title: 'The Prestige'),
  (
    asset: 'assets/splash_posters/p09.jpg',
    title: 'The Lord of the Rings: The Return of the King',
  ),
  (
    asset: 'assets/splash_posters/p10.jpg',
    title: 'The Lord of the Rings: The Fellowship of the Ring',
  ),
  (asset: 'assets/splash_posters/p11.jpg', title: 'Gladiator'),
  (asset: 'assets/splash_posters/p12.jpg', title: 'WALL-E'),
  (asset: 'assets/splash_posters/p13.jpg', title: 'Whiplash'),
  (asset: 'assets/splash_posters/p14.jpg', title: 'Django Unchained'),
];

/// Blok mosaik dalam satuan sel grid 4 x 6.
/// Format: (kolom, baris, lebar, tinggi). Semua sel harus terisi penuh.
const List<(int, int, int, int)> _blocks = [
  (0, 0, 2, 2),
  (2, 0, 2, 2),
  (0, 2, 1, 2),
  (1, 2, 1, 2),
  (2, 2, 2, 1),
  (2, 3, 2, 1),
  (0, 4, 2, 1),
  (2, 4, 2, 1),
  (0, 5, 1, 1),
  (1, 5, 1, 1),
  (2, 5, 1, 1),
  (3, 5, 1, 1),
];

/// Latar splash: mosaik poster yang **mengisi seluruh layar** tanpa celah.
///
/// Tiap poster dipotong (`BoxFit.cover`) sesuai bloknya, jadi nggak ada area
/// kosong dan nggak ada distorsi. Di atasnya ada scrim + vignette supaya konten
/// (logo & loader) tetap terbaca.
class PosterCollage extends StatelessWidget {
  const PosterCollage({super.key});

  @override
  Widget build(BuildContext context) {
    const cols = 4.0;
    const rows = 6.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cellW = constraints.maxWidth / cols;
        final cellH = constraints.maxHeight / rows;

        return Stack(
          fit: StackFit.expand,
          children: [
            for (var i = 0; i < _blocks.length; i++)
              Positioned(
                left: _blocks[i].$1 * cellW,
                top: _blocks[i].$2 * cellH,
                width: _blocks[i].$3 * cellW,
                height: _blocks[i].$4 * cellH,
                child: _PosterTile(
                  asset: kSplashPosters[i % kSplashPosters.length].asset,
                  title: kSplashPosters[i % kSplashPosters.length].title,
                ),
              ),

            // Scrim gelap: lebih pekat di tengah biar konten menonjol.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.5, 1.0],
                  colors: [
                    Color(0x8C0C1015),
                    Color(0xE60C1015),
                    Color(0x8C0C1015),
                  ],
                ),
              ),
            ),
            // Vignette biar sudut tidak terlalu tajam.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.15,
                  colors: [Color(0x00000000), Color(0x590C1015)],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PosterTile extends StatelessWidget {
  final String asset;
  final String title;

  const _PosterTile({required this.asset, required this.title});

  @override
  Widget build(BuildContext context) {
    final fallback = DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surfaceVariant, AppColors.surface],
        ),
        border: Border.all(color: AppColors.glassBorder),
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Image.asset(
        asset,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      ),
    );
  }
}
