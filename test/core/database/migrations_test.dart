import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:showtracker/core/database/app_database.dart';

void main() {
  test('schema corrente espone tabelle, colonne e vincoli essenziali',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await db.customSelect('SELECT 1').get();
    expect(
        (await db.customSelect('PRAGMA user_version').getSingle())
            .read<int>('user_version'),
        14);
    final tables = await db
        .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%'")
        .get();
    expect(
        tables.map((r) => r.read<String>('name')),
        unorderedEquals([
          'tracked_shows',
          'tracked_episodes',
          'tracked_seasons',
          'tracked_movies',
          'tracked_games',
          'cached_episodes',
          'yuna_cache',
          'anime_season_cache',
        ]));
    for (final table in [
      'tracked_shows',
      'tracked_movies',
      'tracked_games',
      'tracked_episodes'
    ]) {
      final columns = await db.customSelect('PRAGMA table_info($table)').get();
      expect(
          columns.map((r) => r.read<String>('name')), contains('updated_at'));
    }
    final showColumns =
        await db.customSelect('PRAGMA table_info(tracked_shows)').get();
    expect(
        showColumns.map((r) => r.read<String>('name')),
        containsAll([
          'is_anime',
          'last_watched_at',
          'next_episode_number',
          'next_episode_season',
          'next_episode_name',
          'next_episode_air_date',
        ]));
    for (final table in ['tracked_episodes', 'tracked_seasons']) {
      final fk =
          await db.customSelect('PRAGMA foreign_key_list($table)').getSingle();
      expect(fk.read<String>('table'), 'tracked_shows');
      expect(fk.read<String>('from'), 'show_id');
      expect(fk.read<String>('to'), 'id');
    }
    for (final entry in {
      'tracked_shows': ['tmdb_id'],
      'tracked_movies': ['tmdb_id'],
      'tracked_games': ['rawg_id'],
      'tracked_episodes': ['show_id', 'season_number', 'episode_number'],
      'tracked_seasons': ['show_id', 'season_number'],
      'cached_episodes': ['tmdb_show_id', 'season_number', 'episode_number'],
      'anime_season_cache': ['tmdb_show_id', 'season_number'],
    }.entries) {
      final indexes =
          await db.customSelect('PRAGMA index_list(${entry.key})').get();
      final uniqueColumns = <List<String>>[];
      for (final index in indexes.where((r) => r.read<int>('unique') == 1)) {
        final name = index.read<String>('name');
        final columns =
            await db.customSelect('PRAGMA index_info("$name")').get();
        uniqueColumns.add(columns.map((r) => r.read<String>('name')).toList());
      }
      expect(uniqueColumns, contains(orderedEquals(entry.value)),
          reason: 'Vincolo unico ${entry.key}');
    }
  });

  test('v12 → v14 aggiunge e riempie timestamp senza perdere progressi/cache',
      () async {
    final before = DateTime.now().subtract(const Duration(seconds: 2));
    final db = historicalDatabase(12);
    addTearDown(db.close);
    final shows = await db.showsDao.getAll();
    final after = DateTime.now().add(const Duration(seconds: 2));
    final show = shows.single;
    expect(show.id, 10);
    expect(show.tmdbId, 73223);
    expect(show.title, 'Serie storica');
    expect(show.userRating, 8.5);
    expect(show.userNotes, 'Nota serie');
    expect(show.totalEpisodes, 24);
    expect(show.totalSeasons, 2);
    expect(show.isAnime, isTrue);
    expect(show.lastWatchedAt!.millisecondsSinceEpoch ~/ 1000, 1700000001);
    expect(show.nextEpisodeNumber, 3);
    expect(show.nextEpisodeSeason, 2);
    expect(show.nextEpisodeName, 'Prossimo');
    expect(show.nextEpisodeAirDate!.millisecondsSinceEpoch ~/ 1000, 1900000000);
    expect(show.updatedAt!.isAtSameMomentAs(show.addedAt), isTrue);
    final game = (await db.gamesDao.getByRawgId(100))!;
    expect(game.updatedAt!.isAtSameMomentAs(game.addedAt), isTrue);
    expect(game.title, 'Gioco storico');
    expect(game.playtime, 42);
    expect(game.platforms, '["PC"]');
    expect(game.voteAverage, 4.5);
    final movie = (await db.moviesDao.getByTmdbId(101))!;
    expect(movie.status, MediaStatus.planToWatch);
    expect(movie.updatedAt!.isAtSameMomentAs(movie.addedAt), isTrue);
    expect(movie.userRating, 7.5);
    expect(movie.releaseYear, 2020);
    final episodes = await db.showsDao.getEpisodesByShow(10);
    expect(episodes.map((e) => e.watched), [true, false]);
    for (final episode in episodes) {
      expect(episode.updatedAt!.isAfter(before), isTrue);
      expect(episode.updatedAt!.isBefore(after), isTrue);
    }
    expect(await db.showsDao.countWatchedEpisodes(10), 1);
    expect(await db.showsDao.getSeasonCounts(10), {1: 12, 2: 12});
    await verifyHistoricalCache(db);
    await verifyUpgradedDatabase(db);
  });

  test('v13 → v14 normalizza solo film watching e preserva timestamp/null',
      () async {
    final db = historicalDatabase(13);
    addTearDown(db.close);
    final movies = await db.moviesDao.watchAll().first;
    expect({
      for (final m in movies) m.tmdbId: m.status
    }, {
      101: MediaStatus.planToWatch,
      102: MediaStatus.completed,
      103: MediaStatus.paused,
      104: MediaStatus.dropped,
      105: MediaStatus.planToWatch,
    });
    for (final movie in movies) {
      expect(movie.updatedAt!.millisecondsSinceEpoch ~/ 1000, 1800000000);
    }
    final show = (await db.showsDao.getById(10))!;
    expect(show.status, MediaStatus.watching);
    expect(show.updatedAt!.millisecondsSinceEpoch ~/ 1000, 1800000000);
    final game = (await db.gamesDao.getByRawgId(100))!;
    expect(game.status, MediaStatus.watching);
    expect(game.updatedAt!.millisecondsSinceEpoch ~/ 1000, 1800000000);
    final episodes = await db.showsDao.getEpisodesByShow(10);
    expect(
        episodes.first.updatedAt!.millisecondsSinceEpoch ~/ 1000, 1800000000);
    expect(episodes.last.updatedAt, isNull);
    expect(await db.showsDao.getSeasonCounts(10), {1: 12, 2: 12});
    await verifyHistoricalCache(db);
    await verifyUpgradedDatabase(db);
  });
}

