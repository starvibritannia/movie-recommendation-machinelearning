import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'data/datasources/recommendation_local_datasource.dart';
import 'data/datasources/recommendation_remote_datasource.dart';
import 'data/datasources/watchlist_local_datasource.dart';
import 'data/repositories/recommendation_repository_impl.dart';
import 'domain/repositories/recommendation_repository.dart';
import 'presentation/providers/recommendation_provider.dart';
import 'presentation/providers/watchlist_provider.dart';

void main() {
  runApp(const FilmRecommendationApp());
}

/// Aplikasi root + composition root.
///
/// Di sinilah semua object dirangkai (dependency injection manual). Kalau
/// nanti mau pakai package get_it atau injectable, cukup ubah bagian ini.
class FilmRecommendationApp extends StatelessWidget {
  const FilmRecommendationApp({super.key});

  @override
  Widget build(BuildContext context) {
    final remoteDataSource = RecommendationRemoteDataSource();
    final localDataSource = RecommendationLocalDataSource();
    final watchlistDataSource = WatchlistLocalDataSource();

    final RecommendationRepository repository = RecommendationRepositoryImpl(
      remoteDataSource: remoteDataSource,
      localDataSource: localDataSource,
    );

    return MultiProvider(
      providers: [
        // Data source dipakai bareng oleh repository & halaman trending.
        Provider<RecommendationLocalDataSource>.value(value: localDataSource),
        Provider<WatchlistLocalDataSource>.value(value: watchlistDataSource),

        // State halaman.
        ChangeNotifierProvider(
          create: (_) => RecommendationProvider(repository: repository),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              WatchlistProvider(dataSource: watchlistDataSource)..load(),
        ),
      ],
      child: const MovieApp(),
    );
  }
}
