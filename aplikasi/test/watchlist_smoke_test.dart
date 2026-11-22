import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:film_recommendation/data/datasources/watchlist_local_datasource.dart';
import 'package:film_recommendation/domain/entities/movie.dart';
import 'package:film_recommendation/presentation/providers/watchlist_provider.dart';
import 'package:film_recommendation/presentation/utils/watchlist_toggler.dart';
import 'package:film_recommendation/presentation/widgets/glass_nav_bar.dart';
import 'package:film_recommendation/presentation/widgets/movie_card.dart';

void main() {
  testWidgets('watchlist toggle + persist', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final ds = WatchlistLocalDataSource();
    final provider = WatchlistProvider(dataSource: ds)..load();
    await tester.pumpAndSettle();

    const movie = Movie(movieId: 'tt1', movieName: 'Inception');
    await provider.toggle(movie);
    await tester.pumpAndSettle();
    expect(provider.isSaved('tt1'), isTrue);
    expect(provider.count, 1);

    final saved = await ds.getWatchlist();
    expect(saved.length, 1);
    expect(saved.first.movieName, 'Inception');

    await provider.remove('tt1');
    await tester.pumpAndSettle();
    expect(provider.isSaved('tt1'), isFalse);
    expect(provider.count, 0);
  });

  testWidgets('kartu film bisa diclick bookmark-nya', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final provider = WatchlistProvider(dataSource: WatchlistLocalDataSource())
      ..load();
    await tester.pumpAndSettle();

    const movie = Movie(movieId: 'tt2', movieName: 'Interstellar');

    await tester.pumpWidget(
      ChangeNotifierProvider<WatchlistProvider>.value(
        value: provider,
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: ListenableBuilder(
                listenable: provider,
                builder: (context, _) => MovieCard(
                  movie: movie,
                  rank: 1,
                  isSaved: provider.isSaved(movie.movieId),
                  onToggleBookmark: () => toggleWatchlist(context, movie),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
    await tester.tap(find.byIcon(Icons.bookmark_border));
    await tester.pumpAndSettle();

    expect(provider.isSaved('tt2'), isTrue);
    expect(find.byIcon(Icons.bookmark), findsOneWidget);
  });

  testWidgets('badge watchlist di nav bar', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: GlassNavBar(
            currentIndex: 0,
            onTap: (_) {},
            watchlistCount: 3,
          ),
        ),
      ),
    );

    expect(find.text('3'), findsOneWidget);
  });
}