Future<void> verifyHistoricalCache(AppDatabase db) async {
  final cached =
      (await db.cacheDao.getSeasonEpisodesIgnoringTtl(73223, 1)).single;
  expect(cached.name, 'Pilota storico');
  expect(cached.absoluteEpisodeNumber, 1);
  expect(cached.airingAt!.millisecondsSinceEpoch ~/ 1000, 1700000000);
  expect(await db.animeCacheDao.getYunaIds(73223), isNull);
  final anime = (await db.animeCacheDao.getStaleAnimeSeasons(73223))!.single;
  expect(anime.anilistId, 101);
  expect(anime.episodeCount, 12);
  expect(await db.animeCacheDao.getFreshAnimeSeasons(73223), isNull);
}

Future<void> verifyUpgradedDatabase(AppDatabase db) async {
  expect(
      (await db.customSelect('PRAGMA user_version').getSingle())
          .read<int>('user_version'),
      14);
  expect(await db.customSelect('PRAGMA foreign_key_check').get(), isEmpty);
  expect(
      (await db.customSelect('PRAGMA integrity_check').getSingle())
          .read<String>('integrity_check'),
      'ok');
  // Le nuove colonne non sono soltanto leggibili: rimangono scrivibili.
  await db.showsDao.markEpisodeWatched(10, 2, 1);
  await db.showsDao.insertSeasons(10, {2: 13});
  await db.moviesDao.updateRating(1, null);
  await db.gamesDao.updateStatus(1, MediaStatus.completed);
  expect(await db.showsDao.countWatchedEpisodes(10), 2);
  expect(await db.showsDao.getSeasonCounts(10), {1: 12, 2: 13});
  expect((await db.moviesDao.getByTmdbId(101))!.userRating, isNull);
  expect((await db.gamesDao.getByRawgId(100))!.status, MediaStatus.completed);
}

