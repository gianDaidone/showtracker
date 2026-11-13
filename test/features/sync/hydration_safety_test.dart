import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:showtracker/core/database/app_database.dart';
import 'package:showtracker/features/games/data/rawg_service.dart';
import 'package:showtracker/features/series/data/tmdb_service.dart';
import 'package:showtracker/features/sync/domain/models/sync_payload.dart';
import 'package:showtracker/features/sync/services/sync_service.dart';

final _addedAt = DateTime.utc(2025, 1, 2, 3);
final _updatedAt = DateTime.utc(2026, 10, 1, 12);

SyncService _service(AppDatabase db, http.Client client) => SyncService(
      db,
      db.showsDao,
      db.gamesDao,
      db.moviesDao,
      TmdbService(client),
      RawgService(client),
    );

Future<void> _seed(AppDatabase db, {bool timestamp = true, int id = 1}) async {
  await db.gamesDao.insertGame(TrackedGamesCompanion.insert(
    rawgId: id,
    title: 'Sconosciuto',
    status: MediaStatus.paused,
    addedAt: _addedAt,
    updatedAt: Value(timestamp ? _updatedAt : null),
    userRating: const Value(7.5),
    userNotes: const Value('Note gioco locali'),
  ));
  await db.moviesDao.insertMovie(TrackedMoviesCompanion.insert(
    tmdbId: id,
    title: 'Sconosciuto',
    status: MediaStatus.completed,
    addedAt: _addedAt,
    updatedAt: Value(timestamp ? _updatedAt : null),
    userRating: const Value(8.5),
    userNotes: const Value('Note film locali'),
  ));
}

List<Object?> _gamePersonal(TrackedGame game) => [
      game.id,
      game.rawgId,
      game.status,
      game.userRating,
      game.userNotes,
      game.addedAt,
      game.updatedAt,
    ];

List<Object?> _moviePersonal(TrackedMovy movie) => [
      movie.id,
      movie.tmdbId,
      movie.status,
      movie.userRating,
      movie.userNotes,
      movie.addedAt,
      movie.updatedAt,
    ];

http.Response _metadata(http.Request request,
    {String? title = 'Titolo remoto'}) {
  return http.Response(
      jsonEncode({
        'id': int.parse(request.url.pathSegments.last),
        'name': title,
        'title': title,
        'poster_path': '/remote.jpg',
        'overview': 'Trama remota',
        'release_date': '2020-05-06',
        'background_image': 'https://example.com/remote.jpg',
        'released': '2021-06-07',
        'playtime': 20,
        'rating': 4.5,
        'platforms': [
          {
            'platform': {'name': 'PC'}
          },
        ],
      }),
      200);
}

