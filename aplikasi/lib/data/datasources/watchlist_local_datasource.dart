import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/errors/failures.dart';
import '../models/movie_model.dart';

/// Simpan & baca watchlist user di penyimpanan lokal HP.
///
/// Dipilih shared_preferences (bukan database) karena:
///   - nggak ada login / akun, jadi nggak butuh sync antar perangkat
///   - data yang disimpan cuma daftar film, ukurannya kecil
///   - cukup berupa JSON string, gampang di-debug
class WatchlistLocalDataSource {
  static const String _storageKey = 'watchlist_movies';

  Future<List<MovieModel>> getWatchlist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.isEmpty) return [];

      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => MovieModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on Failure {
      rethrow;
    } catch (error) {
      throw CacheFailure('Gagal membaca watchlist: $error');
    }
  }

  Future<void> saveWatchlist(List<MovieModel> movies) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonEncode(movies.map((m) => m.toJson()).toList());
      await prefs.setString(_storageKey, raw);
    } catch (error) {
      throw CacheFailure('Gagal menyimpan watchlist: $error');
    }
  }
}
