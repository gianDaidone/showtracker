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

  Future<Map<int, List<TmdbEpisode>>> getAnimeEpisodesBySeason(
    int tmdbId,
    List<NormalizedAnimeSeason> animeSeasonsData,
  ) async {
    if (animeSeasonsData.isEmpty) return {};

    // 1. Fetch TMDB seasons
    final tmdbSeasonsMap = <int, List<TmdbEpisode>>{};
    final tmdbSeasonsToFetch = animeSeasonsData.map((s) => s.tmdbSeasonNumber).toSet();
    
    await Future.wait(tmdbSeasonsToFetch.map((tmdbSeasonNum) async {
      try {
        final season = await getSeasonDetails(tmdbId, tmdbSeasonNum);
        final eps = season.episodes;
        if (eps != null && eps.isNotEmpty) {
          tmdbSeasonsMap[tmdbSeasonNum] = eps;
        }
      } catch (_) {}
    }));

    if (tmdbSeasonsMap.isEmpty) return {};

    // 2. Build streaming episode title map
    final titleMap = <int, String>{};
    int absoluteIdx = 1;
    for (final animeSeason in animeSeasonsData) {
      for (final streamEp in animeSeason.streamingEpisodes) {
        if (streamEp.title == null) continue;
        final parsed = _parseStreamingTitle(streamEp.title!);
        if (parsed != null) {
          titleMap[parsed.$1] = parsed.$2;
        }
      }
    }

    // 3. Smart group AniList seasons to TMDB seasons to handle OVA discrepancies
    final adjustedCounts = <int, int>{};
    
    // Group AniList seasons by tmdbSeasonNumber
    final groupedAniSeasons = <int, List<NormalizedAnimeSeason>>{};
    for (final s in animeSeasonsData) {
      groupedAniSeasons.putIfAbsent(s.tmdbSeasonNumber, () => []).add(s);
    }

    for (final entry in groupedAniSeasons.entries) {
      final tmdbSeasonNum = entry.key;
      final aniGroup = entry.value;
      final tmdbEpsCount = tmdbSeasonsMap[tmdbSeasonNum]?.length ?? 0;
      
      int groupSum = aniGroup.fold(0, (sum, s) => sum + s.episodeCount);
      
      if (tmdbEpsCount > 0 && groupSum > 0) {
        if (groupSum == tmdbEpsCount || (groupSum - tmdbEpsCount).abs() <= 2) {
          int diff = tmdbEpsCount - groupSum;
          for (int j = 0; j < aniGroup.length; j++) {
            final s = aniGroup[j];
            if (j == 0) {
              adjustedCounts[s.seasonNumber] = s.episodeCount + diff;
            } else {
              adjustedCounts[s.seasonNumber] = s.episodeCount;
            }
          }
          continue;
        }
      }
      
      for (final s in aniGroup) {
        adjustedCounts[s.seasonNumber] = s.episodeCount;
      }
    }

    // 4. Distribute TMDB episodes into AniList seasons by matching tmdbSeasonNumber
    final result = <int, List<TmdbEpisode>>{};
    absoluteIdx = 1;

    for (final entry in groupedAniSeasons.entries) {
      final tmdbSeasonNum = entry.key;
      final aniSeasons = entry.value;
      final tmdbEpisodes = tmdbSeasonsMap[tmdbSeasonNum] ?? <TmdbEpisode>[];
      
      var offset = 0;
      for (var i = 0; i < aniSeasons.length; i++) {
        final animeSeason = aniSeasons[i];
        int count = adjustedCounts[animeSeason.seasonNumber] ?? animeSeason.episodeCount;
        
        // Se non conosciamo la durata (0) o se è l'ultimo cour del gruppo, 
        // assegniamo tutti gli episodi rimanenti.
        if (count == 0 || i == aniSeasons.length - 1) {
          count = tmdbEpisodes.length - offset;
        }
        
        // Se abbiamo bisogno di più episodi di quelli disponibili, prendiamo solo il rimanente.
        if (count < 0) count = 0;
        final actualTake = (offset + count <= tmdbEpisodes.length) 
            ? count 
            : tmdbEpisodes.length - offset;
            
        final slice = tmdbEpisodes.skip(offset).take(actualTake).toList();
        final episodes = <TmdbEpisode>[];

        for (var j = 0; j < slice.length; j++) {
          final original = slice[j];
          final relativeNum = j + 1;

          var name = original.name;
          if (_isPlaceholderTitle(name)) {
            final realTitle = titleMap[absoluteIdx];
            if (realTitle != null && realTitle.isNotEmpty) {
              name = realTitle;
            }
          }

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
            absoluteEpisodeNumber: absoluteIdx,
            airingAt: airingAt,
          ));
          
          absoluteIdx++;
        }

        result[animeSeason.seasonNumber] = episodes;
        offset += actualTake;
      }
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
