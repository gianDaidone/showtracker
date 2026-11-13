import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/database/app_database.dart';
import '../domain/models/sync_payload.dart';
import '../utils/range_utils.dart';
import '../utils/sync_compressor.dart';

import '../../series/providers/series_providers.dart';
import '../../games/providers/games_providers.dart';
import '../../series/data/tmdb_service.dart';
import '../../games/data/rawg_service.dart';

final syncServiceProvider = Provider.autoDispose<SyncService>((ref) {
  return SyncService(
    ref.watch(databaseProvider),
    ref.watch(showsDaoProvider),
    ref.watch(gamesDaoProvider),
    ref.watch(moviesDaoProvider),
    ref.watch(tmdbServiceProvider),
    ref.watch(rawgServiceProvider),
  );
});

class SyncService {
  final AppDatabase _db;
  final ShowsDao _showsDao;
  final GamesDao _gamesDao;
  final MoviesDao _moviesDao;
  final TmdbService _tmdbService;
  final RawgService _rawgService;

  SyncService(this._db, this._showsDao, this._gamesDao, this._moviesDao,
      this._tmdbService, this._rawgService);

  Future<SyncPayload> exportData() async {
    final showsMap = <String, ShowSyncData>{};
    final gamesMap = <String, GameSyncData>{};
    final moviesMap = <String, MovieSyncData>{};

    // Export Shows
    final shows = await _showsDao.getAll();
    final watchedByShow = <int, List<TrackedEpisode>>{};
    for (final ep in await _showsDao.getAllWatchedEpisodes()) {
      watchedByShow.putIfAbsent(ep.showId, () => []).add(ep);
    }
    for (final show in shows) {
      final eps = watchedByShow[show.id] ?? const <TrackedEpisode>[];
      final epsMap = <String, String>{};

      final epsBySeason = <int, List<int>>{};
      for (final ep in eps) {
        epsBySeason
            .putIfAbsent(ep.seasonNumber, () => [])
            .add(ep.episodeNumber);
      }

      for (final entry in epsBySeason.entries) {
        epsMap[entry.key.toString()] =
            RangeUtils.compactListToRange(entry.value);
      }

      showsMap[show.tmdbId.toString()] = ShowSyncData(
        status: show.status.name,
        updatedAt:
            (show.updatedAt ?? show.addedAt).millisecondsSinceEpoch ~/ 1000,
        eps: epsMap,
      );
    }

    // Export Games
    final games = await _gamesDao.watchAll().first;
    for (final game in games) {
      gamesMap[game.rawgId.toString()] = GameSyncData(
        status: game.status.name,
        updatedAt:
            (game.updatedAt ?? game.addedAt).millisecondsSinceEpoch ~/ 1000,
      );
    }

    // Export Movies
    final movies = await _moviesDao.watchAll().first;
    for (final movie in movies) {
      moviesMap[movie.tmdbId.toString()] = MovieSyncData(
        status: movie.status.name,
        updatedAt:
            (movie.updatedAt ?? movie.addedAt).millisecondsSinceEpoch ~/ 1000,
      );
    }

    return SyncPayload(shows: showsMap, games: gamesMap, movies: moviesMap);
  }

