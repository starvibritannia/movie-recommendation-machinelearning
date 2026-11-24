import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:film_recommendation/data/datasources/watchlist_local_datasource.dart';
import 'package:film_recommendation/core/constants/app_strings.dart';
import 'package:film_recommendation/data/services/poster_service.dart';
import 'package:film_recommendation/domain/entities/movie.dart';
import 'package:film_recommendation/domain/entities/recommendation_criteria.dart';
import 'package:film_recommendation/domain/repositories/recommendation_repository.dart';
import 'package:film_recommendation/presentation/pages/mascot_page.dart';
import 'package:film_recommendation/presentation/providers/recommendation_provider.dart';
import 'package:film_recommendation/presentation/providers/watchlist_provider.dart';

Movie _movie(int i) => Movie(
  movieId: 'tt$i',
  movieName: 'Film Nomor $i',
  year: 2010 + i,
  runtime: 120 + i,
  certificate: 'PG-13',
  genre: const ['Sci-Fi'],
  rating: 8.0 + i * 0.2,
  matchPercent: 90.0 + i,
  clusterLabel: null,
);

class _FakeRepo implements RecommendationRepository {
  @override
  Future<List<Movie>> getRecommendations(RecommendationCriteria c) async => [
    _movie(1),
    _movie(2),
    _movie(3),
  ];

  @override
  Future<bool> isServerHealthy() async => true;
}

void main() {
  /// Lebar layar proyektor di popup hasil.
  double lebarLayar(WidgetTester tester) =>
      tester.getSize(find.byKey(const ValueKey('layarProyektor'))).width;

  Future<void> bukaHasil(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<PosterService>.value(value: PosterService(prefs)),
          ChangeNotifierProvider(
            create: (_) => RecommendationProvider(repository: _FakeRepo()),
          ),
          ChangeNotifierProvider(
            create: (_) =>
                WatchlistProvider(dataSource: WatchlistLocalDataSource())
                  ..load(),
          ),
        ],
        child: MaterialApp(home: const MascotPage()),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 2700));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(
      find.byKey(const ValueKey('ctaTiket')),
      warnIfMissed: false,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.tap(find.text('Sci-Fi'), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.text('Oke, lanjut!'), warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 900));
    await tester.tap(find.text('Siap, lanjut!'), warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.enterText(find.byType(TextField), 'ruang angkasa');
    await tester.tap(
      find.byIcon(Icons.keyboard_double_arrow_up_rounded),
      warnIfMissed: false,
    );
    // Popup muncul setelah sheet selesai dibangun, jadi tunggu dulu.
    var terbuka = false;
    for (var i = 0; i < 24 && !terbuka; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      terbuka = find.text(AppStrings.mascotDone).evaluate().isNotEmpty;
    }

    expect(
      find.text(AppStrings.mascotDone),
      findsOneWidget,
      reason: 'popup hasil harus terbuka',
    );
  }

  testWidgets('popup hasil: berkas nyala lalu layar membesar', (tester) async {
    await bukaHasil(tester);

    expect(find.text('3 film'), findsOneWidget);

    // Layar mulai kecil (titik cahaya), bukan langsung penuh.
    final awal = lebarLayar(tester);
    expect(awal, lessThan(180), reason: 'layar harus mulai dari titik cahaya');

    await tester.pump(const Duration(milliseconds: 320));
    final tengah = lebarLayar(tester);
    expect(tengah, greaterThan(awal), reason: 'layar harus membesar');
    expect(tengah, lessThan(345), reason: 'layar belum penuh di tengah jalan');

    await tester.pump(const Duration(milliseconds: 1100));
    expect(
      lebarLayar(tester),
      greaterThan(350),
      reason: 'layar harus penuh di akhir',
    );

    expect(tester.takeException(), isNull, reason: 'popup hasil overflow');
  });
}
