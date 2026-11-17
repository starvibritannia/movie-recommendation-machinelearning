import '../entities/movie.dart';
import '../entities/recommendation_criteria.dart';

/// Kontrak repository (abstraksi), diimplementasikan di lapisan data.
///
/// Domain cuma tau "ada cara buat minta rekomendasi", nggak peduli datanya
/// datang dari FastAPI, cache, atau file dummy.
abstract class RecommendationRepository {
  Future<List<Movie>> getRecommendations(RecommendationCriteria criteria);

  /// Cek server FastAPI hidup atau tidak (dipakai halaman pengaturan/debug).
  Future<bool> isServerHealthy();
}
