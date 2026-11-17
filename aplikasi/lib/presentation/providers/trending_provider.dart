import 'package:flutter/material.dart';

import '../../core/errors/failures.dart';
import '../../data/datasources/recommendation_local_datasource.dart';
import '../../domain/entities/movie.dart';

/// State halaman Trending.
///
/// Sekarang isinya data dummy dulu. Nanti kalau backend menambah endpoint
/// `/trending`, tinggal ganti [load] jadi panggilan remote + fallback ke sini.
class TrendingProvider extends ChangeNotifier {
  final RecommendationLocalDataSource localDataSource;

  TrendingProvider({required this.localDataSource});

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<Movie> _movies = [];
  List<Movie> get movies => _movies;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Muat daftar film trending.
  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _movies = await localDataSource.getMockRecommendations();
    } on Failure catch (error) {
      _errorMessage = error.message;
      _movies = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
