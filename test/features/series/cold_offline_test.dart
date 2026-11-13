import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:showtracker/core/database/app_database.dart';
import 'package:showtracker/core/database/database_provider.dart';
import 'package:showtracker/core/riverpod_utils.dart';
import 'package:showtracker/features/series/data/models/anilist_media.dart';
import 'package:showtracker/features/series/data/models/normalized_anime_season.dart';
import 'package:showtracker/features/series/data/tmdb_service.dart';
import 'package:showtracker/features/series/providers/series_providers.dart';

// Public helpers are shared only with cold_offline_screen_test.dart.
Future<int> seedColdShow(AppDatabase db,
    {bool anime = false,
    bool expired = false,
    bool cacheEpisodes = true}) async {
  final id = await db.showsDao.insertShow(TrackedShowsCompanion(
    tmdbId: const Value(42),
    title: Value(anime ? 'Anime salvato' : 'Regina Rossa'),
    overview: const Value('Trama salvata sul dispositivo'),
    status: const Value(MediaStatus.watching),
    totalSeasons: Value(anime ? 2 : 3),
    totalEpisodes: Value(anime ? 24 : 14),
    tmdbStatus: const Value('Returning Series'),
    isAnime: Value(anime),
    addedAt: Value(DateTime.utc(2020)),
    nextEpisodeSeason: Value(anime ? 2 : null),
    nextEpisodeNumber: Value(anime ? 9 : null),
    nextEpisodeName: Value(anime ? 'Prossimo episodio salvato' : null),
    nextEpisodeAirDate: Value(anime ? DateTime.utc(2050) : null),
  ));
  final counts = anime ? {1: 12, 2: 12} : {1: 7, 2: 6, 3: 1};
  await db.showsDao.insertSeasons(id, counts);
  for (final entry in counts.entries) {
    if (entry.key == (anime ? 2 : 3)) break;
    for (var e = 1; e <= entry.value; e++) {
      await db.showsDao.markEpisodeWatched(id, entry.key, e);
    }
  }
  await (db.update(db.trackedShows)..where((t) => t.id.equals(id))).write(
    TrackedShowsCompanion(
        updatedAt: Value(DateTime.utc(2020, 2)),
        lastWatchedAt: Value(DateTime.utc(2020, 2))),
  );
  if (anime) {
    await db.animeCacheDao.saveAnimeSeasons(42, [
      for (var cour = 1; cour <= 2; cour++)
        NormalizedAnimeSeason(
            seasonNumber: cour,
            tmdbSeasonNumber: 1,
            anilistId: 100 + cour,
            episodeCount: 12,
            status: 'FINISHED',
            season: cour == 1 ? 'WINTER' : 'SPRING',
            seasonYear: 2020,
            titleEnglish: 'Anime salvato',
            nextAiringEpisode: cour == 2
                ? AniListNextAiring(
                    episode: 9,
                    airingAt: DateTime.utc(2050).millisecondsSinceEpoch ~/ 1000,
                    timeUntilAiring: 1)
                : null,
            streamingEpisodes: const []),
    ]);
    if (expired) await db.animeCacheDao.expireAnimeCacheForShow(42);
  }
  if (cacheEpisodes) {
    await db.cacheDao.saveSeasonEpisodes([
      CachedEpisodesCompanion.insert(
          tmdbShowId: 42,
          seasonNumber: anime ? 2 : 3,
          episodeNumber: 1,
          name: anime ? 'Il secondo cour' : 'Episode 1',
          overview: const Value('Trama episodio locale'),
          airDate: Value(anime ? '2020-04-01' : null),
          absoluteEpisodeNumber: Value(anime ? 13 : null),
          airingAt: Value(anime ? DateTime.utc(2020, 4, 1, 21) : null),
          cachedAt: expired ? DateTime.utc(2000) : DateTime.now()),
    ]);
  }
  return id;
}

Future<String> coldSnapshot(AppDatabase db, {bool includeCache = true}) async =>
    jsonEncode([
      for (final table in [
        'tracked_shows',
        'tracked_seasons',
        'tracked_episodes',
        if (includeCache) ...[
          'cached_episodes',
          'anime_season_cache',
          'yuna_cache'
        ]
      ])
        (await db.customSelect('SELECT * FROM $table ORDER BY 1').get())
            .map((row) => row.data)
            .toList(),
    ]);

