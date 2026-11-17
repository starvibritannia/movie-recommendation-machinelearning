import '../../core/errors/failures.dart';
import '../../domain/entities/movie.dart';
import '../../domain/entities/recommendation_criteria.dart';
import '../../domain/repositories/recommendation_repository.dart';
import '../datasources/recommendation_local_datasource.dart';
import '../datasources/recommendation_remote_datasource.dart';

/// Implementasi repository: nentuin data rekomendasi datang dari mana.
///
/// Strategi default:
///   - Kalau [preferMock] true, langsung pakai data dummy (buat development).
///   - Kalau false, coba remote dulu, lalu otomatis fallback ke dummy kalau
///     server nggak bisa dihubungi. Jadi UI tetap bisa dipakai pas backend
///     belum selesai, tapi begitu backend hidup, aplikasi langsung pakai data
///     asli tanpa perlu ubah kode.
class RecommendationRepositoryImpl implements RecommendationRepository {
  final RecommendationRemoteDataSource remoteDataSource;
  final RecommendationLocalDataSource localDataSource;
  final bool preferMock;

  RecommendationRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    this.preferMock = false,
  });

  @override
  Future<List<Movie>> getRecommendations(
    RecommendationCriteria criteria,
  ) async {
    if (preferMock) {
      return localDataSource.getMockRecommendations();
    }

    try {
      return await remoteDataSource.getRecommendations(criteria);
    } on NetworkFailure {
      // Backend belum siap, jadi pakai dummy biar aplikasi tetap jalan.
      return localDataSource.getMockRecommendations();
    }
  }

  @override
  Future<bool> isServerHealthy() => remoteDataSource.isServerHealthy();
}
