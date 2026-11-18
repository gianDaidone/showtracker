import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:showtracker/core/auth/rawg_auth_state.dart';
import 'package:showtracker/core/auth/auth_state.dart';
import 'package:showtracker/features/games/data/rawg_service.dart';
import 'package:showtracker/features/series/data/tmdb_service.dart';
import 'package:showtracker/features/series/data/models/normalized_anime_season.dart';
import 'package:showtracker/features/series/providers/series_providers.dart';
import 'package:showtracker/features/sync/domain/models/sync_payload.dart';
import 'package:showtracker/features/sync/domain/models/sync_progress.dart';
import 'package:showtracker/features/sync/providers/sync_controller.dart';
import 'package:showtracker/features/sync/services/sync_android_bridge.dart';
import 'package:showtracker/features/sync/services/sync_service.dart';
import 'package:showtracker/features/sync/services/sync_job_store.dart';
import 'package:showtracker/features/sync/utils/sync_compressor.dart';
import '../../support/app_test_harness.dart';

class _Android extends SyncAndroidBridge {
  final snapshots = <SyncProgress>[];
  void Function()? stopped;
  @override
  void onStop(void Function() callback) {
    stopped = callback;
  }

  @override
  Future<({bool available, bool notifications})> start() async =>
      (available: true, notifications: false);
  @override
  void publish(SyncProgress progress) {
    snapshots.add(progress);
  }

  @override
  void dispose() {}
}

int get stamp => DateTime(2025).millisecondsSinceEpoch ~/ 1000;
String wire(SyncPayload payload) =>
    SyncCompressor.compressPayload(payload.toJson());
