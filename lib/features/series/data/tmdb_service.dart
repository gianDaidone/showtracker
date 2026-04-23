import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/constants.dart';
import 'models/tmdb_show.dart';
import 'models/tmdb_show_detail.dart';
import 'models/tmdb_season.dart';
import '../../movies/data/models/tmdb_movie.dart';
import '../../movies/data/models/tmdb_movie_detail.dart';

class TmdbService {
  static const _base = 'https://api.themoviedb.org/3';

  Uri _uri(String path, [Map<String, String>? params]) {
    if (kTmdbApiKey.isEmpty) {
      throw Exception(
        'TMDB API key non configurata.\n'
        'Aggiungila in lib/core/constants.dart → kTmdbApiKey',
      );
    }
    return Uri.parse('$_base$path').replace(
      queryParameters: {'api_key': kTmdbApiKey, ...?params},
    );
  }

  Future<Map<String, dynamic>> _get(Uri uri) async {
    final response = await http.get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('TMDB ${response.statusCode}: ${response.reasonPhrase}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<List<TmdbShow>> searchShows(String query) async {
    final data = await _get(
      _uri('/search/tv', {'query': query, 'language': 'it-IT'}),
    );
    return ((data['results'] as List<dynamic>?) ?? [])
        .map((e) => TmdbShow.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<TmdbShowDetail> getShowDetails(int id) async {
    final results = await Future.wait([
      _get(_uri('/tv/$id', {'language': 'it-IT'})),
      _get(_uri('/tv/$id', {'language': 'en-US'})),
    ]);
    return TmdbShowDetail.fromJson(results[0], en: results[1]);
  }

  Future<TmdbSeason> getSeasonDetails(int showId, int seasonNumber) async {
    final results = await Future.wait([
      _get(_uri('/tv/$showId/season/$seasonNumber', {'language': 'it-IT'})),
      _get(_uri('/tv/$showId/season/$seasonNumber', {'language': 'en-US'})),
    ]);
    return TmdbSeason.fromDetailJson(results[0], en: results[1]);
  }

  // ── Film ──────────────────────────────────────────────────────────────────

  Future<List<TmdbMovie>> searchMovies(String query) async {
    final data = await _get(
      _uri('/search/movie', {
        'query': query,
        'language': 'it-IT',
        'include_adult': 'false',
      }),
    );
    return ((data['results'] as List<dynamic>?) ?? [])
        .map((e) => TmdbMovie.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<TmdbMovieDetail> getMovieDetails(int id) async {
    final results = await Future.wait([
      _get(_uri('/movie/$id', {'language': 'it-IT'})),
      _get(_uri('/movie/$id', {'language': 'en-US'})),
    ]);
    return TmdbMovieDetail.fromJson(results[0], en: results[1]);
  }
}