  Future<void> importData(SyncPayload payload) async {
    await _db.transaction(() async {
      // Import Shows
      for (final entry in payload.shows.entries) {
        final tmdbId = int.tryParse(entry.key);
        if (tmdbId == null) continue;

        final incomingData = entry.value;
        final incomingDate =
            DateTime.fromMillisecondsSinceEpoch(incomingData.updatedAt * 1000);
        final incomingStatus = MediaStatus.values.firstWhere(
            (e) => e.name == incomingData.status,
            orElse: () => MediaStatus.watching);

        var existingShow = await _showsDao.getByTmdbId(tmdbId);
        int showId;

        if (existingShow == null) {
          showId = await _showsDao.insertShow(TrackedShowsCompanion(
            tmdbId: Value(tmdbId),
            title: const Value(
                'Sconosciuto'), // Fallback as requested not to send titles
            status: Value(incomingStatus),
            addedAt: Value(DateTime.now()),
            updatedAt: Value(incomingDate),
          ));
        } else {
          showId = existingShow.id;
          final existingDate = existingShow.updatedAt ?? existingShow.addedAt;

          if (incomingDate.isAfter(existingDate)) {
            await _showsDao.updateStatus(showId, incomingStatus);
            // updateStatus sets updatedAt to now(), we might want to preserve incomingDate
            await (_db.update(_db.trackedShows)
                  ..where((t) => t.id.equals(showId)))
                .write(TrackedShowsCompanion(updatedAt: Value(incomingDate)));
          }
        }

        // Merge episodes
        final allLocalEps = await _showsDao.getEpisodesByShow(showId);
        final watchedLocally = <int, Set<int>>{};
        for (final ep in allLocalEps) {
          if (ep.watched) {
            watchedLocally
                .putIfAbsent(ep.seasonNumber, () => {})
                .add(ep.episodeNumber);
          }
        }

        for (final epsEntry in incomingData.eps.entries) {
          final season = int.tryParse(epsEntry.key);
          if (season == null) continue;

          final incomingEps = RangeUtils.expandRangeToList(epsEntry.value);
          final localSeasonEps = watchedLocally[season] ?? {};

          for (final epNum in incomingEps) {
            if (!localSeasonEps.contains(epNum)) {
              await _db.into(_db.trackedEpisodes).insert(
                    TrackedEpisodesCompanion(
                      showId: Value(showId),
                      seasonNumber: Value(season),
                      episodeNumber: Value(epNum),
                      watched: const Value(true),
                      updatedAt: Value(incomingDate),
                    ),
                    mode: InsertMode.insertOrReplace,
                  );
            }
          }
        }
      }

      // Import Games
      for (final entry in payload.games.entries) {
        final rawgId = int.tryParse(entry.key);
        if (rawgId == null) continue;

        final incomingData = entry.value;
        final incomingDate =
            DateTime.fromMillisecondsSinceEpoch(incomingData.updatedAt * 1000);
        final incomingStatus = MediaStatus.values.firstWhere(
            (e) => e.name == incomingData.status,
            orElse: () => MediaStatus.watching);

        final existingGame = await _gamesDao.getByRawgId(rawgId);
        if (existingGame == null) {
          await _gamesDao.insertGame(TrackedGamesCompanion(
            rawgId: Value(rawgId),
            title: const Value('Sconosciuto'),
            status: Value(incomingStatus),
            addedAt: Value(DateTime.now()),
            updatedAt: Value(incomingDate),
          ));
        } else {
          final existingDate = existingGame.updatedAt ?? existingGame.addedAt;
          if (incomingDate.isAfter(existingDate)) {
            await _gamesDao.updateStatus(existingGame.id, incomingStatus);
            await (_db.update(_db.trackedGames)
                  ..where((t) => t.id.equals(existingGame.id)))
                .write(TrackedGamesCompanion(updatedAt: Value(incomingDate)));
          }
        }
      }

      // Import Movies
      for (final entry in payload.movies.entries) {
        final tmdbId = int.tryParse(entry.key);
        if (tmdbId == null) continue;

        final incomingData = entry.value;
        final incomingDate =
            DateTime.fromMillisecondsSinceEpoch(incomingData.updatedAt * 1000);
        // I film non hanno lo stato "In visione": un dispositivo con una
        // versione precedente può ancora inviarlo, lo trattiamo come "Da vedere".
        var incomingStatus = MediaStatus.values.firstWhere(
            (e) => e.name == incomingData.status,
            orElse: () => MediaStatus.planToWatch);
        if (incomingStatus == MediaStatus.watching) {
          incomingStatus = MediaStatus.planToWatch;
        }

        final existingMovie = await _moviesDao.getByTmdbId(tmdbId);
        if (existingMovie == null) {
          await _moviesDao.insertMovie(TrackedMoviesCompanion(
            tmdbId: Value(tmdbId),
            title: const Value('Sconosciuto'),
            status: Value(incomingStatus),
            addedAt: Value(DateTime.now()),
            updatedAt: Value(incomingDate),
          ));
        } else {
          final existingDate = existingMovie.updatedAt ?? existingMovie.addedAt;
          if (incomingDate.isAfter(existingDate)) {
            await _moviesDao.updateStatus(existingMovie.id, incomingStatus);
            await (_db.update(_db.trackedMovies)
                  ..where((t) => t.id.equals(existingMovie.id)))
                .write(TrackedMoviesCompanion(updatedAt: Value(incomingDate)));
          }
        }
      }
    });
  }

