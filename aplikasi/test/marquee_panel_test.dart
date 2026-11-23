import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:film_recommendation/domain/entities/movie.dart';
import 'package:film_recommendation/domain/entities/recommendation_criteria.dart';
import 'package:film_recommendation/domain/repositories/recommendation_repository.dart';
import 'package:film_recommendation/presentation/pages/mascot_page.dart';
import 'package:film_recommendation/presentation/providers/recommendation_provider.dart';
import 'package:film_recommendation/presentation/widgets/marquee_panel.dart';

class _FakeRepo implements RecommendationRepository {
  @override
  Future<List<Movie>> getRecommendations(RecommendationCriteria c) async => [];
  @override
  Future<bool> isServerHealthy() async => true;
}

void main() {
  testWidgets('papan marquee genre: judul, semua genre, tombol lanjut', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => RecommendationProvider(repository: _FakeRepo()),
        child: const MaterialApp(home: MascotPage()),
      ),
    );

    await tester.pump(const Duration(milliseconds: 2700));
    await tester.tap(find.text('Cariin Film dong!'), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump(const Duration(milliseconds: 900));

    expect(find.text('PILIH GENRE'), findsOneWidget);
    expect(find.text('SILAHKAN PILIH SATU ATAU LEBIH'), findsOneWidget);
    // Tiket genre di pojok papan.
    expect(find.text('TIKET GENRE'), findsOneWidget);
    // 25 genre harus ada di papan.
    expect(find.text('Documentary'), findsOneWidget);
    expect(find.text('Western'), findsOneWidget);
    expect(find.text('Reality-TV'), findsOneWidget);
    expect(tester.takeException(), isNull, reason: 'papan genre overflow');

    final btn = tester.getRect(find.text('Oke, lanjut!'));
    expect(btn.bottom, lessThan(844), reason: 'tombol lanjut kepotong');

    // Tombol lanjut di kanan papan dan bukan lebar penuh (gaya mockup).
    final panel = tester.getRect(find.byType(MarqueePanel));
    expect(btn.right, lessThan(panel.right - 8), reason: 'tombol keluar papan');
    expect(btn.width, lessThan(panel.width * 0.6), reason: 'tombol kebanyakan');

    // Pilih genre -> counter naik, tombol tetap kelihatan.
    await tester.tap(find.text('Sci-Fi'), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 900));
    expect(find.text('1 dipilih'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
