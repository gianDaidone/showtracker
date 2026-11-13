import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:showtracker/core/auth/auth_state.dart';
import 'package:showtracker/core/auth/rawg_auth_state.dart';
import 'package:showtracker/core/database/app_database.dart';
import 'package:showtracker/core/database/database_provider.dart';
import 'package:showtracker/core/riverpod_utils.dart';
import 'package:showtracker/features/sync/domain/models/sync_payload.dart';
import 'package:showtracker/features/sync/providers/metadata_recovery_provider.dart';
import 'package:showtracker/features/sync/services/sync_service.dart';

final _date = DateTime.utc(2026, 10, 1, 12);
Future<T> _bounded<T>(Future<T> future) =>
    future.timeout(const Duration(seconds: 5));

http.Response _reply(http.Request request) {
  final id = int.parse(request.url.pathSegments.last);
  final game = request.url.host == 'api.rawg.io';
  return http.Response(
      jsonEncode({
        'id': id,
        if (game) 'slug': 'game-$id',
        if (game) 'name': 'Gioco $id' else 'title': 'Film $id',
        'overview': 'Trama recuperata',
        'poster_path': '/poster.jpg',
        'background_image': 'https://example.test/cover.jpg',
        'released': '2026-09-01',
        'release_date': '2026-09-01',
        'rating': 4.5,
        'playtime': 12,
        'platforms': [
          {
            'platform': {'name': 'PC'}
          }
        ],
      }),
      200);
}

class _Fixture {
  _Fixture(this.db, this.container, this.requests);
  final AppDatabase db;
  final ProviderContainer container;
  final List<http.Request> requests;
  bool _closed = false;
  MetadataRecovery get recovery => container.read(metadataRecoveryProvider);

  Future<void> importMedia(
      {List<int> games = const [202],
      List<int> movies = const [],
      List<int> shows = const []}) async {
    final sub = container.listen(syncServiceProvider, (_, __) {});
    try {
      final timestamp = _date.millisecondsSinceEpoch ~/ 1000;
      await sub.read().importData(SyncPayload(
            shows: {
              for (final id in shows)
                '$id': ShowSyncData(
                    status: 'paused', updatedAt: timestamp, eps: {})
            },
            games: {
              for (final id in games)
                '$id': GameSyncData(status: 'paused', updatedAt: timestamp)
            },
            movies: {
              for (final id in movies)
                '$id': MovieSyncData(status: 'completed', updatedAt: timestamp)
            },
          ));
    } finally {
      sub.close();
    }
  }

  Future<void> restoreAuth() async {
    await container.readFuture(authControllerProvider.future);
    await container.readFuture(rawgAuthControllerProvider.future);
  }

  Future<void> gamesReady(List<int> ids) async {
    await _bounded(db.gamesDao.watchAll().firstWhere((rows) => ids.every((id) =>
        rows.any((row) => row.rawgId == id && row.title == 'Gioco $id'))));
  }

  Future<void> movieReady() async {
    await _bounded(db.moviesDao
        .watchAll()
        .firstWhere((rows) => rows.any((row) => row.title == 'Film 303')));
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    container.dispose();
    await db.close();
  }
}

