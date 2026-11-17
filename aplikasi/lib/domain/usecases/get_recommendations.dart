import '../entities/movie.dart';
import '../entities/recommendation_criteria.dart';
import '../repositories/recommendation_repository.dart';

/// Use case: ambil rekomendasi film berdasarkan kriteria.
///
/// Dipisah jadi class sendiri biar logika ambil data bisa diuji terpisah dari
/// UI, dan provider nggak perlu tahu detail repository.
class GetRecommendations {
  final RecommendationRepository repository;

  const GetRecommendations(this.repository);

  Future<List<Movie>> call(RecommendationCriteria criteria) {
    return repository.getRecommendations(criteria);
  }
}