void main() {
  late AppDatabase db;
  late ProviderContainer container;
  late MockClient client;
  late List<Uri> requests;
  late Object failure;
  int? status;
  var online = false;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.customSelect('SELECT 1').get();
    requests = [];
    failure = http.ClientException('Failed host lookup: api.themoviedb.org');
    status = null;
    online = false;
    client = MockClient((request) async {
      requests.add(request.url);
      if (status != null) return http.Response('{}', status!);
      if (!online) throw failure;
      return http.Response(
          jsonEncode({
            'id': 42,
            'name': 'Regina Rossa aggiornata',
            'in_production': true,
            'status': 'Returning Series',
            'number_of_seasons': 3,
            'number_of_episodes': 15,
            'genres': [],
            'origin_country': [],
            'seasons': [
              for (var n = 1; n <= 3; n++)
                {
                  'season_number': n,
                  'episode_count': n == 1 ? 7 : (n == 2 ? 6 : 2),
                  'name': 'Stagione $n',
                }
            ],
          }),
          200);
    });
    container = ProviderContainer(retry: noProviderRetry, overrides: [
      databaseProvider.overrideWithValue(db),
      tmdbServiceProvider.overrideWithValue(TmdbService(client)),
    ]);
  });
  tearDown(() async {
    container.dispose();
    client.close();
    await db.close();
  });

  Future<void> transportOnly(Future<void> Function() body) =>
      http.runWithClient(() async {
        await body();
        expect(requests, isNotEmpty);
        expect(requests.every((u) => u.host == 'api.themoviedb.org'), isTrue,
            reason: 'Cold fallback must not launch Yuna or AniList requests');
      }, () => client);

  test('cold regular cache preserves stored 09:00 instead of midnight',
      () async {
    final id = await seedColdShow(db);
    final airing = DateTime(2050, 1, 2, 9);
    await (db.update(db.trackedShows)..where((t) => t.id.equals(id))).write(
      TrackedShowsCompanion(
          nextEpisodeSeason: const Value(3),
          nextEpisodeNumber: const Value(1),
          nextEpisodeAirDate: Value(airing)),
    );
    await db.cacheDao.saveSeasonEpisodes([
      CachedEpisodesCompanion.insert(
          tmdbShowId: 42,
          seasonNumber: 3,
          episodeNumber: 1,
          name: 'Episodio futuro',
          airDate: const Value('2050-01-02'),
          cachedAt: DateTime(2000)),
    ]);
    final local = await container
        .readFuture(seasonDetailProvider(showId: 42, seasonNumber: 3).future);
    expect(local.episodes!.single.airingAt?.isAtSameMomentAs(airing), isTrue);
    expect(local.episodes!.single.hasAired, isFalse);
  });

  for (final socket in [false, true]) {
    test(
        'cold normal snapshot preserves metadata (${socket ? 'socket' : 'DNS'})',
        () => transportOnly(() async {
              if (socket) failure = const SocketException('Failed host lookup');
              final id = await seedColdShow(db);
              final before = await coldSnapshot(db);
              final detail =
                  await container.readFuture(showDetailProvider(42).future);
              expect(detail.isLocalSnapshot, isTrue);
              expect(detail.name, 'Regina Rossa');
              expect(detail.overview, 'Trama salvata sul dispositivo');
              expect(detail.numberOfEpisodes, 14);
              expect(detail.seasons.map((s) => s.episodeCount), [7, 6, 1]);
              expect(detail.backdropPath, isNull);
              expect(detail.isAnime, isFalse);
              final season = await container.readFuture(
                  seasonDetailProvider(showId: 42, seasonNumber: 3).future);
              expect(season.isLocalSnapshot, isTrue);
              expect(season.episodes!.single.name, 'Episode 1');
              expect(season.episodes!.single.airDate, isNull);
              final notifier = container.read(trackedShowsProvider.notifier);
              await notifier.syncMetadata(detail, id);
              await notifier.rescheduleNotification(detail);
              await notifier.rescheduleNotificationById(42);
              await notifier.rescheduleAllNotifications();
              expect(await coldSnapshot(db), before,
                  reason:
                      'Partial local reads must not rewrite sync/progress/pointers');
            }));
  }

  for (final expired in [false, true]) {
    test(
        'cold anime retains both cours and ${expired ? 'stale' : 'fresh'} episodes',
        () => transportOnly(() async {
              final id = await seedColdShow(db, anime: true, expired: expired);
              final before = await coldSnapshot(db);
              final detail =
                  await container.readFuture(showDetailProvider(42).future);
              expect(detail.isLocalSnapshot, isTrue);
              expect(detail.isAnime, isTrue);
              expect(detail.originCountries, isEmpty,
                  reason:
                      'Local anime identity must not invent a country or genre');
              expect(detail.animeSeasonsData!.map((s) => s.tmdbSeasonNumber),
                  [1, 1]);
              expect(detail.seasons.map((s) => s.seasonNumber), [1, 2]);
              expect(
                  detail.seasons.last.name, startsWith('Stagione 1 Parte 2'));
              final copy = detail.copyWith(
                  name: 'Altro titolo', seasons: detail.seasons);
              expect(copy.isLocalSnapshot, isTrue);
              expect(copy.isAnime, isTrue);
              expect(copy.animeSeasonsData, detail.animeSeasonsData);
              final season = await container.readFuture(
                  seasonDetailProvider(showId: 42, seasonNumber: 2).future);
              expect(season.isLocalSnapshot, isTrue);
              final episode = season.episodes!.single;
              expect(episode.episodeNumber, 1);
              expect(episode.name, 'Il secondo cour');
              expect(episode.overview, 'Trama episodio locale');
              expect(episode.airDate, '2020-04-01');
              expect(episode.airingAt?.toUtc(), DateTime.utc(2020, 4, 1, 21));
              expect(episode.absoluteEpisodeNumber, 13);
              final notifier = container.read(trackedShowsProvider.notifier);
              await notifier.syncMetadata(detail, id);
              await notifier.rescheduleNotification(detail);
              await notifier.rescheduleNotificationById(42);
              await notifier.rescheduleAllNotifications();
              expect(await coldSnapshot(db), before);
            }));
  }

  test(
      'missing episode cache stays explicitly partial, not authoritative empty',
      () => transportOnly(() async {
            await seedColdShow(db,
                anime: true, expired: true, cacheEpisodes: false);
            final before = await coldSnapshot(db);
            final season = await container.readFuture(
                seasonDetailProvider(showId: 42, seasonNumber: 2).future);
            expect(season.isLocalSnapshot, isTrue);
            expect(season.episodes ?? [], isEmpty);
            expect(await coldSnapshot(db), before);
          }));

  for (final code in [401, 403, 404]) {
    test(
        'HTTP $code is not disguised as a local success',
        () => transportOnly(() async {
              await seedColdShow(db);
              status = code;
              final before = await coldSnapshot(db);
              await expectLater(
                  container.readFuture(showDetailProvider(42).future),
                  throwsA(isA<TmdbException>()
                      .having((e) => e.statusCode, 'statusCode', code)));
              expect(await coldSnapshot(db), before);
            }));
  }

  test(
      'untracked show cannot fabricate a local detail',
      () => transportOnly(() async {
            await expectLater(
                container.readFuture(showDetailProvider(999).future),
                throwsA(anything));
            expect(await db.showsDao.getAll(), isEmpty);
          }));

  test(
      'explicit retry after reconnection returns authoritative remote data',
      () => transportOnly(() async {
            await seedColdShow(db);
            // Keep the snapshot observed until explicit invalidation, like the screen.
            final sub = container.listen(showDetailProvider(42), (_, __) {});
            addTearDown(sub.close);
            final local =
                await container.readFuture(showDetailProvider(42).future);
            expect(local.isLocalSnapshot, isTrue);
            final before = await coldSnapshot(db);
            online = true;
            container.invalidate(rawShowDetailProvider(42));
            container.invalidate(showDetailProvider(42));
            final remote =
                await container.readFuture(showDetailProvider(42).future);
            expect(remote.isLocalSnapshot, isFalse);
            expect(
                remote.copyWith(name: 'Copia remota').isLocalSnapshot, isFalse);
            expect(remote.name, 'Regina Rossa aggiornata');
            expect(remote.numberOfEpisodes, 15);
            expect(await coldSnapshot(db), before,
                reason:
                    'Reading recovered metadata is not itself a progress mutation');
          }));
}
