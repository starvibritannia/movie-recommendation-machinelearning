import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/movie.dart';
import 'glass_card.dart';
import 'match_badge.dart';

/// Kartu film di halaman hasil/trending/watchlist.
///
/// Wadahnya GlassCard (transparan + blur), poster tetap gradien oranye karena
/// dataset nggak menyediakan URL gambar.
class MovieCard extends StatelessWidget {
  final Movie movie;
  final int rank;
  final VoidCallback? onTap;

  /// Status watchlist (dipakai di kartu rekomendasi).
  final bool isSaved;

  /// Kalau diisi, kartu menampilkan tombol bookmark.
  final VoidCallback? onToggleBookmark;

  const MovieCard({
    super.key,
    required this.movie,
    required this.rank,
    this.onTap,
    this.isSaved = false,
    this.onToggleBookmark,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PosterPlaceholder(title: movie.movieName),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '#$rank',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        movie.movieName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${movie.year ?? '-'} - ${Formatters.runtime(movie.runtime)} - ${movie.certificate}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                if (movie.genre.isNotEmpty)
                  Text(
                    movie.genre.join(', '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    MatchBadge(value: movie.matchPercent),
                    const SizedBox(width: 8),
                    if (movie.clusterLabel != null)
                      _ClusterBadge(label: movie.clusterLabel!),
                    const Spacer(),
                    if (onToggleBookmark != null) ...[
                      _BookmarkButton(saved: isSaved, onTap: onToggleBookmark!),
                      const SizedBox(width: 8),
                    ],
                    const Icon(Icons.star, size: 16, color: AppColors.accent),
                    const SizedBox(width: 4),
                    Text(
                      movie.rating?.toStringAsFixed(1) ?? '-',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tombol bookmark kecil di kartu film, dengan animasi membesar pas aktif.
class _BookmarkButton extends StatelessWidget {
  final bool saved;
  final VoidCallback onTap;

  const _BookmarkButton({required this.saved, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: AnimatedScale(
          scale: saved ? 1.2 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          child: Icon(
            saved ? Icons.bookmark : Icons.bookmark_border,
            size: 20,
            color: saved ? AppColors.accent : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// Placeholder poster: dataset nggak punya URL gambar, jadi kita tampilkan
/// kotak gradien dengan huruf awal judul. Kalau nanti backend menambah
/// poster_url, cukup ganti widget ini jadi Image.network.
class _PosterPlaceholder extends StatelessWidget {
  final String title;

  const _PosterPlaceholder({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 74,
      height: 104,
      decoration: BoxDecoration(
        gradient: AppColors.accentGradient,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Center(
        child: Text(
          title.isEmpty ? '?' : title.substring(0, 1).toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _ClusterBadge extends StatelessWidget {
  final int label;

  const _ClusterBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.glass,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Text(
        'Cluster $label',
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
      ),
    );
  }
}
