import 'package:flutter/material.dart';

import '../../core/errors/failures.dart';
import '../../domain/entities/movie.dart';
import '../../domain/entities/recommendation_criteria.dart';
import '../../domain/repositories/recommendation_repository.dart';
import '../../domain/usecases/get_recommendations.dart';

/// Otak state halaman input & hasil.
///
/// Semua nilai filter disimpan di sini (bukan di widget) supaya state nggak
/// hilang saat berpindah halaman, dan UI cuma tinggal membaca + memanggil
/// method setter.
class RecommendationProvider extends ChangeNotifier {
  final RecommendationRepository repository;

  RecommendationProvider({required this.repository});

  // ---------------- state hasil ----------------
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<Movie> _results = const [];
  List<Movie> get results => _results;

  bool get hasResults => _results.isNotEmpty;

  // ---------------- state server ----------------
  bool? _isServerOnline;
  bool? get isServerOnline => _isServerOnline;

  // ---------------- state filter ----------------
  final Set<String> selectedGenres = <String>{};
  double minRating = 7.0;
  RangeValues runtimeRange = const RangeValues(60, 210);
  RangeValues yearRange = const RangeValues(1980, 2024);
  String keyword = '';
  int topN = 10;

  // ---------------- aksi ----------------

  /// Cek server FastAPI hidup atau tidak (dipanggil sekali saat halaman dibuka).
  Future<void> checkServerHealth() async {
    _isServerOnline = await repository.isServerHealthy();
    notifyListeners();
  }

  /// Kirim kriteria ke backend dan simpan hasilnya.
  Future<void> search() async {
    final criteria = _buildCriteria();
    final validationMessage = criteria.validate();
    if (validationMessage != null) {
      _errorMessage = validationMessage;
      _results = const [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _results = await GetRecommendations(repository)(criteria);
      if (_results.isEmpty) {
        _errorMessage =
            'Nggak ada film yang cocok, coba longgarkan filter kamu.';
      }
    } on Failure catch (error) {
      _errorMessage = error.message;
      _results = const [];
    } catch (error) {
      _errorMessage = 'Terjadi kesalahan: $error';
      _results = const [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  RecommendationCriteria _buildCriteria() {
    return RecommendationCriteria(
      genres: selectedGenres.toList(),
      minRating: minRating,
      runtimeMin: runtimeRange.start.round(),
      runtimeMax: runtimeRange.end.round(),
      yearStart: yearRange.start.round(),
      yearEnd: yearRange.end.round(),
      keyword: keyword,
      topN: topN,
    );
  }

  // ---------------- setter filter ----------------

  void toggleGenre(String genre) {
    if (selectedGenres.contains(genre)) {
      selectedGenres.remove(genre);
    } else {
      selectedGenres.add(genre);
    }
    notifyListeners();
  }

  void setMinRating(double value) {
    minRating = value;
    notifyListeners();
  }

  void setRuntimeRange(RangeValues value) {
    runtimeRange = value;
    notifyListeners();
  }

  void setYearRange(RangeValues value) {
    yearRange = value;
    notifyListeners();
  }

  void setKeyword(String value) {
    keyword = value;
    notifyListeners();
  }

  void setTopN(double value) {
    topN = value.round();
    notifyListeners();
  }

  /// Balikin semua filter ke nilai awal.
  void resetFilters() {
    selectedGenres.clear();
    minRating = 7.0;
    runtimeRange = const RangeValues(60, 210);
    yearRange = const RangeValues(1980, 2024);
    keyword = '';
    topN = 10;
    _errorMessage = null;
    _results = const [];
    notifyListeners();
  }
}
