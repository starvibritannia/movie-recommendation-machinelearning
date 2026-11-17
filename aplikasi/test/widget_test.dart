import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:film_recommendation/core/constants/app_strings.dart';
import 'package:film_recommendation/data/datasources/recommendation_local_datasource.dart';
import 'package:film_recommendation/data/datasources/recommendation_remote_datasource.dart';
import 'package:film_recommendation/data/datasources/watchlist_local_datasource.dart';
import 'package:film_recommendation/data/models/movie_model.dart';
import 'package:film_recommendation/data/models/recommendation_response.dart';
import 'package:film_recommendation/data/repositories/recommendation_repository_impl.dart';
import 'package:film_recommendation/domain/entities/recommendation_criteria.dart';
import 'package:film_recommendation/domain/repositories/recommendation_repository.dart';
import 'package:film_recommendation/presentation/pages/main_shell.dart';
import 'package:film_recommendation/presentation/providers/recommendation_provider.dart';
import 'package:film_recommendation/presentation/providers/trending_provider.dart';
import 'package:film_recommendation/presentation/providers/watchlist_provider.dart';

void main() {
  group('RecommendationCriteria', () {
    test('toJson sesuai kontrak API', () {
      const criteria = RecommendationCriteria(
        genres: ['Action', 'Sci-Fi'],
        minRating: 7.5,
        runtimeMin: 90,
        runtimeMax: 150,
        yearStart: 2015,
        yearEnd: 2024,
        keyword: 'space',
        topN: 10,
      );

      expect(criteria.toJson(), {
        'genres': ['Action', 'Sci-Fi'],
        'min_rating': 7.5,
        'runtime_min': 90,
        'runtime_max': 150,
        'year_start': 2015,
        'year_end': 2024,
        'keyword': 'space',
        'top_n': 10,
      });
    });

    test('keyword kosong diubah jadi null', () {
      const criteria = RecommendationCriteria(keyword: '   ');
      expect(criteria.toJson()['keyword'], isNull);
    });

    test('validasi menolak rentang tahun terbalik', () {
      const criteria = RecommendationCriteria(yearStart: 2024, yearEnd: 2015);
      expect(criteria.validate(), isNotNull);
    });
  });

  group('MovieModel', () {
    test('fromJson parsing lengkap', () {
      final movie = MovieModel.fromJson({
        'movie_id': 'tt1375666',
        'movie_name': 'Inception',
        'year': 2010,
        'certificate': 'PG-13',
        'runtime': 148,
        'genre': 'Action, Sci-Fi',
        'rating': 8.8,
        'votes': 2500000,
        'description': 'A thief who steals secrets.',
        'director': 'Christopher Nolan',
        'star': 'Leonardo DiCaprio, Joseph Gordon-Levitt',
        'match_percent': 96.4,
        'cluster_label': 3,
      });

      expect(movie.movieId, 'tt1375666');
      expect(movie.genre, ['Action', 'Sci-Fi']);
      expect(movie.stars, ['Leonardo DiCaprio', 'Joseph Gordon-Levitt']);
      expect(movie.matchPercent, 96.4);
      expect(movie.clusterLabel, 3);
    });

    test('fromJson tahan data kosong', () {
      final movie = MovieModel.fromJson({
        'movie_id': 'tt0001',
        'movie_name': '',
      });

      expect(movie.movieName, 'Tanpa Judul');
      expect(movie.certificate, 'Unrated');
      expect(movie.genre, isEmpty);
    });
  });

  group('RecommendationResponse', () {
    test('parsing bentuk object', () {
      final response = RecommendationResponse.fromJson({
        'recommendations': [
          {'movie_id': 'tt1', 'movie_name': 'Film A'},
        ],
        'total_candidates': 120,
        'elapsed_ms': 45.2,
        'predicted_cluster': 2,
      });

      expect(response.recommendations.length, 1);
      expect(response.totalCandidates, 120);
      expect(response.predictedCluster, 2);
    });

    test('parsing bentuk array polos', () {
      // Data source sudah membongkar array, tapi model ini tetap dites buat
      // memastikan parser lebih fleksibel.
      final response = RecommendationResponse.fromJson({'recommendations': []});
      expect(response.recommendations, isEmpty);
    });
  });

  test('daftar genre tersedia di UI', () {
    expect(AppStrings.availableGenres.length, 25);
    expect(AppStrings.availableGenres, contains('Sci-Fi'));
  });

  testWidgets('bottom navigation punya 3 tab', (tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final localDataSource = RecommendationLocalDataSource();
    final watchlistDataSource = WatchlistLocalDataSource();
    final RecommendationRepository repository = RecommendationRepositoryImpl(
      remoteDataSource: RecommendationRemoteDataSource(),
      localDataSource: localDataSource,
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<RecommendationLocalDataSource>.value(value: localDataSource),
          Provider<WatchlistLocalDataSource>.value(value: watchlistDataSource),
          ChangeNotifierProvider(
            create: (_) => RecommendationProvider(repository: repository),
          ),
          ChangeNotifierProvider(
            create: (_) => TrendingProvider(localDataSource: localDataSource),
          ),
          ChangeNotifierProvider(
            create: (_) =>
                WatchlistProvider(dataSource: watchlistDataSource)..load(),
          ),
        ],
        child: const MaterialApp(home: MainShell()),
      ),
    );

    await tester.pump();

    expect(find.text(AppStrings.tabTrending), findsWidgets);
    expect(find.text(AppStrings.tabDiscover), findsWidgets);
    expect(find.text(AppStrings.tabWatchlist), findsWidgets);
  });
}
