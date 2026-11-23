import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:film_recommendation/presentation/widgets/glass_nav_bar.dart';
import 'package:film_recommendation/presentation/widgets/wordmark.dart';

void main() {
  testWidgets('wordmark glow: Ne + Vie + tagline', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: Wordmark(fontSize: 40))),
      ),
    );

    expect(find.text('Ne'), findsOneWidget);
    // "Vie" dua lapis (glow + tajam) di dalam wordmark.
    expect(find.text('Vie'), findsNWidgets(2));
    expect(find.text('NEXT MOVIE'), findsNothing);
  });

  testWidgets('wordmark splash: tagline + garis gradien muncul', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: Wordmark(fontSize: 56, showTagline: true)),
        ),
      ),
    );

    expect(find.text('Ne'), findsOneWidget);
    expect(find.text('Vie'), findsNWidgets(2));
    expect(find.text('NEXT MOVIE'), findsOneWidget);
  });

  testWidgets('tab aktif nav bar pakai pill gradien', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: GlassNavBar(
            currentIndex: 0,
            onTap: (_) {},
            watchlistCount: 2,
          ),
        ),
      ),
    );

    BoxDecoration pillOf(IconData icon) {
      final finder = find.ancestor(
        of: find.byIcon(icon),
        matching: find.byType(AnimatedContainer),
      );
      return tester.widget<AnimatedContainer>(finder).decoration
          as BoxDecoration;
    }

    // Tab aktif (Maskot) -> pill gradien oranye.
    expect(pillOf(Icons.smart_toy).gradient, isNotNull);
    // Tab non-aktif (Watchlist) -> tanpa gradien.
    expect(pillOf(Icons.bookmark_border).gradient, isNull);
    expect(find.text('2'), findsOneWidget);
  });
}
