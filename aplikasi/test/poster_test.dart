import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:film_recommendation/data/models/movie_model.dart';
import 'package:film_recommendation/data/services/poster_service.dart';
import 'package:film_recommendation/presentation/widgets/movie_poster.dart';

void main() {
  test('MovieModel simpan & baca poster_url', () {
    const model = MovieModel(
      movieId: 'tt1375666',
      movieName: 'Inception',
      posterUrl: 'https://example.com/a.jpg',
    );

    final json = model.toJson();
    expect(json['poster_url'], 'https://example.com/a.jpg');

    final back = MovieModel.fromJson(json);
    expect(back.posterUrl, 'https://example.com/a.jpg');
  });

  test('MovieModel poster_url kosong jadi null', () {
    final model = MovieModel.fromJson({'movie_id': 'tt1', 'movie_name': 'X'});
    expect(model.posterUrl, isNull);
  });

  test('PosterService extractPoster ambil imageUrl', () {
    const body =
        '{"d":[{"i":{"imageUrl":"https://x/y.jpg","width":700,"height":1000},'
        '"id":"tt1","l":"Inception"}]}';
    expect(PosterService.extractPoster(body), 'https://x/y.jpg');
    expect(PosterService.extractPoster('{"d":[]}'), isNull);
    expect(PosterService.extractPoster('bukan json'), isNull);
  });

  testWidgets('MoviePoster fallback tampil kalau poster nggak ada', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      Provider<PosterService>.value(
        value: PosterService(prefs),
        child: const MaterialApp(
          home: Scaffold(
            body: Center(
              child: MoviePoster(
                movieId: 'tt1375666',
                title: 'Inception',
                width: 74,
                height: 104,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('I'), findsOneWidget);
  });
}