Future<void> _hydrateDomain(
  SyncService service,
  String domain, {
  bool Function()? isCurrent,
}) =>
    service.hydrateUnknownMedia(
      shows: domain == 'series',
      movies: domain == 'movies',
      games: domain == 'games',
      isCurrent: isCurrent,
    );

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });
  tearDown(() => db.close());

  for (final timestamp in [true, false]) {
    test('metadata preservano dati personali e LWW con timestamp $timestamp',
        () async {
      await _seed(db, timestamp: timestamp);
      await (db.update(db.trackedGames)..where((t) => t.rawgId.equals(1)))
          .write(const TrackedGamesCompanion(playtime: Value(44)));
      final gameBefore = (await db.gamesDao.getByRawgId(1))!;
      final movieBefore = (await db.moviesDao.getByTmdbId(1))!;
      final client = MockClient((request) async => _metadata(request));
      addTearDown(client.close);
      final service = _service(db, client);
      final exportBefore = (await service.exportData()).toJson();

      await service.hydrateUnknownMedia(shows: false);

      final game = (await db.gamesDao.getByRawgId(1))!;
      final movie = (await db.moviesDao.getByTmdbId(1))!;
      expect(_gamePersonal(game), _gamePersonal(gameBefore));
      expect(_moviePersonal(movie), _moviePersonal(movieBefore));
      expect(game.playtime, 44);
      expect(game.voteAverage, 9.0);
      expect(jsonDecode(game.platforms!), ['PC']);
      expect(movie.posterPath, '/remote.jpg');
      expect(movie.overview, 'Trama remota');
      expect(movie.releaseDate, DateTime(2020, 5, 6));
      expect(movie.releaseYear, 2020);
      expect((await service.exportData()).toJson(), exportBefore);

      final conflictDate = timestamp ? _updatedAt : _addedAt;
      final conflictSeconds = conflictDate.millisecondsSinceEpoch ~/ 1000;
      for (final offset in [-1, 0, 1]) {
        await service.importData(SyncPayload(shows: {}, games: {
          '1': GameSyncData(
              status: 'dropped', updatedAt: conflictSeconds + offset),
        }, movies: {
          '1': MovieSyncData(
              status: 'dropped', updatedAt: conflictSeconds + offset),
        }));
        expect((await db.gamesDao.getByRawgId(1))!.status,
            offset > 0 ? MediaStatus.dropped : MediaStatus.paused);
        expect((await db.moviesDao.getByTmdbId(1))!.status,
            offset > 0 ? MediaStatus.dropped : MediaStatus.completed);
      }
    });
  }

  for (final domain in ['games', 'movies']) {
    test('$domain conserva modifiche personali fatte durante il fetch',
        () async {
      await _seed(db);
      final requested = Completer<void>();
      final release = Completer<void>();
      final client = MockClient((request) async {
        if (!requested.isCompleted) requested.complete();
        await release.future;
        return _metadata(request);
      });
      addTearDown(client.close);
      final hydration = _hydrateDomain(_service(db, client), domain);
      await requested.future;
      final editTime = _updatedAt.add(const Duration(hours: 1));
      if (domain == 'games') {
        await (db.update(db.trackedGames)..where((t) => t.rawgId.equals(1)))
            .write(TrackedGamesCompanion(
          status: const Value(MediaStatus.dropped),
          userRating: const Value(9.5),
          userNotes: const Value('Modifica durante fetch'),
          playtime: const Value(87),
          updatedAt: Value(editTime),
        ));
      } else {
        await (db.update(db.trackedMovies)..where((t) => t.tmdbId.equals(1)))
            .write(TrackedMoviesCompanion(
          status: const Value(MediaStatus.planToWatch),
          userRating: const Value(9.5),
          userNotes: const Value('Modifica durante fetch'),
          updatedAt: Value(editTime),
        ));
      }
      final gameBefore = (await db.gamesDao.getByRawgId(1))!;
      final movieBefore = (await db.moviesDao.getByTmdbId(1))!;
      release.complete();
      await hydration;
      final game = (await db.gamesDao.getByRawgId(1))!;
      final movie = (await db.moviesDao.getByTmdbId(1))!;
      expect(_gamePersonal(game), _gamePersonal(gameBefore));
      expect(_moviePersonal(movie), _moviePersonal(movieBefore));
      expect(domain == 'games' ? game.title : movie.title, 'Titolo remoto');
      if (domain == 'games') expect(game.playtime, 87);
    });

    for (final mutation in ['delete', 'resolve', 'external id']) {
      test('$domain non sovrascrive riga modificata in volo: $mutation',
          () async {
        await _seed(db);
        final requested = Completer<void>();
        final release = Completer<void>();
        final client = MockClient((request) async {
          if (!requested.isCompleted) requested.complete();
          await release.future;
          return _metadata(request);
        });
        addTearDown(client.close);
        final hydration = _hydrateDomain(_service(db, client), domain);
        await requested.future;
        if (domain == 'games') {
          final game = (await db.gamesDao.getByRawgId(1))!;
          if (mutation == 'delete') {
            await db.gamesDao.deleteGame(game.id);
          } else {
            await (db.update(db.trackedGames)
                  ..where((t) => t.id.equals(game.id)))
                .write(TrackedGamesCompanion(
              title: Value(
                  mutation == 'resolve' ? 'Risolto altrove' : 'Sconosciuto'),
              rawgId: Value(mutation == 'external id' ? 99 : 1),
              coverUrl: const Value('cover locale'),
            ));
          }
        } else {
          final movie = (await db.moviesDao.getByTmdbId(1))!;
          if (mutation == 'delete') {
            await db.moviesDao.deleteMovie(movie.id);
          } else {
            await (db.update(db.trackedMovies)
                  ..where((t) => t.id.equals(movie.id)))
                .write(TrackedMoviesCompanion(
              title: Value(
                  mutation == 'resolve' ? 'Risolto altrove' : 'Sconosciuto'),
              tmdbId: Value(mutation == 'external id' ? 99 : 1),
              posterPath: const Value('/locale.jpg'),
            ));
          }
        }
        final gamesBefore = await db.select(db.trackedGames).get();
        final moviesBefore = await db.select(db.trackedMovies).get();
        release.complete();
        await hydration;
        expect(await db.select(db.trackedGames).get(), gamesBefore);
        expect(await db.select(db.trackedMovies).get(), moviesBefore);
      });
    }

    test('$domain errori isolati restano ritentabili senza fermare altre righe',
        () async {
      for (var id = 1; id <= 4; id++) {
        await _seed(db, id: id);
      }
      var failing = true;
      var requests = 0;
      final client = MockClient((request) async {
        requests++;
        final id = int.parse(request.url.pathSegments.last);
        if (failing && id == 1) throw http.ClientException('offline simulato');
        if (failing && id == 2) return http.Response('{}', 401);
        if (failing && id == 3) return http.Response('{}', 404);
        return _metadata(request);
      });
      addTearDown(client.close);
      final service = _service(db, client);
      await _hydrateDomain(service, domain);
      final titles = domain == 'games'
          ? (await db.gamesDao.watchAll().first).map((g) => g.title)
          : (await db.moviesDao.watchAll().first).map((m) => m.title);
      expect(titles.where((t) => t == 'Sconosciuto'), hasLength(3));
      expect(titles.where((t) => t == 'Titolo remoto'), hasLength(1));
      failing = false;
      await _hydrateDomain(service, domain);
      final afterRetry = requests;
      await _hydrateDomain(service, domain);
      expect(requests, afterRetry);
      final retriedTitles = domain == 'games'
          ? (await db.gamesDao.watchAll().first).map((g) => g.title)
          : (await db.moviesDao.watchAll().first).map((m) => m.title);
      expect(retriedTitles, everyElement('Titolo remoto'));
    });
  }

  test('nomi vuoti o placeholder non risolvono film e giochi', () async {
    await _seed(db);
    String? remoteTitle;
    final client =
        MockClient((request) async => _metadata(request, title: remoteTitle));
    addTearDown(client.close);
    final service = _service(db, client);
    final gamesBefore = await db.select(db.trackedGames).get();
    final moviesBefore = await db.select(db.trackedMovies).get();
    for (final title in [
      null,
      '',
      '  \n ',
      'Sconosciuto',
      'Titolo sconosciuto',
      ' sconosciuto '
    ]) {
      remoteTitle = title;
      await service.hydrateUnknownMedia(shows: false);
      expect(await db.select(db.trackedGames).get(), gamesBefore);
      expect(await db.select(db.trackedMovies).get(), moviesBefore);
    }
    remoteTitle = '  Titolo valido  ';
    await service.hydrateUnknownMedia(shows: false);
    expect((await db.gamesDao.getByRawgId(1))!.title, 'Titolo valido');
    expect((await db.moviesDao.getByTmdbId(1))!.title, 'Titolo valido');
  });

  for (final domain in ['series', 'movies', 'games', 'none']) {
    test('flag $domain esegue richieste solo per il dominio selezionato',
        () async {
      await _seed(db);
      await db.showsDao.insertShow(TrackedShowsCompanion.insert(
        tmdbId: 1,
        title: 'Sconosciuto',
        status: MediaStatus.watching,
        addedAt: _addedAt,
      ));
      final paths = <String>[];
      final client = MockClient((request) async {
        paths.add(request.url.path);
        return _metadata(request);
      });
      addTearDown(client.close);
      await _hydrateDomain(_service(db, client), domain);
      expect(
          paths,
          switch (domain) {
            'series' => ['/3/tv/1', '/3/tv/1'],
            'movies' => ['/3/movie/1', '/3/movie/1'],
            'games' => ['/api/games/1'],
            _ => <String>[],
          });
    });
  }

  test('generazione già scaduta non avvia richieste', () async {
    await _seed(db);
    var requests = 0;
    final client = MockClient((request) async {
      requests++;
      return _metadata(request);
    });
    addTearDown(client.close);
    await _service(db, client).hydrateUnknownMedia(isCurrent: () => false);
    expect(requests, 0);
  });

  for (final domain in ['series', 'movies', 'games']) {
    test('$domain cambio credenziali scarta risposta e richieste residue',
        () async {
      for (var id = 1; id <= 2; id++) {
        await _seed(db, id: id);
        await db.showsDao.insertShow(TrackedShowsCompanion.insert(
          tmdbId: id,
          title: 'Sconosciuto',
          status: MediaStatus.watching,
          addedAt: _addedAt,
        ));
      }
      final gamesBefore = await db.select(db.trackedGames).get();
      final moviesBefore = await db.select(db.trackedMovies).get();
      final showsBefore = await db.select(db.trackedShows).get();
      var current = true;
      final paths = <String>[];
      final requested = Completer<void>();
      final release = Completer<void>();
      final client = MockClient((request) async {
        paths.add(request.url.path);
        if (!requested.isCompleted) requested.complete();
        await release.future;
        return _metadata(request);
      });
      addTearDown(client.close);
      final hydration = _hydrateDomain(_service(db, client), domain,
          isCurrent: () => current);
      await requested.future;
      current = false;
      release.complete();
      await hydration;
      expect(paths, hasLength(domain == 'games' ? 1 : 2));
      expect(paths, everyElement(endsWith('/1')));
      expect(await db.select(db.trackedGames).get(), gamesBefore);
      expect(await db.select(db.trackedMovies).get(), moviesBefore);
      expect(await db.select(db.trackedShows).get(), showsBefore);
    });
  }
}
