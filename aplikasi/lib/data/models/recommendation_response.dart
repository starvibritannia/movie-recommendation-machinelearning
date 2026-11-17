import 'movie_model.dart';

/// Pembungkus response /recommend dari backend.
///
/// Backend bisa balikin dua bentuk, dan class ini menerima dua-duanya:
///   1. object : { "recommendations": [...], "total_candidates": 123, ... }
///   2. array  : [ {...}, {...} ]
///
/// Fleksibilitas ini sengaja dibuat supaya saat backend belum final, Flutter
/// tetap bisa parse response apa pun yang mirip.
class RecommendationResponse {
  final List<MovieModel> recommendations;
  final int? totalCandidates;
  final double? elapsedMs;
  final int? predictedCluster;

  const RecommendationResponse({
    this.recommendations = const [],
    this.totalCandidates,
    this.elapsedMs,
    this.predictedCluster,
  });

  factory RecommendationResponse.fromJson(Map<String, dynamic> json) {
    final rawList =
        (json['recommendations'] ?? json['results'] ?? []) as List<dynamic>;

    return RecommendationResponse(
      recommendations: rawList
          .map((e) => MovieModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalCandidates: _toInt(json['total_candidates']),
      elapsedMs: _toDouble(json['elapsed_ms']),
      predictedCluster: _toInt(json['predicted_cluster']),
    );
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
