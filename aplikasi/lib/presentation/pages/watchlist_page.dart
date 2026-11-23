import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_strings.dart';
import '../../core/constants/app_layout.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/movie.dart';
import '../providers/watchlist_provider.dart';
import '../utils/watchlist_toggler.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/movie_card.dart';
import 'mascot_page.dart';
import 'results_page.dart';

/// Tab 3: koleksi film yang mau ditonton user (watchlist).
///
/// Data disimpan lokal di HP lewat shared_preferences, jadi nggak butuh login
/// dan tetap ada setelah aplikasi ditutup.
class WatchlistPage extends StatelessWidget {
  /// Dipanggil saat user menekan "Cari film dulu". Kalau null, halaman maskot
  /// di-push sebagai route baru (fallback).
  final VoidCallback? onFindFilms;

  const WatchlistPage({super.key, this.onFindFilms});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WatchlistProvider>();

    return AppScaffold(
      appBar: AppBar(title: const Text(AppStrings.tabWatchlist)),
      body: _buildBody(context, provider),
    );
  }

  Widget _buildBody(BuildContext context, WatchlistProvider provider) {
    if (!provider.isLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.movies.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.bookmark_border,
                size: 56,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 16),
              const Text(
                AppStrings.watchlistEmpty,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed:
                    onFindFilms ??
                    () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const MascotPage()),
                      );
                    },
                child: const Text('Cari film dulu'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Text(
            '${provider.count} film tersimpan di HP ini',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, AppLayout.navSpacer),
            itemCount: provider.movies.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final movie = provider.movies[index];
              return Dismissible(
                key: ValueKey(movie.movieId),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: AppColors.danger,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.delete_outline, color: Colors.white),
                ),
                onDismissed: (_) => provider.remove(movie.movieId),
                child: MovieCard(
                  movie: movie,
                  rank: index + 1,
                  isSaved: true,
                  onToggleBookmark: () => toggleWatchlist(context, movie),
                  onTap: () => _openDetail(context, movie),
                ),
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
