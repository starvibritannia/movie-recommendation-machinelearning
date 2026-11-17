import 'package:flutter/material.dart';

import '../../core/errors/failures.dart';
import '../../data/datasources/watchlist_local_datasource.dart';
import '../../data/models/movie_model.dart';
import '../../domain/entities/movie.dart';

/// State watchlist: daftar film yang ditandai user.
///
/// Watchlist sengaja lokal (per HP) karena aplikasi nggak punya login.
/// Perubahan langsung disimpan ke shared_preferences, jadi data nggak hilang
/// saat aplikasi ditutup.
class WatchlistProvider extends ChangeNotifier {
  final WatchlistLocalDataSource dataSource;

  WatchlistProvider({required this.dataSource});

  List<Movie> _movies = [];
  List<Movie> get movies => _movies;

  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  int get count => _movies.length;

  Set<String> get _ids => _movies.map((m) => m.movieId).toSet();

  /// Dipakai tombol bookmark di halaman detail & kartu watchlist.
  bool isSaved(String movieId) => _ids.contains(movieId);

  /// Baca watchlist dari penyimpanan lokal (dipanggil sekali saat app nyala).
  Future<void> load() async {
    try {
      _movies = await dataSource.getWatchlist();
    } on Failure catch (error) {
      // Watchlist gagal dibaca tidak boleh bikin app mati, jadi cukup dikosongkan.
      debugPrint('Watchlist gagal dimuat: ${error.message}');
      _movies = [];
    } finally {
      _isLoaded = true;
      notifyListeners();
    }
  }

  /// Tambah kalau belum ada, hapus kalau sudah ada (toggle).
  Future<void> toggle(Movie movie) async {
    final alreadySaved = isSaved(movie.movieId);

    if (alreadySaved) {
      _movies.removeWhere((m) => m.movieId == movie.movieId);
    } else {
      _movies.insert(0, MovieModel.fromMovie(movie));
    }
    notifyListeners();

    try {
      await dataSource.saveWatchlist(
        _movies.map(MovieModel.fromMovie).toList(),
      );
    } on Failure catch (error) {
      debugPrint('Watchlist gagal disimpan: ${error.message}');
    }
  }

  /// Hapus satu film dari watchlist.
  Future<void> remove(String movieId) =>
      toggle(_movies.firstWhere((m) => m.movieId == movieId));
}
