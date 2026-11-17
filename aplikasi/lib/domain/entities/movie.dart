/// Entity inti: satu film hasil rekomendasi.
///
/// Entity ini murni (nggak tahu-menahu soal JSON atau HTTP), supaya lapisan
/// domain bisa dipakai ulang tanpa bergantung ke backend.
class Movie {
  final String movieId;
  final String movieName;
  final int? year;
  final String certificate;
  final int? runtime;
  final List<String> genre;
  final double? rating;
  final int? votes;
  final String description;
  final String director;
  final List<String> stars;

  /// Persentase kemiripan terhadap kriteria user (0-100), diisi backend.
  final double? matchPercent;

  /// Label klaster hasil clustering, misal 3 = "Action/Sci-Fi modern".
  final int? clusterLabel;

  const Movie({
    required this.movieId,
    required this.movieName,
    this.year,
    this.certificate = 'Unrated',
    this.runtime,
    this.genre = const [],
    this.rating,
    this.votes,
    this.description = '',
    this.director = '-',
    this.stars = const [],
    this.matchPercent,
    this.clusterLabel,
  });

  /// Judul + tahun, dipakai di app bar halaman detail.
  String get titleWithYear {
    final y = year?.toString() ?? '????';
    return '$movieName ($y)';
  }
}
