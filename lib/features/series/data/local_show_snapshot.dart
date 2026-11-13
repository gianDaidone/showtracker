import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../core/database/app_database.dart';
import 'models/tmdb_episode.dart';
import 'models/tmdb_season.dart';
import 'models/tmdb_show_detail.dart';
import 'tmdb_service.dart';
import 'watch_next_rules.dart';

/// Errori per cui i dati salvati sono un fallback, non una risposta HTTP valida.
bool isRecoverableSeriesError(Object error) =>
    error is http.ClientException ||
    error is SocketException ||
    error is TimeoutException ||
    (error is TmdbException && (error.statusCode ?? 0) >= 500);

TmdbShowDetail localShowSnapshot(TrackedShow show, Map<int, int> seasonCounts) {
  final ordered = seasonCounts.keys.toList()..sort();
  return TmdbShowDetail(
    id: show.tmdbId,
    name: show.title,
    overview: show.overview,
    posterPath: show.posterPath,
    status: show.tmdbStatus,
    inProduction: show.tmdbStatus == 'Returning Series' ||
        show.tmdbStatus == 'In Production',
    numberOfSeasons: show.totalSeasons,
    numberOfEpisodes: show.totalEpisodes,
    genres: const [],
    originCountries: const [],
    isLocalSnapshot: true,
    isAnimeOverride: show.isAnime,
    // Per gli anime i conteggi DB sono già cour, non stagioni TMDB:
    // saranno composti con la mappatura persistita, mai arricchiti come grezzi.
    seasons: show.isAnime
        ? const []
        : [
            for (final number in ordered)
              TmdbSeason(
                  seasonNumber: number,
                  episodeCount: seasonCounts[number]!,
                  name: 'Stagione $number',
                  isLocalSnapshot: true),
          ],
    nextEpisodeToAir:
        show.nextEpisodeNumber != null && show.nextEpisodeSeason != null
            ? TmdbNextEpisode(
                seasonNumber: show.nextEpisodeSeason!,
                episodeNumber: show.nextEpisodeNumber!,
                name: show.nextEpisodeName ?? '',
                airDate: show.nextEpisodeAirDate?.toIso8601String(),
              )
            : null,
  );
}

TmdbSeason cachedSeasonSnapshot(int number, List<CachedEpisode> rows,
        {String? name, bool isLocalSnapshot = false, TrackedShow? show}) =>
    TmdbSeason(
      seasonNumber: number,
      episodeCount: rows.length,
      name: name,
      isLocalSnapshot: isLocalSnapshot,
      episodes: [
        for (final row in rows)
          withStoredAiringTime(
              TmdbEpisode(
                episodeNumber: row.episodeNumber,
                name: row.name,
                overview: row.overview,
                stillPath: row.stillPath,
                airDate: row.airDate,
                voteAverage: row.voteAverage,
                absoluteEpisodeNumber: row.absoluteEpisodeNumber,
                airingAt: row.airingAt,
              ),
              show,
              number),
      ],
    );
