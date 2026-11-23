import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:film_recommendation/data/services/poster_service.dart';
import 'package:film_recommendation/domain/entities/movie.dart';
import 'package:film_recommendation/presentation/widgets/movie_card.dart';

void main() {
  Future<void> pumpCard(WidgetTester tester, Movie movie) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      Provider<PosterService>.value(
        value: PosterService(prefs),
        child: MaterialApp(
          home: Scaffold(
            backgroundColor: const Color(0xFF0C1015),
            body: Center(
              child: SizedBox(
                width: 350,
                child: MovieCard(
                  movie: movie,
                  rank: 1,
                  isSaved: true,
                  onToggleBookmark: () {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Movie movie({int? cluster}) => Movie(
    movieId: 'tt1',
    movieName: 'Inception',
    year: 2010,
    runtime: 148,
    certificate: 'PG-13',
    genre: ['Action', 'Sci-Fi'],
    rating: 8.8,
    matchPercent: 96.4,
    clusterLabel: cluster,
  );

  testWidgets('rating & badge tetap di dalam kartu (watchlist)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await pumpCard(tester, movie(cluster: 2));

    expect(
      tester.takeException(),
      isNull,
      reason: 'kartu tidak boleh overflow',
    );

    final card = tester.getRect(find.byType(MovieCard));
    final rating = tester.getRect(find.text('8.8'));
    final star = tester.getRect(find.byIcon(Icons.star));

    // Rating + bintang harus masuk ke dalam padding kartu.
    expect(rating.right, lessThanOrEqualTo(card.right - 8));
    expect(star.left, greaterThanOrEqualTo(card.left));
    expect(rating.left, greaterThanOrEqualTo(card.left));
  });

  testWidgets('badge match tetap terbaca walau tanpa cluster', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await pumpCard(tester, movie());

    expect(tester.takeException(), isNull);
    expect(find.textContaining('MATCH'), findsOneWidget);
  });
}
