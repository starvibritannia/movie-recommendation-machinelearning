import '../../domain/entities/movie.dart';

/// Representasi film dalam format JSON milik backend.
///
/// Tugasnya: menerjemahkan JSON -> Movie, plus menahan perbedaan nama field
/// (misal dataset pakai "runtime", API pakai "runtime_min") di satu tempat.
class MovieModel extends Movie {
  const MovieModel({
    required super.movieId,
    required super.movieName,
    super.year,
    super.certificate = 'Unrated',
    super.runtime,
    super.genre = const [],
    super.rating,
    super.votes,
    super.description = '',
    super.director = '-',
    super.stars = const [],
    super.matchPercent,
    super.clusterLabel,
  });

  factory MovieModel.fromJson(Map<String, dynamic> json) {
    return MovieModel(
      movieId: json['movie_id']?.toString() ?? '',
      movieName: (json['movie_name']?.toString() ?? '').isEmpty
          ? 'Tanpa Judul'
          : json['movie_name'].toString(),
      year: _toInt(json['year']),
      certificate: _toNonEmpty(json['certificate'], fallback: 'Unrated'),
      runtime: _toInt(json['runtime']),
      genre: _parseList(json['genre']),
      rating: _toDouble(json['rating']),
      votes: _toInt(json['votes']),
      description: json['description']?.toString() ?? '',
      director: _toNonEmpty(json['director'], fallback: '-'),
      stars: _parseList(json['star'] ?? json['stars']),
      matchPercent: _toDouble(json['match_percent']),
      clusterLabel: _toInt(json['cluster_label']),
    );
  }

  /// Buat MovieModel dari entity Movie (dipakai saat simpan watchlist).
  factory MovieModel.fromMovie(Movie movie) {
    return MovieModel(
      movieId: movie.movieId,
      movieName: movie.movieName,
      year: movie.year,
      certificate: movie.certificate,
      runtime: movie.runtime,
      genre: movie.genre,
      rating: movie.rating,
      votes: movie.votes,
      description: movie.description,
      director: movie.director,
      stars: movie.stars,
      matchPercent: movie.matchPercent,
      clusterLabel: movie.clusterLabel,
    );
  }

  /// Balik ke JSON (dipakai saat testing / debug).
  Map<String, dynamic> toJson() {
    return {
      'movie_id': movieId,
      'movie_name': movieName,
      'year': year,
      'certificate': certificate,
      'runtime': runtime,
      'genre': genre,
      'rating': rating,
      'votes': votes,
      'description': description,
      'director': director,
      'star': stars,
      'match_percent': matchPercent,
      'cluster_label': clusterLabel,
    };
  }

  // ---------------- helper parsing ----------------

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.round();
    return int.tryParse(value.toString().replaceAll(RegExp(r'[^0-9-]'), ''));
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(
      value.toString().replaceAll(RegExp(r'[^0-9.\-]'), ''),
    );
  }

  static String _toNonEmpty(dynamic value, {required String fallback}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  /// Genre bisa datang sebagai `List<String>` atau string "Action, Drama".
  static List<String> _parseList(dynamic value) {
    if (value == null) return const [];
    if (value is List) {
      return value
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return value
        .toString()
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }
}
