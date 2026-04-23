import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/constants.dart';
import 'models/tmdb_show.dart';
import 'models/tmdb_show_detail.dart';
import 'models/tmdb_season.dart';
import 'models/tmdb_episode.dart';
import 'models/normalized_anime_season.dart';
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

  // ── Anime: redistribuisce gli episodi TMDB per stagione AniList ────────────

  /// Fetches TMDB episodes and redistributes them according to AniList season
  /// boundaries. Returns a map from AniList season number → redistributed episodes.
  ///
  /// Also enriches episode titles: if TMDB has a placeholder title ("Episodio 4"),
  /// it is replaced with the real title from AniList streamingEpisodes (if available).
  /// If AniList also lacks the title, the placeholder is kept as-is.
  Future<Map<int, List<TmdbEpisode>>> getAnimeEpisodesBySeason(
    int tmdbId,
    List<NormalizedAnimeSeason> animeSeasonsData,
  ) async {
    if (animeSeasonsData.isEmpty) return {};

    final totalExpected =
        animeSeasonsData.fold(0, (sum, s) => sum + s.episodeCount);
    if (totalExpected == 0) return {};

    // Build a flat pool by fetching TMDB seasons sequentially until we have enough.
    final pool = <TmdbEpisode>[];
    var tmdbSeasonNum = animeSeasonsData.first.tmdbSeasonNumber;

    while (pool.length < totalExpected) {
      try {
        final season = await getSeasonDetails(tmdbId, tmdbSeasonNum);
        final eps = season.episodes;
        if (eps == null || eps.isEmpty) break;
        pool.addAll(eps);
        tmdbSeasonNum++;
      } catch (_) {
        break;
      }
    }

    if (pool.isEmpty) return {};

    // Build streaming episode title map: absoluteEpisodeNumber → realTitle
    final titleMap = <int, String>{};
    for (final animeSeason in animeSeasonsData) {
      for (final streamEp in animeSeason.streamingEpisodes) {
        if (streamEp.title == null) continue;
        final parsed = _parseStreamingTitle(streamEp.title!);
        if (parsed != null) {
          titleMap[parsed.$1] = parsed.$2;
        }
      }
    }

    // Redistribute pool into AniList seasons and enrich titles.
    final result = <int, List<TmdbEpisode>>{};
    var offset = 0;

    for (final animeSeason in animeSeasonsData) {
      final count = animeSeason.episodeCount;
      final slice = pool.skip(offset).take(count).toList();
      final episodes = <TmdbEpisode>[];

      for (var i = 0; i < slice.length; i++) {
        final original = slice[i];
        final absoluteNum = offset + i + 1;
        final relativeNum = i + 1;

        // Title enrichment: only replace placeholder titles.
        var name = original.name;
        if (_isPlaceholderTitle(name)) {
          final realTitle = titleMap[absoluteNum];
          if (realTitle != null && realTitle.isNotEmpty) {
            name = realTitle;
          }
        }

        // Inject precise airingAt for the next airing episode of this AniList season.
        DateTime? airingAt;
        final nextAiring = animeSeason.nextAiringEpisode;
        if (nextAiring != null && relativeNum == nextAiring.episode) {
          airingAt = nextAiring.airingDateTime;
        }

        episodes.add(TmdbEpisode(
          episodeNumber: relativeNum,
          name: name,
          overview: original.overview,
          stillPath: original.stillPath,
          airDate: original.airDate,
          voteAverage: original.voteAverage,
          absoluteEpisodeNumber: absoluteNum,
          airingAt: airingAt,
        ));
      }

      result[animeSeason.seasonNumber] = episodes;
      offset += count;
    }

    return result;
  }

  // ── Title parsing helpers ─────────────────────────────────────────────────

  static final _placeholderRe =
      RegExp(r'^Episod(?:io|e)\s+\d+$', caseSensitive: false);

  static final _streamingTitleRe =
      RegExp(r'^E?pisode?\s*(\d+)\s*[-–]\s*(.+)$', caseSensitive: false);

  static bool _isPlaceholderTitle(String name) =>
      _placeholderRe.hasMatch(name.trim());

  /// Returns (episodeNumber, realTitle) or null if the format is not recognized.
  static (int, String)? _parseStreamingTitle(String title) {
    final match = _streamingTitleRe.firstMatch(title.trim());
    if (match == null) return null;
    final num = int.tryParse(match.group(1)!);
    final realTitle = match.group(2)?.trim();
    if (num == null || realTitle == null || realTitle.isEmpty) return null;
    return (num, realTitle);
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