SyncPayload movies(int count) => SyncPayload(shows: {}, games: {}, movies: {
      for (var id = 1; id <= count; id++)
        '$id': MovieSyncData(status: 'completed', updatedAt: stamp),
    });

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<({AppTestHarness app, _Android android, SyncController controller})>
      setup(
    Future<http.Response> Function(http.Request) handler, {
    RawgAuthState rawgAuth = const RawgAuthenticated('fake-rawg'),
  }) async {
    FlutterSecureStorage.setMockInitialValues({});
    final client = MockClient(handler);
    addTearDown(client.close);
    final android = _Android();
    final app = await AppTestHarness.create(
      rawgAuth: rawgAuth,
      tmdbService: TmdbService(client),
      rawgService: RawgService(client),
      overrides: [syncAndroidBridgeProvider.overrideWithValue(android)],
    );
    addTearDown(() async {
      app.container.dispose();
      await app.db.close();
    });
    final controller = app.container.read(syncControllerProvider.notifier);
    await controller.ready;
    return (app: app, android: android, controller: controller);
  }

  test(
      'titoli progressivi prima del drain, totale unico e notifica coerente con permesso negato',
      () async {
    final blocked = Completer<void>();
    final requested = Completer<void>();
    final f = await setup((r) async {
      if (r.url.path.endsWith('/2')) {
        if (!requested.isCompleted) requested.complete();
        await blocked.future;
      }
      final id = int.parse(r.url.pathSegments.last);
      return http.Response(jsonEncode({'id': id, 'title': 'Film $id'}), 200);
    });
    final ready = f.app.db.moviesDao
        .watchAll()
        .firstWhere((rows) => rows.any((r) => r.title == 'Film 1'));
    final run = f.controller.receive(wire(movies(2)));
    await requested.future;
    await ready;
    expect(f.controller.busy, isTrue);
    expect((await f.app.db.moviesDao.watchAll().first).length, 2);
    blocked.complete();
    await run;
    final state = f.app.container.read(syncControllerProvider);
    expect(state.total, 2);
    expect(state.completed, 2);
    expect(state.failed, 0);
    expect(state.notificationsAllowed, isFalse);
    expect(f.android.snapshots.last.counter, state.counter);
    expect(f.android.snapshots.last.heading, 'Sincronizzazione completata');
  });

  test(
      'errore parziale, retry selettivo e replay non duplicano sessioni o richieste riuscite',
      () async {
    var offline = true;
    final paths = <String>[];
    final f = await setup((r) async {
      paths.add(r.url.path);
      if (offline && r.url.path.endsWith('/2')) {
        throw http.ClientException('offline');
      }
      final id = int.parse(r.url.pathSegments.last);
      return http.Response(jsonEncode({'id': id, 'title': 'Film $id'}), 200);
    });
    final payload = wire(movies(2));
    await f.controller.receive(payload);
    expect(f.app.container.read(syncControllerProvider).completed, 1);
    expect(f.app.container.read(syncControllerProvider).failed, 1);
    final count1 = paths.where((p) => p.endsWith('/1')).length;
    offline = false;
    await f.controller.retry();
    expect(f.app.container.read(syncControllerProvider).total, 1);
    expect(f.app.container.read(syncControllerProvider).completed, 1);
    expect(paths.where((p) => p.endsWith('/1')).length, count1);
    final requests = paths.length;
    await f.controller.receive(payload);
    expect(paths.length, requests);
    expect(await f.app.db.select(f.app.db.syncSessions).get(), hasLength(1));
    expect(await f.app.db.select(f.app.db.syncItems).get(), hasLength(2));
  });

  test('rimozione durante fetch non ricrea il record', () async {
    final entered = Completer<void>();
    final release = Completer<void>();
    final f = await setup((r) async {
      if (!entered.isCompleted) entered.complete();
      await release.future;
      return http.Response(jsonEncode({'id': 1, 'title': 'Film'}), 200);
    });
    final run = f.controller.receive(wire(movies(1)));
    await entered.future;
    final row = (await f.app.db.moviesDao.getByTmdbId(1))!;
    await f.app.db.moviesDao.deleteMovie(row.id);
    release.complete();
    await run;
    expect(await f.app.db.moviesDao.getByTmdbId(1), isNull);
    expect(f.app.container.read(syncControllerProvider).completed, 0);
    expect((await f.app.db.select(f.app.db.syncItems).get()).single.status,
        'removed');
  });

  test(
      'serie ripristina progressi, conteggi e feed senza apertura dettaglio e conserva timestamp',
      () async {
    final next = DateTime.now()
        .add(const Duration(days: 7))
        .toIso8601String()
        .substring(0, 10);
    final f = await setup((r) async {
      final body = r.url.path.contains('/season/')
          ? {
              'id': 1,
              'season_number': 1,
              'episodes': [
                {
                  'id': 1,
                  'episode_number': 1,
                  'season_number': 1,
                  'name': 'Uno',
                  'air_date': '2020-01-01'
                },
                {
                  'id': 2,
                  'episode_number': 2,
                  'season_number': 1,
                  'name': 'Due',
                  'air_date': '2020-01-02'
                },
              ]
            }
          : {
              'id': 10,
              'name': 'Serie',
              'number_of_seasons': 1,
              'number_of_episodes': 3,
              'status': 'Returning Series',
              'seasons': [
                {'season_number': 1, 'episode_count': 3}
              ],
              'next_episode_to_air': {
                'season_number': 1,
                'episode_number': 3,
                'air_date': next
              }
            };
      return http.Response(jsonEncode(body), 200);
    });
    final visible =
        f.app.container.listen(visibleWatchingShowsProvider, (_, __) {});
    final upcoming =
        f.app.container.listen(upcomingEpisodesProvider, (_, __) {});
    addTearDown(visible.close);
    addTearDown(upcoming.close);
    await f.controller.receive(wire(SyncPayload(shows: {
      '10': ShowSyncData(status: 'watching', updatedAt: stamp, eps: {'1': '1'})
    }, games: {}, movies: {})));
    final show = (await f.app.db.showsDao.getByTmdbId(10))!;
    expect(show.updatedAt!.millisecondsSinceEpoch ~/ 1000, stamp);
    expect(await f.app.db.showsDao.getSeasonCounts(show.id), {1: 3});
    expect((await f.app.db.showsDao.getEpisodesByShow(show.id)).single.watched,
        isTrue);
    expect(await f.app.container.read(visibleWatchingShowsProvider.future),
        hasLength(1));
    expect(await f.app.container.read(upcomingEpisodesProvider.future),
        hasLength(1));
    expect(f.app.container.read(syncControllerProvider).completed, 1);
  });

  test('cour v2 si riconcilia per AniList ID senza usare il numero TMDB',
      () async {
    final f = await setup((r) async => http.Response(
        jsonEncode({
          'id': 10,
          'name': 'Anime',
          'number_of_seasons': 1,
          'number_of_episodes': 24,
          'genres': [
            {'id': 16, 'name': 'Animation'}
          ],
          'origin_country': ['JP'],
          'seasons': [
            {'season_number': 1, 'episode_count': 24}
          ],
        }),
        200));
    await f.app.db.animeCacheDao.saveAnimeSeasons(10, [
      const NormalizedAnimeSeason(
          seasonNumber: 1,
          tmdbSeasonNumber: 1,
          anilistId: 200,
          episodeCount: 12,
          status: 'FINISHED',
          streamingEpisodes: []),
      const NormalizedAnimeSeason(
          seasonNumber: 2,
          tmdbSeasonNumber: 1,
          anilistId: 201,
          episodeCount: 12,
          status: 'FINISHED',
          streamingEpisodes: []),
    ]);
    await f.controller.receive(wire(SyncPayload(version: 2, shows: {
      '10': ShowSyncData(
          status: 'paused',
          updatedAt: stamp,
          coordinates: 'cour',
          courIds: {'1': 201},
          eps: {'1': '1-2'})
    }, games: {}, movies: {})));
    final show = (await f.app.db.showsDao.getByTmdbId(10))!;
    final eps = await f.app.db.showsDao.getEpisodesByShow(show.id);
    expect(eps.map((e) => (e.seasonNumber, e.episodeNumber)), [(2, 1), (2, 2)]);
    expect(f.app.container.read(syncControllerProvider).completed, 1);
  });

  test(
      'payload cour importato programmaticamente conserva progressi da riconciliare',
      () async {
    final f = await setup((_) async => throw StateError('nessuna rete'));
    final service = f.app.container.listen(syncServiceProvider, (_, __) {});
    addTearDown(service.close);
    await service.read().importData(SyncPayload(version: 2, shows: {
          '10': ShowSyncData(
              status: 'watching',
              updatedAt: stamp,
              coordinates: 'cour',
              courIds: {'1': 200},
              eps: {'1': '1-4'})
        }, games: {}, movies: {}));
    expect(await f.app.db.select(f.app.db.trackedEpisodes).get(), isEmpty);
    final job = (await f.app.db.select(f.app.db.syncItems).get()).single;
    expect(jsonDecode(job.progressData!)['e'], {'1': '1-4'});
  });

  test('payload malformato non crea sessione né dati', () async {
    final f = await setup((_) async => throw StateError('nessuna rete'));
    await f.controller.receive('invalid');
    expect(await f.app.db.select(f.app.db.syncSessions).get(), isEmpty);
    expect(await f.app.db.moviesDao.watchAll().first, isEmpty);
    expect(f.app.container.read(syncControllerProvider).errors, isNotEmpty);
  });

  test('totale misto distingue lo stesso ID TMDB di serie e film', () async {
    final f = await setup((r) async => http.Response(
        jsonEncode({
          'id': 1,
          'name': 'Titolo',
          'title': 'Film',
          'platforms': [],
          'number_of_seasons': 0,
          'number_of_episodes': 0,
          'seasons': [],
        }),
        200));
    await f.controller.receive(wire(SyncPayload(
        shows: {'1': ShowSyncData(status: 'paused', updatedAt: stamp, eps: {})},
        movies: {'1': MovieSyncData(status: 'completed', updatedAt: stamp)},
        games: {'1': GameSyncData(status: 'paused', updatedAt: stamp)})));
    final state = f.app.container.read(syncControllerProvider);
    expect(state.total, 3);
    expect(state.completed, 3);
    expect(await f.app.db.select(f.app.db.syncItems).get(), hasLength(3));
  });

  test('errore checkpoint annulla anche il merge della libreria', () async {
    final f = await setup((_) async => throw StateError('nessuna rete'));
    await f.app.db.customStatement(
        "CREATE TRIGGER fail_sync BEFORE INSERT ON sync_items BEGIN SELECT RAISE(ABORT, 'checkpoint fallito'); END");
    final service = f.app.container.listen(syncServiceProvider, (_, __) {});
    addTearDown(service.close);
    await expectLater(
        service.read().importData(movies(1), persistSession: true),
        throwsA(anything));
    expect(await f.app.db.moviesDao.watchAll().first, isEmpty);
    expect(await f.app.db.select(f.app.db.syncSessions).get(), isEmpty);
    expect(await f.app.db.select(f.app.db.syncItems).get(), isEmpty);
  });

  test(
      'cambio credenziali in volo scarta risultati obsoleti e riaccoda il lavoro',
      () async {
    final entered = Completer<void>();
    final release = Completer<void>();
    var old = true;
    final f = await setup((_) async {
      final wasOld = old;
      if (wasOld) {
        if (!entered.isCompleted) entered.complete();
        await release.future;
      }
      return http.Response(
          jsonEncode({'id': 1, 'title': wasOld ? 'Obsoleto' : 'Corrente'}),
          200);
    });
    final run = f.controller.receive(wire(movies(1)));
    await entered.future;
    old = false;
    await f.app.container
        .read(authControllerProvider.notifier)
        .loginWithManualKey('new-fake-key');
    release.complete();
    await run;
    await f.controller.retry();
    expect((await f.app.db.moviesDao.getByTmdbId(1))!.title, 'Corrente');
    expect(f.app.container.read(syncControllerProvider).completed, 1);
  });

  test('cour ambiguo conserva dati ricevuti e non applica coordinate TMDB',
      () async {
    final f = await setup((_) async => http.Response(
        jsonEncode({
          'id': 10,
          'name': 'Anime',
          'number_of_seasons': 1,
          'number_of_episodes': 12,
          'genres': [
            {'id': 16, 'name': 'Animation'}
          ],
          'origin_country': ['JP'],
          'seasons': [
            {'season_number': 1, 'episode_count': 12}
          ],
        }),
        200));
    await f.app.db.animeCacheDao.saveAnimeSeasons(10, [
      const NormalizedAnimeSeason(
          seasonNumber: 1,
          tmdbSeasonNumber: 1,
          anilistId: 200,
          episodeCount: 12,
          status: 'FINISHED',
          streamingEpisodes: []),
    ]);
    await f.controller.receive(wire(SyncPayload(version: 2, shows: {
      '10': ShowSyncData(
          status: 'paused',
          updatedAt: stamp,
          coordinates: 'cour',
          courIds: {'1': 999},
          eps: {'1': '1-4'})
    }, movies: {}, games: {})));
    expect(f.app.container.read(syncControllerProvider).failed, 1);
    expect(await f.app.db.select(f.app.db.trackedEpisodes).get(), isEmpty);
    final job = (await f.app.db.select(f.app.db.syncItems).get()).single;
    expect(jsonDecode(job.progressData!)['e'], {'1': '1-4'});
    final service = f.app.container.listen(syncServiceProvider, (_, __) {});
    addTearDown(service.close);
    await expectLater(service.read().exportData(), throwsFormatException);
  });

  test('nuova scansione mantiene recuperabili i trasferimenti precedenti',
      () async {
    var offline = true;
    final f = await setup((r) async {
      final id = int.parse(r.url.pathSegments.last);
      if (offline && id == 1) throw http.ClientException('offline');
      return http.Response(jsonEncode({'id': id, 'title': 'Film $id'}), 200);
    });
    await f.controller.receive(wire(movies(1)));
    await f.controller.receive(wire(SyncPayload(
        shows: {},
        games: {},
        movies: {'2': MovieSyncData(status: 'completed', updatedAt: stamp)})));
    expect(f.app.container.read(syncControllerProvider).otherSessions, 1);
    offline = false;
    await f.controller.resumeOlder();
    expect(f.app.container.read(syncControllerProvider).completed, 1);
    expect(f.app.container.read(syncControllerProvider).otherSessions, 0);
    expect(await f.app.db.moviesDao.watchAll().first, hasLength(2));
  });

  test('ricreazione coordinatore riprende checkpoint senza reimportare',
      () async {
    var offline = true;
    final f = await setup((r) async {
      if (offline) throw http.ClientException('offline');
      return http.Response(
          jsonEncode({'id': 1, 'title': 'Film recuperato'}), 200);
    });
    await f.controller.receive(wire(movies(1)));
    final oldId = (await f.app.db.moviesDao.getByTmdbId(1))!.id;
    final store = SyncJobStore(f.app.db);
    final item = (await f.app.db.select(f.app.db.syncItems).get()).single;
    await store.update(item.id, 'running');
    f.app.container.invalidate(syncControllerProvider);
    final restored = f.app.container.read(syncControllerProvider.notifier);
    await restored.ready;
    await restored.retry();
    expect(f.app.container.read(syncControllerProvider).failed, 1);
    offline = false;
    await restored.retry();
    expect((await f.app.db.moviesDao.getByTmdbId(1))!.id, oldId);
    expect(f.app.container.read(syncControllerProvider).completed, 1);
    expect(await f.app.db.select(f.app.db.syncSessions).get(), hasLength(1));
  });
  test(
      'giochi senza chiave: elenco salvato, nessun errore, conferma persistente',
      () async {
    final f = await setup(
        (r) async => http.Response(jsonEncode({'id': 1, 'title': 'Film'}), 200),
        rawgAuth: const RawgUnauthenticated());
    await f.controller.receive(wire(SyncPayload(
        shows: {},
        movies: {'1': MovieSyncData(status: 'completed', updatedAt: stamp)},
        games: {'2': GameSyncData(status: 'paused', updatedAt: stamp)})));
    var state = f.app.container.read(syncControllerProvider);
    expect(state.completed, 1);
    expect(state.deferredGames, 1);
    expect(state.failed, 0);
    expect(state.needsGameAcknowledgement, isTrue);
    final game = (await f.app.db.gamesDao.getByRawgId(2))!;
    expect(game.title, 'Sconosciuto');
    expect(game.status.name, 'paused');
    await f.controller.acknowledgeGames();
    state = f.app.container.read(syncControllerProvider);
    expect(state.hasActivity, isFalse);
    expect(state.heading, 'Sincronizzazione completata');
    expect(
        (await f.app.db.select(f.app.db.syncItems).get())
            .firstWhere((i) => i.domain == 'games')
            .status,
        'deferred_ack');
    f.app.container.invalidate(syncControllerProvider);
    final restored = f.app.container.read(syncControllerProvider.notifier);
    await restored.ready;
    await restored.retry(automatic: true);
    expect(
        f.app.container.read(syncControllerProvider).needsGameAcknowledgement,
        isFalse);
  });

  test(
      'chiave RAWG riprende giochi anche di sessioni precedenti conservando timestamp',
      () async {
    final requests = <String>[];
    final f = await setup((r) async {
      requests.add(r.url.path);
      return http.Response(
          jsonEncode({'id': 2, 'name': 'Gioco recuperato', 'title': 'Film'}),
          200);
    }, rawgAuth: const RawgUnauthenticated());
    await f.controller.receive(wire(SyncPayload(
        shows: {},
        movies: {},
        games: {'2': GameSyncData(status: 'paused', updatedAt: stamp)})));
    await f.controller.acknowledgeGames();
    final before = (await f.app.db.gamesDao.getByRawgId(2))!;
    await f.controller.receive(wire(movies(1)));
    expect(requests.where((p) => p.contains('/games/')), isEmpty);
    await f.app.container
        .read(rawgAuthControllerProvider.notifier)
        .loginWithKey('new-fake-rawg');
    // Stesso esecutore delle callback auth, Future condivisa se già avviato.
    await Future<void>.delayed(Duration.zero);
    await f.controller.retry(automatic: true);
    final after = (await f.app.db.gamesDao.getByRawgId(2))!;
    expect(after.title, 'Gioco recuperato');
    expect(after.id, before.id);
    expect(after.updatedAt, before.updatedAt);
    expect(after.status, before.status);
    expect(requests.where((p) => p.contains('/games/')), hasLength(1));
  });

  test('inserire la chiave prima della conferma non fa scomparire l’avviso',
      () async {
    final f = await setup(
        (_) async => http.Response(
            jsonEncode({'id': 2, 'name': 'Gioco', 'platforms': []}), 200),
        rawgAuth: const RawgUnauthenticated());
    await f.controller.receive(wire(SyncPayload(
        shows: {},
        movies: {},
        games: {'2': GameSyncData(status: 'paused', updatedAt: stamp)})));
    await f.app.container
        .read(rawgAuthControllerProvider.notifier)
        .loginWithKey('new-fake-rawg');
    await Future<void>.delayed(Duration.zero);
    await f.controller.retry(automatic: true);
    expect(f.app.container.read(syncControllerProvider).completed, 1);
    expect(
        f.app.container.read(syncControllerProvider).needsGameAcknowledgement,
        isTrue);
    await f.controller.acknowledgeGames();
    expect(f.app.container.read(syncControllerProvider).hasActivity, isFalse);
  });

  test('Ho capito durante il recupero non interrompe i giochi in lavorazione',
      () async {
    final entered = Completer<void>();
    final release = Completer<void>();
    final f = await setup((_) async {
      if (!entered.isCompleted) entered.complete();
      await release.future;
      return http.Response(jsonEncode({'id': 2, 'name': 'Gioco'}), 200);
    }, rawgAuth: const RawgUnauthenticated());
    await f.controller.receive(wire(SyncPayload(
        shows: {},
        movies: {},
        games: {'2': GameSyncData(status: 'paused', updatedAt: stamp)})));
    await f.app.container
        .read(rawgAuthControllerProvider.notifier)
        .loginWithKey('new-fake-rawg');
    await entered.future;
    expect(
        f.app.container.read(syncControllerProvider).needsGameAcknowledgement,
        isTrue);
    expect((await f.app.db.select(f.app.db.syncItems).get()).single.status,
        'running_notice');
    await f.controller.acknowledgeGames();
    expect(f.app.container.read(syncControllerProvider).active, isTrue);
    expect(
        f.app.container.read(syncControllerProvider).needsGameAcknowledgement,
        isFalse);
    release.complete();
    await f.controller.retry(automatic: true);
    expect(f.app.container.read(syncControllerProvider).completed, 1);
    expect(f.app.container.read(syncControllerProvider).hasActivity, isFalse);
  });
  test('ripresa RAWG usa solo i giochi in attesa e un contatore crescente',
      () async {
    final f = await setup((r) async {
      final id = int.parse(r.url.pathSegments.last);
      return http.Response(
          jsonEncode({'id': id, 'title': 'Film $id', 'name': 'Gioco $id'}),
          200);
    }, rawgAuth: const RawgUnauthenticated());
    await f.controller.receive(wire(SyncPayload(
        shows: {},
        movies: movies(51).movies,
        games: {
          for (var id = 100; id < 103; id++)
            '$id': GameSyncData(status: 'paused', updatedAt: stamp)
        })));
    await f.controller.acknowledgeGames();
    expect(f.app.container.read(syncControllerProvider).total, 54);
    expect(f.app.container.read(syncControllerProvider).processed, 54);
    f.android.snapshots.clear();
    await f.app.container
        .read(rawgAuthControllerProvider.notifier)
        .loginWithKey('new-fake-rawg');
    await Future<void>.delayed(Duration.zero);
    await f.controller.retry(automatic: true);
    final active = f.android.snapshots.where((p) => p.active).toList();
    expect(active, isNotEmpty);
    expect(active.map((p) => p.total).toSet(), {3});
    final counts = active.map((p) => p.processed).toList();
    expect(counts, orderedEquals([...counts]..sort()),
        reason: 'Il contatore non deve arretrare durante la ripresa.');
    expect(counts.first, 0);
    expect(f.app.container.read(syncControllerProvider).processed, 3);
    expect(f.app.container.read(syncControllerProvider).counter,
        '3/3 giochi aggiornati');
  });
  test(
      'giochi differiti in più sessioni: identità contata e scaricata una volta',
      () async {
    final fetched = <int>[];
    final f = await setup((r) async {
      final id = int.parse(r.url.pathSegments.last);
      fetched.add(id);
      return http.Response(jsonEncode({'id': id, 'name': 'Gioco $id'}), 200);
    }, rawgAuth: const RawgUnauthenticated());
    SyncPayload games(List<int> ids) =>
        SyncPayload(shows: {}, movies: {}, games: {
          for (final id in ids)
            '$id': GameSyncData(status: 'paused', updatedAt: stamp)
        });
    await f.controller.receive(wire(games([100])));
    await f.controller.acknowledgeGames();
    await f.controller.receive(wire(games([100, 101])));
    await f.controller.acknowledgeGames();
    f.android.snapshots.clear();
    await f.app.container
        .read(rawgAuthControllerProvider.notifier)
        .loginWithKey('new-fake-rawg');
    await Future<void>.delayed(Duration.zero);
    await f.controller.retry(automatic: true);
    expect(fetched, unorderedEquals([100, 101]));
    final active = f.android.snapshots.where((p) => p.active).toList();
    expect(active.map((p) => p.total).toSet(), {2});
    final counts = active.map((p) => p.processed).toList();
    expect(counts, orderedEquals([...counts]..sort()));
    expect(f.app.container.read(syncControllerProvider).counter,
        '2/2 giochi aggiornati');
    expect(
        (await f.app.db.select(f.app.db.syncItems).get())
            .every((i) => i.status == 'completed'),
        isTrue);
  });
}
