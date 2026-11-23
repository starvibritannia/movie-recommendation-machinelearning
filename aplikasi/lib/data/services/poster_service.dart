import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Ambil URL poster film dari IMDb ID.
///
/// Dataset cuma punya `movie_id` (IMDb, mis. tt1375666), jadi poster dicari
/// dari dua sumber gratis tanpa API key:
///   1. IMDb suggestion API (koverage paling luas).
///   2. Cinemeta/Stremio (nutup sebagian yang IMDb-nya kosong).
/// Hasilnya di-cache lokal di [SharedPreferences] supaya nggak fetch ulang.
class PosterService {
  PosterService(this._prefs, {http.Client? client})
    : _client = client ?? http.Client();

  final SharedPreferences _prefs;
  final http.Client _client;

  static const String _imdbBase = 'https://v2.sg.media-imdb.com/suggestion';
  static const String _cinemetaBase = 'https://v3-cinemeta.strem.io/meta/movie';
  static const String _ua =
      'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/120 Mobile Safari/537.36';

  /// Cache in-memory (termasuk hasil "nggak ada") biar nggak request ulang.
  final Map<String, String?> _memory = {};

  /// Return URL poster, atau null kalau nggak ada / gagal.
  Future<String?> resolve(String movieId) async {
    final id = movieId.trim();
    if (!id.startsWith('tt')) return null;
    if (_memory.containsKey(id)) return _memory[id];

    final cached = _prefs.getString('poster_$id');
    if (cached != null && cached.isNotEmpty) {
      _memory[id] = cached;
      return cached;
    }

    final url = await _fromImdb(id) ?? await _fromCinemeta(id);
    _memory[id] = url;
    if (url != null && url.isNotEmpty) {
      await _prefs.setString('poster_$id', url);
    }
    return url;
  }

  Future<String?> _fromImdb(String id) async {
    try {
      final uri = Uri.parse('$_imdbBase/${id[0]}/$id.json');
      final response = await _client
          .get(uri, headers: {'User-Agent': _ua})
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;
      return extractPoster(response.body);
    } catch (_) {
      return null;
    }
  }

  Future<String?> _fromCinemeta(String id) async {
    try {
      final uri = Uri.parse('$_cinemetaBase/$id.json');
      final response = await _client
          .get(uri, headers: {'User-Agent': _ua})
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body);
      if (data is! Map<String, dynamic>) return null;
      final meta = data['meta'];
      if (meta is! Map<String, dynamic>) return null;
      final poster = meta['poster']?.toString();
      return (poster == null || poster.isEmpty) ? null : poster;
    } catch (_) {
      return null;
    }
  }

  /// Ambil `d[0].i.imageUrl` dari respons IMDb suggestion API.
  static String? extractPoster(String body) => _extractPoster(body);

  static String? _extractPoster(String body) {
    try {
      final data = jsonDecode(body);
      if (data is! Map<String, dynamic>) return null;
      final list = data['d'];
      if (list is! List || list.isEmpty) return null;
      final first = list.first;
      if (first is! Map<String, dynamic>) return null;
      final img = first['i'];
      if (img is! Map<String, dynamic>) return null;
      return img['imageUrl']?.toString();
    } catch (_) {
      return null;
    }
  }
}
