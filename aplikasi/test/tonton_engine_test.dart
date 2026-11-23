import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:film_recommendation/presentation/widgets/tonton_engine.dart';
import 'package:film_recommendation/presentation/widgets/tv_mascot.dart';

void main() {
  group('TontonEngine', () {
    test('hop naik lalu mendarat di posisi semula', () {
      final e = TontonEngine();
      e.hop(620);

      var minY = 0.0;
      for (var i = 0; i < 300; i++) {
        e.tick(1 / 60);
        minY = math.min(minY, e.pos.dy);
      }

      expect(minY, lessThan(-20), reason: 'harus sempat melayang');
      expect(e.pos.dy, closeTo(0, 0.01), reason: 'mendarat di home');
    });

    test('poke beruntun eskalasi ekspresi', () {
      final e = TontonEngine();
      const seq = [
        MascotExpression.happy,
        MascotExpression.excited,
        MascotExpression.surprised,
        MascotExpression.wince,
        MascotExpression.annoyed,
        MascotExpression.angry,
        MascotExpression.angry,
      ];
      for (final expected in seq) {
        e.poke(const Offset(110, 110));
        expect(e.expression, expected);
      }
    });

    test('8 kali poke berujung marah lalu baikan', () {
      final e = TontonEngine()..autonomy = false;
      for (var i = 0; i < 8; i++) {
        e.poke(const Offset(110, 110));
      }
      expect(e.expression, MascotExpression.furious);

      for (var i = 0; i < 120; i++) {
        e.tick(1 / 60);
      }
      expect(e.expression, MascotExpression.unamused);

      for (var i = 0; i < 90; i++) {
        e.tick(1 / 60);
      }
      expect(e.expression, MascotExpression.neutral);
    });

    test('drag menggerakkan posisi lalu kembali', () {
      final e = TontonEngine()..autonomy = false;
      e.pointerDown(const Offset(110, 110));
      for (var i = 0; i < 60; i++) {
        e.pointerMove(const Offset(150, 120));
        e.tick(1 / 60);
      }
      expect(e.pos.dx, greaterThan(10));

      e.pointerUp();
      for (var i = 0; i < 240; i++) {
        e.tick(1 / 60);
      }
      expect(e.pos.dx, closeTo(0, 0.5));
    });

    test('tidur kalau 22 detik nggak disentuh', () {
      final e = TontonEngine();
      e.tick(23);
      expect(e.expression, MascotExpression.asleep);

      e.pointerMove(const Offset(110, 110));
      e.tick(0.2);
      expect(e.expression, isNot(MascotExpression.asleep));
    });

    test('mulut bergerak saat talking', () {
      final e = TontonEngine();
      e.setTalking(true);
      var maxOpen = 0.0;
      for (var i = 0; i < 120; i++) {
        e.tick(1 / 60);
        maxOpen = math.max(maxOpen, e.mouthOpen);
      }
      expect(maxOpen, greaterThan(0.2));
    });

    test('seret bebas sampai batas dragRange', () {
      final e = TontonEngine()..autonomy = false;
      e.pointerDown(const Offset(110, 110));
      for (var i = 0; i < 120; i++) {
        e.pointerMove(const Offset(400, 400));
        e.tick(1 / 60);
      }
      expect(e.pos.dx, greaterThan(e.dragRange * 0.5));
      expect(e.pos.dx, lessThanOrEqualTo(e.dragRange + 0.5));
      expect(e.pos.dy, lessThanOrEqualTo(e.dragRange + 0.5));
      e.pointerUp();
    });

    test('mengambang: bob berubah seiring waktu', () {
      final e = TontonEngine()..autonomy = false;
      e.tick(0.1);
      final a = e.bobY;
      e.tick(0.5);
      expect(e.bobY == a, isFalse);
    });
  });

  testWidgets('klik TonTon memicu ekspresi', (tester) async {
    final controller = MascotController();
    controller.engine.autonomy = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(child: TvMascot(controller: controller)),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byType(TvMascot), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 100));

    expect(controller.engine.expression, MascotExpression.happy);
  });
}
