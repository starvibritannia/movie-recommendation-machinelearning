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
  Future<void> pumpToGenre(WidgetTester tester) async {
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
  }

  /// Proporsi tinggi papan yang masih kelihatan.
  /// Efek gulung pakai klip (konten terpotong), bukan scale (konten teremas).
  double rollRatio(WidgetTester tester) {
    final ratios = tester
        .widgetList<ClipRect>(find.byType(ClipRect))
        .map((c) => c.clipper)
        .whereType<CustomClipper<Rect>>()
        .map((cl) => cl.getClip(const Size(390, 500)))
        // Potong bagian yang di atas papan (ruang tiket) biar proporsinya
        // mengacu ke tinggi papan itu sendiri.
        .map((r) => (r.bottom - r.top.clamp(0, 500)) / 500)
        .toList();
    expect(ratios, isNotEmpty, reason: 'harus ada klip gulungan');
    return ratios.reduce((a, b) => a < b ? a : b);
  }

  testWidgets('papan marquee genre: judul, semua genre, tombol lanjut', (
    tester,
  ) async {
    await pumpToGenre(tester);

    expect(find.text('PILIH GENRE'), findsOneWidget);
    expect(find.text('SILAHKAN PILIH SATU ATAU LEBIH'), findsOneWidget);
    // Tiket genre di pojok papan.
    expect(find.text('TIKET GENRE'), findsOneWidget);
    // Regresi: tiketnya menjulang di atas papan, jadi klip gulungan harus
    // memberi ruang di sana. Kalau nggak, tiketnya bakal kepotong.
    final klipAwal = tester
        .widgetList<ClipRect>(find.byType(ClipRect))
        .first
        .clipper!
        .getClip(const Size(390, 500));
    expect(
      klipAwal.top,
      lessThan(0),
      reason: 'klip gulungan harus melebihi tepi atas papan',
    );
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

  testWidgets('klik lanjut: papan menggulung jadi tiket ke slot TonTon', (
    tester,
  ) async {
    await pumpToGenre(tester);

    await tester.tap(find.text('Sci-Fi'), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 900));

    final tiketSebelum = tester.getRect(find.text('TIKET GENRE')).center;
    final rollAwal = rollRatio(tester);
    expect(rollAwal, greaterThan(0.9), reason: 'papan masih penuh');

    await tester.tap(find.text('Oke, lanjut!'), warnIfMissed: false);

    // Gulungan bertahap lewat klip, bukan lenyap instan.
    await tester.pump(const Duration(milliseconds: 220));
    expect(rollRatio(tester), greaterThan(0.35), reason: 'papan belum habis');

    await tester.pump(const Duration(milliseconds: 300));
    expect(
      rollRatio(tester),
      lessThan(rollAwal - 0.5),
      reason: 'papan sudah menciut jadi tiket',
    );

    // Tiket pojok hilang, tiket baru terbentuk & terbang ke slot tape TonTon.
    expect(find.text('TIKET GENRE'), findsOneWidget);
    final tiketAkhir = tester.getRect(find.text('TIKET GENRE')).center;
    expect(
      (tiketAkhir - tiketSebelum).distance,
      greaterThan(2),
      reason: 'tiket harus berpindah dari pojok papan',
    );
    expect(
      tiketAkhir.dy,
      lessThan(320),
      reason: 'tiket harus sampai di slot tape TonTon',
    );

    expect(tester.takeException(), isNull, reason: 'transisi overflow');
  });
}
