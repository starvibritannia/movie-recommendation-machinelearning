/// Kriteria input user sebelum dikirim ke backend.
///
/// Class ini yang jadi "jembatan" antara UI dan API contract, jadi kalau
/// backend ganti nama field, cukup diubah di sini (lewat toJson).
class RecommendationCriteria {
  final List<String> genres;
  final double minRating;
  final int runtimeMin;
  final int runtimeMax;
  final int yearStart;
  final int yearEnd;
  final String keyword;
  final int topN;

  const RecommendationCriteria({
    this.genres = const [],
    this.minRating = 7.0,
    this.runtimeMin = 60,
    this.runtimeMax = 210,
    this.yearStart = 1980,
    this.yearEnd = 2024,
    this.keyword = '',
    this.topN = 10,
  });

  /// Bentuk JSON yang HARUS sama persis dengan kontrak API di docs/.
  Map<String, dynamic> toJson() {
    return {
      'genres': genres,
      'min_rating': minRating,
      'runtime_min': runtimeMin,
      'runtime_max': runtimeMax,
      'year_start': yearStart,
      'year_end': yearEnd,
      'keyword': keyword.trim().isEmpty ? null : keyword.trim(),
      'top_n': topN,
    };
  }

  /// Validasi ringan sebelum request dikirim.
  ///
  /// Mengembalikan pesan error, atau null kalau semuanya valid.
  String? validate() {
    if (yearStart > yearEnd) {
      return 'Tahun awal tidak boleh lebih besar dari tahun akhir.';
    }
    if (runtimeMin > runtimeMax) {
      return 'Durasi minimal tidak boleh lebih besar dari durasi maksimal.';
    }
    if (minRating < 0 || minRating > 10) {
      return 'Rating harus di antara 0 sampai 10.';
    }
    if (topN < 1 || topN > 50) {
      return 'Jumlah rekomendasi harus di antara 1 sampai 50.';
    }
    return null;
  }

  RecommendationCriteria copyWith({
    List<String>? genres,
    double? minRating,
    int? runtimeMin,
    int? runtimeMax,
    int? yearStart,
    int? yearEnd,
    String? keyword,
    int? topN,
  }) {
    return RecommendationCriteria(
      genres: genres ?? this.genres,
      minRating: minRating ?? this.minRating,
      runtimeMin: runtimeMin ?? this.runtimeMin,
      runtimeMax: runtimeMax ?? this.runtimeMax,
      yearStart: yearStart ?? this.yearStart,
      yearEnd: yearEnd ?? this.yearEnd,
      keyword: keyword ?? this.keyword,
      topN: topN ?? this.topN,
    );
  }
}
