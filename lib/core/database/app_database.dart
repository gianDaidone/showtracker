import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/enums.dart';
import 'tables/tracked_shows.dart';
import 'tables/tracked_episodes.dart';
import 'tables/tracked_seasons.dart';
import 'tables/cached_episodes.dart';
import 'tables/tracked_movies.dart';
import 'tables/tracked_games.dart';
import 'tables/yuna_cache.dart';
import 'tables/anime_season_cache.dart';
import 'daos/shows_dao.dart';
import 'daos/movies_dao.dart';
import 'daos/games_dao.dart';
import 'daos/cache_dao.dart';
import 'daos/anime_cache_dao.dart';

export 'tables/enums.dart';
export 'tables/tracked_shows.dart';
export 'tables/tracked_episodes.dart';
export 'tables/tracked_seasons.dart';
export 'tables/cached_episodes.dart';
export 'tables/tracked_movies.dart';
export 'tables/tracked_games.dart';
export 'tables/yuna_cache.dart';
export 'tables/anime_season_cache.dart';
export 'daos/shows_dao.dart';
export 'daos/movies_dao.dart';
export 'daos/games_dao.dart';
export 'daos/cache_dao.dart';
export 'daos/anime_cache_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    TrackedShows,
    TrackedEpisodes,
    TrackedSeasons,
    CachedEpisodes,
    TrackedMovies,
    TrackedGames,
    YunaCache,
    AnimeSeasonCache,
  ],
  daos: [ShowsDao, MoviesDao, GamesDao, CacheDao, AnimeCacheDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase._() : super(_openConnection());

  static final AppDatabase instance = AppDatabase._();

  @override
  int get schemaVersion => 10;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(trackedShows, trackedShows.totalEpisodes);
          }
          if (from < 3) {
            await m.createTable(trackedSeasons);
          }
          if (from < 4) {
            await m.createTable(cachedEpisodes);
          }
          if (from < 5) {
            await m.addColumn(trackedShows, trackedShows.tmdbStatus);
          }
          if (from < 6) {
            await m.addColumn(trackedMovies, trackedMovies.releaseDate);
          }
          if (from < 7) {
            await customStatement('DROP TABLE IF EXISTS tracked_books');
          }
          if (from < 8) {
            await customStatement('''
              CREATE TABLE IF NOT EXISTS tracked_games_v8 (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                rawg_id INTEGER NOT NULL UNIQUE,
                title TEXT NOT NULL,
                cover_url TEXT,
                status TEXT NOT NULL,
                user_rating REAL,
                user_notes TEXT,
                added_at INTEGER NOT NULL,
                release_date INTEGER,
                playtime INTEGER,
                platforms TEXT,
                vote_average REAL
              )
            ''');
            await customStatement('''
              INSERT INTO tracked_games_v8
                (id, rawg_id, title, cover_url, status, user_rating, user_notes, added_at)
              SELECT id, igdb_id, title, cover_url, status, user_rating, user_notes, added_at
              FROM tracked_games
            ''');
            await customStatement('DROP TABLE tracked_games');
            await customStatement(
                'ALTER TABLE tracked_games_v8 RENAME TO tracked_games');
          }
          if (from < 9) {
            await m.addColumn(trackedShows, trackedShows.isAnime);
            await m.addColumn(
                cachedEpisodes, cachedEpisodes.absoluteEpisodeNumber);
            await m.addColumn(cachedEpisodes, cachedEpisodes.airingAt);
            await m.createTable(yunaCache);
            await m.createTable(animeSeasonCache);
          }
          if (from < 10) {
            await m.addColumn(trackedShows, trackedShows.lastWatchedAt);
          }
        },
      );
}

QueryExecutor _openConnection() {
  return driftDatabase(name: 'showtracker');
}
