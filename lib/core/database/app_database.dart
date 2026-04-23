import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/enums.dart';
import 'tables/tracked_shows.dart';
import 'tables/tracked_episodes.dart';
import 'tables/tracked_seasons.dart';
import 'tables/cached_episodes.dart';
import 'tables/tracked_movies.dart';
import 'tables/tracked_games.dart';
import 'daos/shows_dao.dart';
import 'daos/movies_dao.dart';
import 'daos/games_dao.dart';
import 'daos/cache_dao.dart';

export 'tables/enums.dart';
export 'tables/tracked_shows.dart';
export 'tables/tracked_episodes.dart';
export 'tables/tracked_seasons.dart';
export 'tables/cached_episodes.dart';
export 'tables/tracked_movies.dart';
export 'tables/tracked_games.dart';
export 'daos/shows_dao.dart';
export 'daos/movies_dao.dart';
export 'daos/games_dao.dart';
export 'daos/cache_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    TrackedShows,
    TrackedEpisodes,
    TrackedSeasons,
    CachedEpisodes,
    TrackedMovies,
    TrackedGames,
  ],
  daos: [ShowsDao, MoviesDao, GamesDao, CacheDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase._() : super(_openConnection());

  static final AppDatabase instance = AppDatabase._();

  @override
  int get schemaVersion => 8;

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
            // Rinomina igdb_id → rawg_id e aggiunge le nuove colonne.
            // Usiamo la tecnica create+copy+drop per compatibilità con SQLite < 3.25.
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
        },
      );
}

QueryExecutor _openConnection() {
  return driftDatabase(name: 'showtracker');
}