  /// Recupera solo i metadati dei placeholder, senza alterare i dati personali.
  /// [isCurrent] interrompe il passaggio se le credenziali cambiano in volo.
  Future<void> hydrateUnknownMedia({
    bool shows = true,
    bool movies = true,
    bool games = true,
    bool Function()? isCurrent,
  }) async {
    bool current() => isCurrent?.call() ?? true;

    // 1. Shows: mantiene il percorso metadata preesistente.
    if (!current()) return;
    if (shows) {
      try {
        final unknownShows = await (_db.select(_db.trackedShows)
              ..where((t) => t.title.equals('Sconosciuto')))
            .get();
        for (final show in unknownShows) {
          if (!current()) return;
          try {
            final details = await _tmdbService.getShowDetails(show.tmdbId);
            if (!current()) return;
            final title = _validHydrationTitle(details.name);
            if (title == null) continue;

            final tmdbNext = details.nextEpisodeToAir;
            int? nextSeason;
            int? nextEpisode;
            String? nextName;
            DateTime? nextDate;

            if (tmdbNext != null) {
              nextSeason = tmdbNext.seasonNumber;
              nextEpisode = tmdbNext.episodeNumber;
              nextName = tmdbNext.name;
              if (tmdbNext.airDate != null) {
                final d = DateTime.tryParse(tmdbNext.airDate!);
                if (d != null) {
                  nextDate = DateTime(d.year, d.month, d.day, 9, 0);
                }
              }
            }

            await (_db.update(_db.trackedShows)
                  ..where((t) => t.id.equals(show.id)))
                .write(
              TrackedShowsCompanion(
                title: Value(title),
                posterPath: Value(details.posterPath),
                overview: Value(details.overview),
                totalSeasons: Value(details.numberOfSeasons),
                totalEpisodes: Value(details.numberOfEpisodes),
                tmdbStatus: Value(details.status),
                isAnime: Value(details.isAnime),
                nextEpisodeNumber: Value(nextEpisode),
                nextEpisodeSeason: Value(nextSeason),
                nextEpisodeName: Value(nextName),
                nextEpisodeAirDate: Value(nextDate),
              ),
            );
          } catch (_) {
            // Le eccezioni HTTP possono contenere URL con credenziali.
            debugPrint('Errore idratazione serie ${show.id}');
          }
        }
      } catch (_) {}
    }

    // 2. Movies
    if (!current()) return;
    if (movies) {
      try {
        final unknownMovies = await (_db.select(_db.trackedMovies)
              ..where((t) => t.title.equals('Sconosciuto')))
            .get();
        for (final movie in unknownMovies) {
          if (!current()) return;
          try {
            final details = await _tmdbService.getMovieDetails(movie.tmdbId);
            if (!current()) return;
            final title = _validHydrationTitle(details.title);
            if (title == null) continue;

            int? releaseYear;
            DateTime? releaseDate;
            if (details.releaseDate != null &&
                details.releaseDate!.isNotEmpty) {
              releaseDate = DateTime.tryParse(details.releaseDate!);
              releaseYear = releaseDate?.year;
            }

            await (_db.update(_db.trackedMovies)
                  ..where((t) =>
                      t.id.equals(movie.id) &
                      t.tmdbId.equals(movie.tmdbId) &
                      t.title.equals('Sconosciuto')))
                .write(
              TrackedMoviesCompanion(
                title: Value(title),
                posterPath: Value(details.posterPath),
                overview: Value(details.overview),
                releaseYear: Value(releaseYear),
                releaseDate: Value(releaseDate),
              ),
            );
          } catch (_) {}
        }
      } catch (_) {}
    }

    // 3. Games
    if (!current()) return;
    if (games) {
      try {
        final unknownGames = await (_db.select(_db.trackedGames)
              ..where((t) => t.title.equals('Sconosciuto')))
            .get();
        for (final game in unknownGames) {
          if (!current()) return;
          try {
            final details = await _rawgService.getGameDetails(game.rawgId);
            if (!current()) return;
            final title = _validHydrationTitle(details.name);
            if (title == null) continue;

            // Nessuna transazione durante la rete: rileggere il playtime dopo
            // il fetch preserva anche le modifiche locali fatte nel frattempo.
            await _db.transaction(() async {
              final latest = await (_db.select(_db.trackedGames)
                    ..where((t) =>
                        t.id.equals(game.id) &
                        t.rawgId.equals(game.rawgId) &
                        t.title.equals('Sconosciuto')))
                  .getSingleOrNull();
              if (!current() || latest == null) return;

              await (_db.update(_db.trackedGames)
                    ..where((t) =>
                        t.id.equals(game.id) &
                        t.rawgId.equals(game.rawgId) &
                        t.title.equals('Sconosciuto')))
                  .write(
                TrackedGamesCompanion(
                  title: Value(title),
                  coverUrl: Value(details.coverUrl),
                  releaseDate: Value(details.releaseDateParsed),
                  playtime: Value(latest.playtime ?? details.playtime),
                  platforms: Value(details.platforms.isNotEmpty
                      ? jsonEncode(details.platforms)
                      : null),
                  voteAverage: Value(
                      details.voteAverage > 0 ? details.voteAverage : null),
                ),
              );
            });
          } catch (_) {}
        }
      } catch (_) {}
    }
  }

  static String? _validHydrationTitle(String value) {
    final title = value.trim();
    if (title.isEmpty ||
        title.toLowerCase() == 'sconosciuto' ||
        title.toLowerCase() == 'titolo sconosciuto') {
      return null;
    }
    return title;
  }
}
