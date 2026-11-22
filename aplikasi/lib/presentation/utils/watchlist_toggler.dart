import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_strings.dart';
import '../../domain/entities/movie.dart';
import '../providers/watchlist_provider.dart';

/// Toggle watchlist lalu kasih feedback snackbar.
///
/// Dipakai di kartu rekomendasi & halaman detail supaya perilakunya konsisten.
void toggleWatchlist(BuildContext context, Movie movie) {
  final provider = context.read<WatchlistProvider>();
  final wasSaved = provider.isSaved(movie.movieId);
  provider.toggle(movie);

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        wasSaved ? AppStrings.watchlistRemoved : AppStrings.watchlistSaved,
      ),
      duration: const Duration(seconds: 2),
    ),
  );
}
