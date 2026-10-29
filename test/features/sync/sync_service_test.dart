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
import 'package:showtracker/features/sync/utils/sync_compressor.dart';

final _date = DateTime.utc(2026, 10, 1, 12);
int get _timestamp => _date.millisecondsSinceEpoch ~/ 1000;

SyncPayload _payload({
  int? timestamp,
  String status = 'completed',
  Map<String, String> eps = const {'1': '2-3', '2': '1'},
}) =>
    SyncPayload(
      shows: {
        '101': ShowSyncData(
            status: status,
            updatedAt: timestamp ?? _timestamp,
            eps: Map.of(eps))
      },
      games: {
        '202': GameSyncData(status: status, updatedAt: timestamp ?? _timestamp)
      },
      movies: {
        '303': MovieSyncData(status: status, updatedAt: timestamp ?? _timestamp)
      },
    );

SyncService _service(AppDatabase db, http.Client client) => SyncService(
      db,
      db.showsDao,
      db.gamesDao,
      db.moviesDao,
      TmdbService(client),
      RawgService(client),
    );

Future<int> _seed(AppDatabase db, {bool hasUpdatedAt = true}) async {
  final showId = await db.showsDao.insertShow(TrackedShowsCompanion.insert(
    tmdbId: 101,
    title: 'Serie locale',
    status: MediaStatus.watching,
    addedAt: _date,
    updatedAt: Value(hasUpdatedAt ? _date : null),
    userRating: const Value(8.5),
  ));
  await db.gamesDao.insertGame(TrackedGamesCompanion.insert(
    rawgId: 202,
    title: 'Gioco locale',
    status: MediaStatus.paused,
    addedAt: _date,
    updatedAt: Value(hasUpdatedAt ? _date : null),
  ));
  await db.moviesDao.insertMovie(TrackedMoviesCompanion.insert(
    tmdbId: 303,
    title: 'Film locale',
    status: MediaStatus.planToWatch,
    addedAt: _date,
    updatedAt: Value(hasUpdatedAt ? _date : null),
  ));
  for (final ep in [1, 2, 4]) {
    await db.into(db.trackedEpisodes).insert(TrackedEpisodesCompanion.insert(
          showId: showId,
          seasonNumber: 1,
          episodeNumber: ep,
          watched: Value(ep != 4),
          updatedAt: Value(_date),
        ));
  }
  return showId;
}

