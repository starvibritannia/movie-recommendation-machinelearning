import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:film_recommendation/data/datasources/watchlist_local_datasource.dart';
import 'package:film_recommendation/domain/entities/movie.dart';
import 'package:film_recommendation/domain/entities/recommendation_criteria.dart';
import 'package:film_recommendation/domain/repositories/recommendation_repository.dart';
import 'package:film_recommendation/presentation/pages/main_shell.dart';
import 'package:film_recommendation/presentation/providers/recommendation_provider.dart';
import 'package:film_recommendation/presentation/providers/watchlist_provider.dart';
import 'package:film_recommendation/presentation/widgets/glass_nav_bar.dart';

class _FakeRepo implements RecommendationRepository {
  @override
  Future<List<Movie>> getRecommendations(
    RecommendationCriteria criteria,
  ) async => [];

  @override
  Future<bool> isServerHealthy() async => true;
}

void main() {
  testWidgets('tombol "Cari film dulu" pindah tab, nav bar nggak hilang', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final watchlist = WatchlistProvider(dataSource: WatchlistLocalDataSource())
      ..load();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => RecommendationProvider(repository: _FakeRepo()),
          ),
          ChangeNotifierProvider.value(value: watchlist),
        ],
        child: const MaterialApp(home: MainShell()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    // Nav bar ada di awal.
    expect(find.byType(GlassNavBar), findsOneWidget);

    // Pindah ke tab Watchlist.
    await tester.tap(
      find.descendant(
        of: find.byType(GlassNavBar),
        matching: find.text('Watchlist'),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Cari film dulu'), findsOneWidget);

    // Tap tombol: harusnya pindah tab, bukan push route baru.
    await tester.tap(find.text('Cari film dulu'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(GlassNavBar), findsOneWidget);
    expect(find.text('Cari film dulu'), findsNothing);
  });
}