Future<void> _withFixture(
  Future<void> Function(_Fixture) body, {
  Map<String, String> storage = const {},
  Future<http.Response> Function(http.Request)? handler,
}) async {
  FlutterSecureStorage.setMockInitialValues(Map.of(storage));
  final requests = <http.Request>[];
  await http.runWithClient(() async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final fixture = _Fixture(
        db,
        ProviderContainer(
          retry: noProviderRetry,
          overrides: [databaseProvider.overrideWithValue(db)],
        ),
        requests);
    try {
      await body(fixture);
    } finally {
      await fixture.close();
    }
  },
      () => MockClient((request) async {
            requests.add(request);
            return handler == null ? _reply(request) : await handler(request);
          }));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
      'import senza chiavi non fa HTTP; login RAWG ripara senza reimportare',
      () => _withFixture((f) async {
            await f.importMedia();
            final recovery = f.recovery;
            await recovery.recoverAfterImport();
            expect(f.requests, isEmpty);
            final imported = (await f.db.gamesDao.getByRawgId(202))!;
            expect(imported.title, 'Sconosciuto');
            await (f.db.update(f.db.trackedGames)
                  ..where((t) => t.id.equals(imported.id)))
                .write(const TrackedGamesCompanion(
                    userRating: Value(8.5),
                    userNotes: Value('Nota locale'),
                    playtime: Value(87)));
            final before = (await f.db.gamesDao.getByRawgId(202))!;
            final sync = f.container.listen(syncServiceProvider, (_, __) {});
            try {
              final exported = (await sync.read().exportData()).toJson();
              await f.container
                  .read(rawgAuthControllerProvider.notifier)
                  .loginWithKey('fake-rawg');
              await f.gamesReady(
                  [202]); // Solo il listener auth avvia il recupero.
              await recovery.recoverGames();
              final after = (await f.db.gamesDao.getByRawgId(202))!;
              expect([
                after.id,
                after.rawgId,
                after.status,
                after.userRating,
                after.userNotes,
                after.addedAt,
                after.updatedAt,
                after.playtime
              ], [
                before.id,
                before.rawgId,
                before.status,
                before.userRating,
                before.userNotes,
                before.addedAt,
                before.updatedAt,
                before.playtime
              ]);
              expect(after.voteAverage, 9.0);
              expect(jsonDecode(after.platforms!), ['PC']);
              expect(after.coverUrl, 'https://example.test/cover.jpg');
              expect((await sync.read().exportData()).toJson(), exported);
              for (final offset in [-1, 1]) {
                await sync
                    .read()
                    .importData(SyncPayload(shows: {}, movies: {}, games: {
                      '202': GameSyncData(
                          status: 'completed',
                          updatedAt:
                              _date.millisecondsSinceEpoch ~/ 1000 + offset),
                    }));
                final merged = (await f.db.gamesDao.getByRawgId(202))!;
                expect(merged.status,
                    offset < 0 ? before.status : MediaStatus.completed);
                expect(merged.title, 'Gioco 202');
              }
              expect(f.requests, hasLength(1));
              expect(f.requests.single.url.queryParameters['key'], 'fake-rawg');
            } finally {
              sync.close();
            }
          }));

  test(
      'login TMDB recupera solo film; i domini e gli stati restano isolati',
      () => _withFixture((f) async {
            await f.importMedia(movies: [303], shows: [101]);
            final recovery = f.recovery;
            await recovery.recoverAfterImport();
            final before = (await f.db.moviesDao.getByTmdbId(303))!;
            await (f.db.update(f.db.trackedMovies)
                  ..where((t) => t.id.equals(before.id)))
                .write(const TrackedMoviesCompanion(
                    userRating: Value(7.5), userNotes: Value('Film locale')));
            await f.container
                .read(authControllerProvider.notifier)
                .loginWithManualKey('fake-tmdb');
            await f.movieReady();
            await recovery.recoverMovies();
            final movie = (await f.db.moviesDao.getByTmdbId(303))!;
            expect([movie.id, movie.status, movie.addedAt, movie.updatedAt],
                [before.id, before.status, before.addedAt, before.updatedAt]);
            expect(movie.userRating, 7.5);
            expect(movie.userNotes, 'Film locale');
            expect(movie.releaseYear, 2026);
            expect(movie.posterPath, '/poster.jpg');
            expect(
                (await f.db.gamesDao.getByRawgId(202))!.title, 'Sconosciuto');
            expect(
                (await f.db.showsDao.getByTmdbId(101))!.title, 'Sconosciuto');
            expect(f.requests, hasLength(2)); // TMDB italiano + inglese.
            expect(
                f.requests.every((r) =>
                    r.url.path == '/3/movie/303' &&
                    r.url.queryParameters['api_key'] == 'fake-tmdb'),
                isTrue);
            await f.db.moviesDao.insertMovie(TrackedMoviesCompanion.insert(
                tmdbId: 304,
                title: 'Sconosciuto',
                status: MediaStatus.planToWatch,
                addedAt: _date));
            await f.container
                .read(rawgAuthControllerProvider.notifier)
                .loginWithKey('fake-rawg');
            await f.gamesReady([202]);
            await recovery.recoverGames();
            expect(f.requests, hasLength(3));
            expect(f.requests.last.url.host, 'api.rawg.io');
            expect(
                (await f.db.moviesDao.getByTmdbId(304))!.title, 'Sconosciuto');
          }));

  for (final restored in [false, true]) {
    test(
        'avvio recupera arretrati con auth già ripristinata: $restored',
        () => _withFixture((f) async {
              // Dati già su disco prima che i controller auth vengano creati.
              await f.db.gamesDao.insertGame(TrackedGamesCompanion.insert(
                  rawgId: 202,
                  title: 'Sconosciuto',
                  status: MediaStatus.paused,
                  addedAt: _date,
                  updatedAt: Value(_date)));
              await f.db.moviesDao.insertMovie(TrackedMoviesCompanion.insert(
                  tmdbId: 303,
                  title: 'Sconosciuto',
                  status: MediaStatus.completed,
                  addedAt: _date,
                  updatedAt: Value(_date)));
              if (restored) await f.restoreAuth();
              final recovery =
                  f.recovery; // Nessuna chiamata esplicita di recupero.
              await Future.wait([
                f.gamesReady([202]),
                f.movieReady()
              ]);
              await recovery.recoverAfterImport();
              expect(f.requests, hasLength(3));
              expect(
                  f.requests
                      .where((r) => r.url.host == 'api.rawg.io')
                      .single
                      .url
                      .queryParameters['key'],
                  'restored-rawg');
              expect(
                  f.requests
                      .where((r) => r.url.host == 'api.themoviedb.org')
                      .every((r) =>
                          r.url.queryParameters['api_key'] == 'restored-tmdb'),
                  isTrue);
            }, storage: {
              'rawg_api_key': 'restored-rawg',
              'tmdb_manual_key': 'restored-tmdb'
            }));
  }

  test(
      'credenziali disponibili senza placeholder non generano HTTP',
      () => _withFixture((f) async {
            await f.restoreAuth();
            await f.recovery.recoverAfterImport();
            await f.recovery.recoverGames();
            await f.recovery.recoverMovies();
            expect(f.requests, isEmpty);
          }, storage: {
            'rawg_api_key': 'fake-rawg',
            'tmdb_manual_key': 'fake-tmdb'
          }));

  for (final failure in ['401', '404', 'offline']) {
    test('$failure lascia solo il titolo fallito retryable alla riapertura',
        () async {
      var fail = true;
      await _withFixture(
          (f) async {
            await f.importMedia(games: [202, 203]);
            await f.restoreAuth();
            final recovery = f.recovery;
            await recovery.recoverGames();
            expect(
                (await f.db.gamesDao.getByRawgId(202))!.title, 'Sconosciuto');
            expect((await f.db.gamesDao.getByRawgId(203))!.title, 'Gioco 203');
            expect(f.requests, hasLength(2));
            fail = false;
            await recovery
                .recoverGames(); // Stesso trigger dell'apertura libreria.
            expect((await f.db.gamesDao.getByRawgId(202))!.title, 'Gioco 202');
            expect(f.requests, hasLength(3));
            await recovery.recoverGames();
            expect(f.requests, hasLength(3));
          },
          storage: {'rawg_api_key': 'fake-rawg'},
          handler: (request) async {
            if (fail && request.url.path.endsWith('/202')) {
              if (failure == 'offline') {
                throw http.ClientException('offline simulato');
              }
              return http.Response('{}', int.parse(failure));
            }
            return _reply(request);
          });
    });
  }

  test('cambio chiave in volo annulla il vecchio pass e accoda client corrente',
      () async {
    final entered = Completer<void>();
    final release = Completer<void>();
    await _withFixture(
        (f) async {
          await f.importMedia(games: [202, 203, 204]);
          await f.restoreAuth();
          final recovery = f.recovery;
          final pending = <Future<void>>[];
          try {
            await _bounded(entered.future);
            await f.container
                .read(rawgAuthControllerProvider.notifier)
                .loginWithKey('new-fake-key');
            pending.addAll(List.generate(5, (_) => recovery.recoverGames()));
          } finally {
            release.complete();
          }
          await _bounded(Future.wait(pending));
          await f.gamesReady([202, 203, 204]);
          await recovery.recoverGames();
          expect(
              f.requests
                  .where((r) => r.url.queryParameters['key'] == 'old-fake-key'),
              hasLength(1));
          expect(
              f.requests
                  .where((r) => r.url.queryParameters['key'] == 'new-fake-key'),
              hasLength(3));
          expect(f.requests, hasLength(4));
        },
        storage: {'rawg_api_key': 'old-fake-key'},
        handler: (request) async {
          if (request.url.queryParameters['key'] == 'old-fake-key') {
            entered.complete();
            await release.future;
            return http.Response(
                jsonEncode({
                  'id': 202,
                  'slug': 'stale',
                  'name': 'Titolo dal client superato'
                }),
                200);
          }
          return _reply(request);
        });
  });

  test('dispose durante fetch chiude DB e impedisce richieste residue',
      () async {
    final entered = Completer<void>();
    final release = Completer<void>();
    await _withFixture(
        (f) async {
          await f.importMedia(games: [202, 203]);
          await f.restoreAuth();
          final recovery = f.recovery;
          final drain = recovery.recoverGames();
          try {
            await _bounded(entered.future);
            await f.close();
          } finally {
            release.complete();
          }
          await _bounded(drain);
          await recovery.recoverAfterImport();
          expect(f.requests, hasLength(1));
        },
        storage: {'rawg_api_key': 'fake-rawg'},
        handler: (request) async {
          entered.complete();
          await release.future;
          return _reply(request);
        });
  });
}
