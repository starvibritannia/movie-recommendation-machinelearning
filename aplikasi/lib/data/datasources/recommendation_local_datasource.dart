import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../../core/errors/failures.dart';
import '../models/movie_model.dart';

/// Data source lokal: baca file JSON dummy di assets/.
///
/// Fungsinya:
///   1. Napkin backup saat backend FastAPI belum jadi / sedang mati.
///   2. Bikin UI bisa langsung dilihat & ditest tanpa server.
class RecommendationLocalDataSource {
  static const String _mockAssetPath = 'assets/mock/recommendation_mock.json';

  Future<List<MovieModel>> getMockRecommendations() async {
    try {
      final raw = await rootBundle.loadString(_mockAssetPath);
      final dynamic decoded = jsonDecode(raw);

      final List<dynamic> list;
      if (decoded is List) {
        list = decoded;
      } else if (decoded is Map<String, dynamic>) {
        list = (decoded['recommendations'] ?? []) as List<dynamic>;
      } else {
        throw const CacheFailure('Struktur file mock tidak dikenal');
      }

      return list
          .map((e) => MovieModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on Failure {
      rethrow;
    } catch (error) {
      throw CacheFailure('Gagal membaca data dummy: $error');
    }
  }
}
