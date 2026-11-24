import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:film_recommendation/domain/entities/movie.dart';
import 'package:film_recommendation/domain/entities/recommendation_criteria.dart';
import 'package:film_recommendation/domain/repositories/recommendation_repository.dart';
import 'package:film_recommendation/presentation/pages/mascot_page.dart';
import 'package:film_recommendation/presentation/providers/recommendation_provider.dart';

class _FakeRepo implements RecommendationRepository {
  @override
  Future<List<Movie>> getRecommendations(
    RecommendationCriteria criteria,
  ) async => [];

  @override
  Future<bool> isServerHealthy() async => true;
}

void main() {
  testWidgets('alur bouncy TonTon jalan tanpa error', (tester) async {
    // Ukuran permukaan disamakan dengan HP sungguhan (layar panel butuh ruang).
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => RecommendationProvider(repository: _FakeRepo()),
        child: const MaterialApp(home: MascotPage()),
      ),
    );

    // Sapaan -> tombol ajakan.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 2700));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byKey(const ValueKey('ctaTiket')), findsOneWidget);

    // Buka genre.
    await tester.tap(
      find.byKey(const ValueKey('ctaTiket')),
      warnIfMissed: false,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 1300));
    expect(find.text('Sci-Fi'), findsOneWidget);

    // Pilih genre + konfirmasi.
    await tester.pump(const Duration(milliseconds: 800));
    await tester.tap(find.text('Sci-Fi'), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Oke, lanjut!'), findsOneWidget);
    // Beri waktu animasi pop tombol selesai sebelum ditap.
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.text('Oke, lanjut!'), warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 500));

    // Slider muncul.
    expect(find.text('Rating minimum'), findsOneWidget);
    expect(find.text('ATUR SELERA'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 900));
    // Tombol "lanjut" wajib terlihat penuh (nggak terpotong bawah layar).
    final nextRect = tester.getRect(find.text('Siap, lanjut!'));
    expect(nextRect.bottom, lessThan(800), reason: 'tombol lanjut terpotong');
    await tester.tap(find.text('Siap, lanjut!'), warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 500));

    // Kata kunci muncul.
    expect(find.byIcon(Icons.keyboard_double_arrow_up_rounded), findsOneWidget);
    expect(find.text('KATA KUNCI'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 700));
    await tester.enterText(find.byType(TextField), 'ruang angkasa');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(
      find.byIcon(Icons.keyboard_double_arrow_up_rounded),
      warnIfMissed: false,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 500));

    // Fake repo balikin kosong -> fase selesai.
    expect(find.text('Cari lagi'), findsOneWidget);
  });
}