// DDL storico trascritto dalle tabelle a 0e14633 (schema 12) ed e5968e7
// (schema 13): git diff 0e14633 e5968e7 -- lib/core/database/tables mostra
// soltanto l'aggiunta di updated_at a serie/episodi/film/giochi.
// NON usa createAll() del DB corrente rinominandolo come una vecchia versione.
// v7 non è ricostruibile fedelmente: il primo commit disponibile c18e816
// contiene già lo schema 8 (rawg_id). Il ramo di migrazione da igdb_id è
// documentato nel codice, ma non prova l'intero DDL storico v7.
AppDatabase historicalDatabase(int version) {
  assert(version == 12 || version == 13);
  final timestamp = version == 13 ? ', updated_at INTEGER' : '';
  return AppDatabase.forTesting(NativeDatabase.memory(setup: (sqlite) {
    sqlite.execute('''
      CREATE TABLE tracked_shows (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        tmdb_id INTEGER NOT NULL UNIQUE,
        title TEXT NOT NULL, overview TEXT, poster_path TEXT,
        status TEXT NOT NULL, user_rating REAL, user_notes TEXT,
        total_seasons INTEGER, total_episodes INTEGER, tmdb_status TEXT,
        is_anime INTEGER NOT NULL DEFAULT 0 CHECK (is_anime IN (0, 1)),
        added_at INTEGER NOT NULL, last_watched_at INTEGER,
        next_episode_number INTEGER, next_episode_season INTEGER,
        next_episode_name TEXT, next_episode_air_date INTEGER$timestamp
      )
    ''');
    sqlite.execute('''
      CREATE TABLE tracked_episodes (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        show_id INTEGER NOT NULL REFERENCES tracked_shows(id),
        season_number INTEGER NOT NULL, episode_number INTEGER NOT NULL,
        watched INTEGER NOT NULL DEFAULT 0 CHECK (watched IN (0, 1))$timestamp,
        UNIQUE (show_id, season_number, episode_number)
      )
    ''');
    sqlite.execute('''
      CREATE TABLE tracked_seasons (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        show_id INTEGER NOT NULL REFERENCES tracked_shows(id),
        season_number INTEGER NOT NULL, episode_count INTEGER NOT NULL,
        UNIQUE (show_id, season_number)
      )
    ''');
    sqlite.execute('''
      CREATE TABLE tracked_movies (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        tmdb_id INTEGER NOT NULL UNIQUE, title TEXT NOT NULL,
        overview TEXT, poster_path TEXT, status TEXT NOT NULL,
        user_rating REAL, user_notes TEXT, release_year INTEGER,
        release_date INTEGER, added_at INTEGER NOT NULL$timestamp
      )
    ''');
    sqlite.execute('''
      CREATE TABLE tracked_games (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        rawg_id INTEGER NOT NULL UNIQUE, title TEXT NOT NULL,
        cover_url TEXT, status TEXT NOT NULL, user_rating REAL, user_notes TEXT,
        added_at INTEGER NOT NULL, release_date INTEGER, playtime INTEGER,
        platforms TEXT, vote_average REAL$timestamp
      )
    ''');
    sqlite.execute('''
      CREATE TABLE cached_episodes (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        tmdb_show_id INTEGER NOT NULL, season_number INTEGER NOT NULL,
        episode_number INTEGER NOT NULL, name TEXT NOT NULL, overview TEXT,
        still_path TEXT, air_date TEXT, vote_average REAL,
        absolute_episode_number INTEGER, airing_at INTEGER,
        cached_at INTEGER NOT NULL,
        UNIQUE (tmdb_show_id, season_number, episode_number)
      )
    ''');
    sqlite.execute('''
      CREATE TABLE yuna_cache (
        tmdb_id INTEGER NOT NULL PRIMARY KEY,
        anilist_ids_json TEXT NOT NULL, cached_at INTEGER NOT NULL
      )
    ''');
    sqlite.execute('''
      CREATE TABLE anime_season_cache (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        tmdb_show_id INTEGER NOT NULL, season_number INTEGER NOT NULL,
        anilist_id INTEGER NOT NULL, episode_count INTEGER NOT NULL,
        status TEXT NOT NULL, anime_season_json TEXT NOT NULL,
        cached_at INTEGER NOT NULL, valid_until INTEGER NOT NULL,
        UNIQUE (tmdb_show_id, season_number)
      )
    ''');
    final showColumns =
        sqlite.select('PRAGMA table_info(tracked_shows)').map((r) => r['name']);
    expect(showColumns.contains('updated_at'), version == 13);
    expect(showColumns, contains('next_episode_number'));
    sqlite.execute('''
      INSERT INTO tracked_shows
        (id, tmdb_id, title, status, user_rating, user_notes, total_seasons,
         total_episodes, tmdb_status, is_anime, added_at, last_watched_at,
         next_episode_number, next_episode_season, next_episode_name,
         next_episode_air_date)
      VALUES (10, 73223, 'Serie storica', 'watching', 8.5, 'Nota serie',
        2, 24, 'Returning Series', 1, 1700000000, 1700000001,
        3, 2, 'Prossimo', 1900000000)
    ''');
    sqlite.execute('''
      INSERT INTO tracked_episodes
        (show_id, season_number, episode_number, watched)
      VALUES (10, 1, 1, 1), (10, 1, 2, 0)
    ''');
    sqlite.execute('''
      INSERT INTO tracked_seasons (show_id, season_number, episode_count)
      VALUES (10, 1, 12), (10, 2, 12)
    ''');
    sqlite.execute('''
      INSERT INTO tracked_games
        (rawg_id, title, cover_url, status, user_rating, user_notes,
         added_at, release_date, playtime, platforms, vote_average)
      VALUES (100, 'Gioco storico', '/cover.jpg', 'watching', 9, 'Nota gioco',
        1700000002, 1600000000, 42, '["PC"]', 4.5)
    ''');
    for (final (index, status) in [
      'watching',
      'completed',
      'paused',
      'dropped',
      'planToWatch'
    ].indexed) {
      sqlite.execute('''
        INSERT INTO tracked_movies
          (tmdb_id, title, status, user_rating, release_year, release_date,
           added_at)
        VALUES (?, 'Film storico', ?, 7.5, 2020, 1600000000, 1700000003)
      ''', [101 + index, status]);
    }
    sqlite.execute('''
      INSERT INTO cached_episodes
        (tmdb_show_id, season_number, episode_number, name,
         absolute_episode_number, airing_at, cached_at)
      VALUES (73223, 1, 1, 'Pilota storico', 1, 1700000000, 1700000000)
    ''');
    sqlite
        .execute("INSERT INTO yuna_cache VALUES (73223, '[101]', 1700000000)");
    sqlite.execute('''
      INSERT INTO anime_season_cache
        (tmdb_show_id, season_number, anilist_id, episode_count, status,
         anime_season_json, cached_at, valid_until)
      VALUES (73223, 1, 101, 12, 'FINISHED',
        '{"seasonNumber":1,"tmdbSeasonNumber":1,"anilistId":101,"episodeCount":12,"status":"FINISHED","streamingEpisodes":[]}',
        1700000000, 1700000001)
    ''');
    if (version == 13) {
      for (final table in [
        'tracked_shows',
        'tracked_movies',
        'tracked_games'
      ]) {
        sqlite.execute('UPDATE $table SET updated_at = 1800000000');
      }
      sqlite.execute('UPDATE tracked_episodes SET updated_at = 1800000000 '
          'WHERE watched = 1');
    }
    sqlite.execute('PRAGMA user_version = $version');
  }));
}
