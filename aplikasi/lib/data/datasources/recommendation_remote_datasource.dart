import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/constants/api_constants.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/recommendation_criteria.dart';
import '../models/movie_model.dart';
import '../models/recommendation_response.dart';

/// Data source yang ngomong langsung ke backend FastAPI lewat HTTP.
///
/// Semua detail teknis (URL, header, timeout, parsing) dikurung di sini,
/// supaya lapisan atas nggak perlu tahu soal HTTP.
class RecommendationRemoteDataSource {
  final http.Client client;

  RecommendationRemoteDataSource({http.Client? client})
    : client = client ?? http.Client();

  /// POST /recommend dengan body JSON berisi kriteria user.
  Future<List<MovieModel>> getRecommendations(
    RecommendationCriteria criteria,
  ) async {
    try {
      final response = await client
          .post(
            Uri.parse(
              '${ApiConstants.baseUrl}${ApiConstants.recommendEndpoint}',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(criteria.toJson()),
          )
          .timeout(ApiConstants.receiveTimeout);

      if (response.statusCode != 200) {
        throw ServerFailure(
          'Server balas status ${response.statusCode}: ${response.body}',
        );
      }

      return _parseBody(response.body);
    } on Failure {
      rethrow;
    } catch (error) {
      throw NetworkFailure('Gagal nyambung ke server FastAPI: $error');
    }
  }

  /// GET /health, dipakai buat cek server hidup.
  Future<bool> isServerHealthy() async {
    try {
      final response = await client
          .get(
            Uri.parse('${ApiConstants.baseUrl}${ApiConstants.healthEndpoint}'),
          )
          .timeout(ApiConstants.connectTimeout);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Terima response baik berupa object maupun array polos.
  List<MovieModel> _parseBody(String body) {
    final dynamic decoded = jsonDecode(body);

    if (decoded is List) {
      return decoded
          .map((e) => MovieModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    if (decoded is Map<String, dynamic>) {
      return RecommendationResponse.fromJson(decoded).recommendations;
    }

    throw const ServerFailure('Format response server tidak dikenal');
  }
}
