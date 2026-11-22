import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/movie.dart';
import '../providers/recommendation_provider.dart';
import '../providers/watchlist_provider.dart';
import '../utils/watchlist_toggler.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/match_badge.dart';
import '../widgets/movie_card.dart';

/// Halaman hasil: daftar film yang direkomendasikan backend.
class ResultsPage extends StatelessWidget {
  const ResultsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RecommendationProvider>();

    return AppScaffold(
      appBar: AppBar(title: const Text(AppStrings.resultsTitle)),
      body: _buildBody(context, provider),
    );
  }

  Widget _buildBody(BuildContext context, RecommendationProvider provider) {
    final watchlist = context.watch<WatchlistProvider>();

    if (provider.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              AppStrings.resultsLoading,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    if (provider.results.isEmpty) {
      return _MessageView(
        icon: provider.errorMessage == null
            ? Icons.movie_outlined
            : Icons.wifi_off_outlined,
        message: provider.errorMessage ?? AppStrings.resultsEmpty,
        actionLabel: 'Coba lagi',
        onAction: () => context.read<RecommendationProvider>().search(),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Text(
            '${provider.results.length} film ditemukan',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            itemCount: provider.results.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final movie = provider.results[index];
              return MovieCard(
                movie: movie,
                rank: index + 1,
                isSaved: watchlist.isSaved(movie.movieId),
                onToggleBookmark: () => toggleWatchlist(context, movie),
                onTap: () => _openDetail(context, movie),
              );
            },
          ),
        ),
      ],
    );
  }

  void _openDetail(BuildContext context, Movie movie) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => DetailPage(movie: movie)));
  }
}

/// Halaman detail satu film.
class DetailPage extends StatelessWidget {
  final Movie movie;

  const DetailPage({super.key, required this.movie});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        title: Text(movie.titleWithYear),
        actions: [
          IconButton(
            tooltip: 'Tonton nanti',
            icon: Icon(
              context.watch<WatchlistProvider>().isSaved(movie.movieId)
                  ? Icons.bookmark
                  : Icons.bookmark_border,
            ),
            onPressed: () => _toggleBookmark(context, movie),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PosterHero(movie: movie),
            const SizedBox(height: 20),
            Row(
              children: [
                Text(
                  movie.rating?.toStringAsFixed(1) ?? '-',
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.star, color: AppColors.accent, size: 22),
                const Spacer(),
                if (movie.matchPercent != null)
                  MatchBadge(value: movie.matchPercent),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${movie.year ?? '-'} - ${Formatters.runtime(movie.runtime)} - ${movie.certificate}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 6),
            Text(
              '${Formatters.votes(movie.votes)} votes',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            if (movie.genre.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: movie.genre
                    .map(
                      (g) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.outline),
                        ),
                        child: Text(g, style: const TextStyle(fontSize: 12)),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 20),
            ],
            const Text(
              'Sinopsis',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              movie.description.isEmpty
                  ? 'Sinopsis nggak tersedia di dataset.'
                  : movie.description,
              style: const TextStyle(height: 1.5),
            ),
            const SizedBox(height: 24),
            const Text(
              'Kru',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text('Sutradara: ${movie.director}'),
            const SizedBox(height: 4),
            Text(
              movie.stars.isEmpty
                  ? 'Pemeran: -'
                  : 'Pemeran: ${movie.stars.join(', ')}',
            ),
          ],
        ),
      ),
    );
  }

  /// Tambah/hapus film dari watchlist, lalu kasih feedback ke user.
  void _toggleBookmark(BuildContext context, Movie movie) {
    toggleWatchlist(context, movie);
  }
}

/// Hero poster besar (placeholder, karena dataset nggak punya URL poster).
class _PosterHero extends StatelessWidget {
  final Movie movie;

  const _PosterHero({required this.movie});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 240,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppColors.accentGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Text(
          movie.movieName.isEmpty
              ? '?'
              : movie.movieName.substring(0, 1).toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 72,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

/// Tampilan pesan kosong / error dengan tombol aksi.
class _MessageView extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _MessageView({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