void main() {
  late AppDatabase source;
  late AppDatabase target;
  late MockClient client;
  late int requests;
  late SyncService sender;
  late SyncService receiver;

  late bool previousMultipleDatabasesWarning;
  setUpAll(() {
    previousMultipleDatabasesWarning =
        driftRuntimeOptions.dontWarnAboutMultipleDatabases;
    // Due dispositivi simulati: executor distinti, nessuna connessione condivisa.
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });
  tearDownAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases =
        previousMultipleDatabasesWarning;
  });

  setUp(() {
    source = AppDatabase.forTesting(NativeDatabase.memory());
    target = AppDatabase.forTesting(NativeDatabase.memory());
    requests = 0;
    client = MockClient((request) async {
      requests++;
      throw http.ClientException('offline simulato', request.url);
    });
    sender = _service(source, client);
    receiver = _service(target, client);
  });

  tearDown(() async {
    client.close();
    await source.close();
    await target.close();
  });

  test('round-trip due database via compressione non chiama API', () async {
    await _seed(source);
    final exported = await sender.exportData();
    expect(exported.shows['101']!.eps, {'1': '1-2'});
    expect(exported.shows['101']!.updatedAt, _timestamp);
    final wire = SyncCompressor.compressPayload(exported.toJson());
    await receiver.importData(
        SyncPayload.fromJson(SyncCompressor.decompressPayload(wire)));
    expect((await receiver.exportData()).toJson(), exported.toJson());
    expect((await target.showsDao.getByTmdbId(101))!.title, 'Sconosciuto');
    expect((await target.gamesDao.getByRawgId(202))!.title, 'Sconosciuto');
    expect((await target.moviesDao.getByTmdbId(303))!.title, 'Sconosciuto');
    expect(await target.select(target.trackedEpisodes).get(), hasLength(2));
    expect(requests, 0);
  });

  for (final offset in [60, -60, 0]) {
    test(
        'conflitto timestamp ${offset > 0 ? 'newer' : offset < 0 ? 'older' : 'equal'} in tutti i domini',
        () async {
      await _seed(target);
      final incomingTimestamp = _timestamp + offset;
      await receiver.importData(_payload(timestamp: incomingTimestamp));
      final show = (await target.showsDao.getByTmdbId(101))!;
      final game = (await target.gamesDao.getByRawgId(202))!;
      final movie = (await target.moviesDao.getByTmdbId(303))!;
      expect(show.status,
          offset > 0 ? MediaStatus.completed : MediaStatus.watching);
      expect(
          game.status, offset > 0 ? MediaStatus.completed : MediaStatus.paused);
      expect(movie.status,
          offset > 0 ? MediaStatus.completed : MediaStatus.planToWatch);
      final expectedDate =
          offset > 0 ? _date.add(Duration(seconds: offset)) : _date;
      expect(show.updatedAt!.toUtc(), expectedDate);
      expect(game.updatedAt!.toUtc(), expectedDate);
      expect(movie.updatedAt!.toUtc(), expectedDate);
      expect(show.title, 'Serie locale');
      expect(show.userRating, 8.5);
      // Gli episodi sono un'unione, anche quando lo stato remoto è più vecchio.
      final episodes = await target.showsDao.getEpisodesByShow(show.id);
      expect(
          episodes
              .where((e) => e.watched)
              .map((e) => '${e.seasonNumber}:${e.episodeNumber}')
              .toSet(),
          {'1:1', '1:2', '1:3', '2:1'});
      expect(
          episodes
              .singleWhere((e) => e.seasonNumber == 1 && e.episodeNumber == 4)
              .watched,
          isFalse);
      expect(requests, 0);
    });
  }

  test('updatedAt assente usa addedAt per export e risoluzione conflitti',
      () async {
    await _seed(target, hasUpdatedAt: false);
    final exported = await receiver.exportData();
    expect(exported.shows['101']!.updatedAt, _timestamp);
    expect(exported.games['202']!.updatedAt, _timestamp);
    expect(exported.movies['303']!.updatedAt, _timestamp);
    await receiver.importData(_payload(timestamp: _timestamp - 1));
    expect(
        (await target.showsDao.getByTmdbId(101))!.status, MediaStatus.watching);
    expect(
        (await target.gamesDao.getByRawgId(202))!.status, MediaStatus.paused);
    expect((await target.moviesDao.getByTmdbId(303))!.status,
        MediaStatus.planToWatch);
    await receiver.importData(_payload(timestamp: _timestamp + 1));
    expect((await target.showsDao.getByTmdbId(101))!.status,
        MediaStatus.completed);
    expect((await target.gamesDao.getByRawgId(202))!.status,
        MediaStatus.completed);
    expect((await target.moviesDao.getByTmdbId(303))!.status,
        MediaStatus.completed);
  });

  test('import ripetuto è idempotente anche per righe già viste e non viste',
      () async {
    final showId = await _seed(target);
    final payload =
        _payload(timestamp: _timestamp + 60, eps: {'1': '2-4', '2': '1'});
    await receiver.importData(payload);
    final firstEpisodes = await target.showsDao.getEpisodesByShow(showId);
    final firstExport = (await receiver.exportData()).toJson();
    await receiver.importData(payload);
    expect((await receiver.exportData()).toJson(), firstExport);
    final after = await target.showsDao.getEpisodesByShow(showId);
    expect(
        after.map((e) => e.id).toSet(), firstEpisodes.map((e) => e.id).toSet());
    expect(after, hasLength(5));
    expect(after.every((e) => e.watched), isTrue);
    expect(await target.showsDao.getAll(), hasLength(1));
    expect(await target.gamesDao.watchAll().first, hasLength(1));
    expect(await target.moviesDao.watchAll().first, hasLength(1));
  });

  test('film legacy watching o stato sconosciuto diventano Da vedere',
      () async {
    final payload = SyncPayload(shows: {}, games: {}, movies: {
      '1': MovieSyncData(status: 'watching', updatedAt: _timestamp),
      '2': MovieSyncData(status: 'legacy-unknown', updatedAt: _timestamp),
    });
    await receiver.importData(payload);
    expect((await target.moviesDao.watchAll().first).map((m) => m.status),
        everyElement(MediaStatus.planToWatch));
    await target.moviesDao.updateStatus(
        (await target.moviesDao.getByTmdbId(1))!.id, MediaStatus.completed);
    await (target.update(target.trackedMovies)
          ..where((m) => m.tmdbId.equals(1)))
        .write(TrackedMoviesCompanion(updatedAt: Value(_date)));
    await receiver.importData(SyncPayload(shows: {}, games: {}, movies: {
      '1': MovieSyncData(status: 'watching', updatedAt: _timestamp + 60),
    }));
    expect((await target.moviesDao.getByTmdbId(1))!.status,
        MediaStatus.planToWatch);
  });

  test(
      'identificatori non numerici vengono ignorati senza perdere righe valide',
      () async {
    final payload = _payload();
    payload.shows['invalid'] =
        ShowSyncData(status: 'watching', updatedAt: _timestamp, eps: {});
    payload.shows['101']!.eps['invalid'] = '1-5';
    payload.games['invalid'] =
        GameSyncData(status: 'watching', updatedAt: _timestamp);
    payload.movies['invalid'] =
        MovieSyncData(status: 'completed', updatedAt: _timestamp);
    await receiver.importData(payload);
    expect(await target.showsDao.getAll(), hasLength(1));
    expect(await target.gamesDao.watchAll().first, hasLength(1));
    expect(await target.moviesDao.watchAll().first, hasLength(1));
    expect(await target.select(target.trackedEpisodes).get(), hasLength(3));
  });

  test(
      'errore a fine import annulla aggiornamenti e inserimenti in tutti i domini',
      () async {
    await _seed(target);
    final before = (await receiver.exportData()).toJson();
    await target.customStatement('''
      CREATE TRIGGER reject_sync_movie BEFORE INSERT ON tracked_movies
      WHEN NEW.tmdb_id = 404 BEGIN SELECT RAISE(ABORT, 'errore test'); END
    ''');
    final payload = _payload(timestamp: _timestamp + 60);
    payload.shows['505'] = ShowSyncData(
        status: 'watching', updatedAt: _timestamp, eps: {'1': '1-5'});
    payload.movies['404'] =
        MovieSyncData(status: 'completed', updatedAt: _timestamp);
    await expectLater(receiver.importData(payload), throwsA(isA<Exception>()));
    expect((await receiver.exportData()).toJson(), before);
    expect(await target.showsDao.getByTmdbId(505), isNull);
    expect(await target.moviesDao.getByTmdbId(404), isNull);
    final show = (await target.showsDao.getByTmdbId(101))!;
    expect(await target.showsDao.getEpisodesByShow(show.id), hasLength(3));
    expect(requests, 0);
  });

  test('idratazione offline conserva archivio e continua con gli altri domini',
      () async {
    await receiver.importData(_payload());
    final before = (await receiver.exportData()).toJson();
    await receiver.hydrateUnknownMedia();
    expect(requests, 5); // due lingue TMDB per serie/film, un dettaglio RAWG.
    expect((await receiver.exportData()).toJson(), before);
    expect((await target.showsDao.getByTmdbId(101))!.title, 'Sconosciuto');
    expect((await target.moviesDao.getByTmdbId(303))!.title, 'Sconosciuto');
    expect((await target.gamesDao.getByRawgId(202))!.title, 'Sconosciuto');
  });

  test(
      'idratazione aggiorna metadati senza cambiare progressi e timestamp sync',
      () async {
    await receiver.importData(_payload());
    final before = (await receiver.exportData()).toJson();
    final paths = <String>[];
    final metadataClient = MockClient((request) async {
      paths.add(request.url.path);
      final body = switch (request.url.path) {
        '/3/tv/101' => <String, dynamic>{
            'id': 101,
            'name': 'Serie idratata',
            'number_of_seasons': 2,
            'number_of_episodes': 24,
            'status': 'Returning Series',
            'next_episode_to_air': {
              'season_number': 2,
              'episode_number': 2,
              'name': 'Nuovo episodio',
              'air_date': '2026-11-01'
            },
          },
        '/3/movie/303' => <String, dynamic>{
            'id': 303,
            'title': 'Film idratato',
            'release_date': '2020-05-06'
          },
        '/api/games/202' => <String, dynamic>{
            'id': 202,
            'name': 'Gioco idratato',
            'released': '2021-06-07',
            'playtime': 20,
            'rating': 4.5
          },
        _ => throw StateError('Richiesta inattesa ${request.url}'),
      };
      return http.Response(jsonEncode(body), 200);
    });
    addTearDown(metadataClient.close);
    await _service(target, metadataClient).hydrateUnknownMedia();
    expect(paths, hasLength(5));
    final show = (await target.showsDao.getByTmdbId(101))!;
    expect(show.title, 'Serie idratata');
    expect(show.totalEpisodes, 24);
    expect(show.nextEpisodeNumber, 2);
    expect(show.nextEpisodeSeason, 2);
    expect(show.nextEpisodeAirDate, DateTime(2026, 11, 1, 9));
    final movie = (await target.moviesDao.getByTmdbId(303))!;
    expect(movie.title, 'Film idratato');
    expect(movie.releaseYear, 2020);
    final game = (await target.gamesDao.getByRawgId(202))!;
    expect(game.title, 'Gioco idratato');
    expect(game.playtime, 20);
    expect((await receiver.exportData()).toJson(), before);
    await _service(target, metadataClient).hydrateUnknownMedia();
    expect(paths, hasLength(5)); // nessuna richiesta per media già idratati.
  });
}
