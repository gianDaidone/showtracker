import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:showtracker/core/database/app_database.dart';
import 'package:showtracker/core/database/database_provider.dart';
import 'package:showtracker/core/riverpod_utils.dart';
import 'package:showtracker/features/series/data/anilist_service.dart';
import 'package:showtracker/features/series/data/models/anilist_media.dart';
import 'package:showtracker/features/series/data/models/normalized_anime_season.dart';
import 'package:showtracker/core/services/notification_service.dart';
import 'package:showtracker/features/series/data/tmdb_service.dart';
import 'package:showtracker/features/series/data/yuna_service.dart';
import 'package:showtracker/features/series/providers/series_providers.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class _AniList implements AniListService {
  late AniListMedia media;
  int requests = 0;
  final List<List<int>> requestedIds = [];
  bool offline = false;
  List<AniListMedia> searchResults = [];
  final List<String> searches = [];

  @override
  Future<List<AniListMedia>> fetchBatch(List<int> ids) async {
    requests++;
    requestedIds.add(List.of(ids));
    if (offline) throw StateError('AniList offline');
    return [media];
  }

  @override
  Future<AniListMedia?> fetchById(int id) async =>
      (await fetchBatch([id])).firstOrNull;

  @override
  Future<List<AniListMedia>> searchByTitle(String title) async {
    searches.add(title);
    if (offline) throw StateError('AniList offline');
    return searchResults;
  }

  @override
  void dispose() {}
}

class _Yuna implements YunaService {
  List<int> ids = [200];
  int requests = 0;

  @override
  Future<List<int>> getAniListIds(int tmdbId) async {
    requests++;
    return ids;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dexterous.com/flutter/local_notifications');
  late AppDatabase db;
  late ProviderContainer container;
  late _AniList anilist;
  late _Yuna yuna;
  late http.Client client;
  late List<Uri> tmdbRequests;
  late int showId;
  late DateTime yesterday;
  late DateTime nextWeek;
  late List<MethodCall> notificationCalls;
  bool tmdbOffline = false;
  bool notificationFails = false;
  bool isAnime = true;
  bool staleTmdbPointer = false;

  AniListNextAiring airing(int episode, DateTime date) => AniListNextAiring(
        episode: episode,
        airingAt: date.millisecondsSinceEpoch ~/ 1000,
        timeUntilAiring: 0,
      );

  NormalizedAnimeSeason season({int episode = 8, DateTime? date}) =>
      NormalizedAnimeSeason(
        seasonNumber: 1,
        tmdbSeasonNumber: 1,
        anilistId: 200,
        episodeCount: 12,
        status: 'RELEASING',
        nextAiringEpisode: airing(episode, date ?? yesterday),
        streamingEpisodes: const [],
      );

  Future<void> saveCache({bool fresh = false}) async {
    await db.animeCacheDao.saveAnimeSeasons(100,
        [season(episode: fresh ? 9 : 8, date: fresh ? nextWeek : yesterday)]);
    if (!fresh) await db.animeCacheDao.expireAnimeCacheForShow(100);
    await db.animeCacheDao.saveYunaIds(100, [200]);
  }

  Future<void> markWatchedAndRefresh() async {
    // Stesso percorso della card, senza montare la pagina di dettaglio.
    await db.showsDao.markEpisodeWatched(showId, 1, 8);
    await container
        .read(trackedShowsProvider.notifier)
        .rescheduleNotificationById(100);
  }

  setUp(() async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.UTC);
    yesterday = DateTime.now().subtract(const Duration(days: 1));
    nextWeek = DateTime.fromMillisecondsSinceEpoch(
        DateTime.now().add(const Duration(days: 7)).millisecondsSinceEpoch ~/
            1000 *
            1000);
    tmdbOffline = false;
    notificationFails = false;
    isAnime = true;
    staleTmdbPointer = false;
    notificationCalls = [];
    tmdbRequests = [];
    yuna = _Yuna();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      notificationCalls.add(call);
      if (notificationFails) throw PlatformException(code: 'permission_denied');
      return null;
    });

    db = AppDatabase.forTesting(NativeDatabase.memory());
    showId = await db.showsDao.insertShow(TrackedShowsCompanion(
      tmdbId: const Value(100),
      title: const Value('Anime'),
      status: const Value(MediaStatus.watching),
      isAnime: const Value(true),
      addedAt: Value(yesterday),
      totalEpisodes: const Value(12),
      totalSeasons: const Value(1),
      tmdbStatus: const Value('Returning Series'),
      nextEpisodeSeason: const Value(1),
      nextEpisodeNumber: const Value(8),
      nextEpisodeAirDate: Value(yesterday),
    ));
    await db.showsDao.insertSeasons(showId, {1: 12});
    await db.animeCacheDao.saveYunaIds(100, [200]);
    anilist = _AniList()
      ..media = AniListMedia(
        id: 200,
        status: 'RELEASING',
        format: 'TV',
        episodes: 12,
        nextAiringEpisode: airing(9, nextWeek),
        streamingEpisodes: const [],
      );
    client = MockClient((request) async {
      tmdbRequests.add(request.url);
      if (tmdbOffline) throw StateError('TMDB offline');
      if (request.url.path == '/3/tv/100/season/1') {
        return http.Response(
            jsonEncode({
              'season_number': 1,
              'episodes': [
                {
                  'episode_number': 8,
                  'name': 'Già uscito',
                  'air_date': yesterday.toIso8601String().split('T').first
                },
                {
                  'episode_number': 9,
                  'name': 'Davvero futuro',
                  'air_date': nextWeek.toIso8601String().split('T').first
                },
              ],
            }),
            200);
      }
      expect(request.url.path, '/3/tv/100');
      return http.Response(
          jsonEncode({
            'id': 100,
            'name': 'Anime',
            'status': 'Returning Series',
            'in_production': true,
            'number_of_seasons': 1,
            'number_of_episodes': 12,
            'genres': [
              {'name': isAnime ? 'Animation' : 'Drama'},
            ],
            'origin_country': [isAnime ? 'JP' : 'US'],
            'seasons': [
              {'season_number': 1, 'episode_count': 12},
            ],
            'next_episode_to_air': {
              'season_number': 1,
              'episode_number': staleTmdbPointer ? 8 : 9,
              'name': 'Il prossimo episodio',
              'air_date': (staleTmdbPointer ? yesterday : nextWeek)
                  .toIso8601String()
                  .split('T')
                  .first,
            },
          }),
          200);
    });
    container = ProviderContainer(
      retry: noProviderRetry,
      overrides: [
        databaseProvider.overrideWithValue(db),
        tmdbServiceProvider.overrideWithValue(TmdbService(client)),
        anilistServiceProvider.overrideWithValue(anilist),
        yunaServiceProvider.overrideWithValue(yuna),
      ],
    );
  });

  tearDown(() async {
    notificationFails = false;
    await NotificationService.cancelAll();
    container.dispose();
    await db.close();
    client.close();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  test('dopo X visto salva Y e aggiorna In Uscita senza aprire il dettaglio',
      () async {
    await saveCache(fresh: true);
    final appeared = Completer<List<UpcomingEpisodeInfo>>();
    container.listen(upcomingEpisodesProvider, (_, next) {
      final items = next.value;
      if (items != null &&
          items.any((i) => i.episode.episodeNumber == 9) &&
          !appeared.isCompleted) {
        appeared.complete(items);
      }
    });
    expect(await container.read(upcomingEpisodesProvider.future), isEmpty);

    await markWatchedAndRefresh();

    final show = (await db.showsDao.getById(showId))!;
    expect(show.nextEpisodeNumber, 9);
    expect(show.nextEpisodeSeason, 1);
    expect(show.nextEpisodeAirDate, nextWeek);
    final items = await appeared.future.timeout(const Duration(seconds: 5));
    expect(items.single.episode.episodeNumber, 9);
    expect(items.single.preciseAirTime, nextWeek);
    expect(anilist.requests, 0);
    expect(notificationCalls.any((c) => c.method == 'zonedSchedule'), isTrue);
  });

  test('ricarica i provider già completati se la cache anime è scaduta',
      () async {
    await db.animeCacheDao.saveAnimeSeasons(100, [season()]);
    container.listen(showDetailProvider(100), (_, __) {});
    container.listen(animeDataProvider(100), (_, __) {});
    final old = await container.read(showDetailProvider(100).future);
    expect(old.animeSeasonsData!.single.nextAiringEpisode!.episode, 8);
    await db.animeCacheDao.expireAnimeCacheForShow(100);
    await db.animeCacheDao.saveYunaIds(100, [200]);

    await markWatchedAndRefresh();

    expect((await db.showsDao.getById(showId))!.nextEpisodeNumber, 9);
    expect(anilist.requests, 1);
    expect(
        (await db.animeCacheDao.getFreshAnimeSeasons(100))!
            .single
            .nextAiringEpisode!
            .episode,
        9);
  });

  test('carica e salva Y anche senza listener della UI', () async {
    await saveCache();

    await markWatchedAndRefresh();

    expect((await db.showsDao.getById(showId))!.nextEpisodeNumber, 9);
    expect(anilist.requests, 1);
    expect(
        (await container.readFuture(upcomingEpisodesProvider.future))
            .single
            .episode
            .episodeNumber,
        9);
  });

  test('fallback anime scaduto non cancella il prossimo episodio già noto',
      () async {
    await saveCache();
    await (db.update(db.trackedShows)..where((t) => t.id.equals(showId))).write(
        TrackedShowsCompanion(
            nextEpisodeNumber: const Value(9),
            nextEpisodeAirDate: Value(nextWeek)));
    anilist.offline = true;

    await markWatchedAndRefresh();

    final show = (await db.showsDao.getById(showId))!;
    expect(show.nextEpisodeNumber, 9);
    expect(show.nextEpisodeAirDate, nextWeek);
    expect(await db.showsDao.getSeasonCounts(showId), {1: 12});
    expect(await db.animeCacheDao.getFreshAnimeSeasons(100), isNull);
    expect(
        (await db.animeCacheDao.getStaleAnimeSeasons(100))!
            .single
            .nextAiringEpisode!
            .episode,
        8);
    expect(await db.showsDao.countWatchedEpisodes(showId), 1);
    expect(notificationCalls, isEmpty);
  });

  test('errore TMDB non annulla il visto né i dati locali', () async {
    await saveCache();
    tmdbOffline = true;

    await markWatchedAndRefresh();

    expect((await db.showsDao.getById(showId))!.nextEpisodeNumber, 8);
    expect(await db.showsDao.countWatchedEpisodes(showId), 1);
    expect(await db.animeCacheDao.getStaleAnimeSeasons(100), isNotEmpty);
  });

  test('anime concluso con cache fresca rimuove il vecchio puntatore',
      () async {
    await db.animeCacheDao.saveAnimeSeasons(100, [
      const NormalizedAnimeSeason(
        seasonNumber: 1,
        tmdbSeasonNumber: 1,
        anilistId: 200,
        episodeCount: 12,
        status: 'FINISHED',
        streamingEpisodes: [],
      ),
    ]);

    await markWatchedAndRefresh();

    final show = (await db.showsDao.getById(showId))!;
    expect(show.nextEpisodeNumber, isNull);
    expect(show.nextEpisodeAirDate, isNull);
    expect(
        await container.readFuture(upcomingEpisodesProvider.future), isEmpty);
    expect(anilist.requests, 0);
  });

  test('sincronizza anche il prossimo episodio delle serie non anime',
      () async {
    isAnime = false;
    await (db.update(db.trackedShows)..where((t) => t.id.equals(showId)))
        .write(const TrackedShowsCompanion(isAnime: Value(false)));

    await markWatchedAndRefresh();

    final show = (await db.showsDao.getById(showId))!;
    expect(show.nextEpisodeNumber, 9);
    expect(show.nextEpisodeName, 'Il prossimo episodio');
    expect(show.nextEpisodeAirDate,
        DateTime(nextWeek.year, nextWeek.month, nextWeek.day, 9));
    expect(anilist.requests, 0);
  });

  test('puntatore TMDB già uscito avanza al primo episodio realmente futuro',
      () async {
    isAnime = false;
    staleTmdbPointer = true;
    await (db.update(db.trackedShows)..where((t) => t.id.equals(showId)))
        .write(const TrackedShowsCompanion(isAnime: Value(false)));

    await markWatchedAndRefresh();

    final show = (await db.showsDao.getById(showId))!;
    expect(show.nextEpisodeNumber, 9);
    expect(show.nextEpisodeName, 'Davvero futuro');
    expect(show.nextEpisodeAirDate,
        DateTime(nextWeek.year, nextWeek.month, nextWeek.day, 9));
    expect(tmdbRequests.any((uri) => uri.path.endsWith('/season/1')), isTrue);
    expect(notificationCalls.any((call) => call.method == 'zonedSchedule'),
        isTrue);
  });

  test('errore notifica non impedisce di salvare Y', () async {
    await saveCache(fresh: true);
    notificationFails = true;

    await markWatchedAndRefresh();

    expect(await db.showsDao.countWatchedEpisodes(showId), 1);
    expect((await db.showsDao.getById(showId))!.nextEpisodeNumber, 9);
    expect(
        (await container.readFuture(upcomingEpisodesProvider.future))
            .single
            .episode
            .episodeNumber,
        9);
  });

  test('addShow attende i cour normalizzati e salva totali e stagioni',
      () async {
    await db.showsDao.deleteShow(showId);
    await db.animeCacheDao.saveAnimeSeasons(100, [
      const NormalizedAnimeSeason(
        seasonNumber: 1,
        tmdbSeasonNumber: 1,
        anilistId: 200,
        episodeCount: 12,
        status: 'FINISHED',
        streamingEpisodes: [],
      ),
      const NormalizedAnimeSeason(
        seasonNumber: 2,
        tmdbSeasonNumber: 1,
        anilistId: 201,
        episodeCount: 12,
        status: 'FINISHED',
        streamingEpisodes: [],
      ),
    ]);
    final raw = await TmdbService(client).getShowDetails(100);
    expect(raw.animeSeasonsData, isNull);
    expect(raw.numberOfEpisodes, 12);

    await container.read(trackedShowsProvider.notifier).addShow(raw);

    final saved = (await db.showsDao.getByTmdbId(100))!;
    expect(saved.isAnime, isTrue);
    expect(saved.totalEpisodes, 24);
    expect(saved.totalSeasons, 2);
    expect(await db.showsDao.getSeasonCounts(saved.id), {1: 12, 2: 12});
    expect(anilist.requests, 0);
  });

  test('syncMetadata senza normalizzazione anime non cambia dati né progressi',
      () async {
    await db.showsDao.insertSeasons(showId, {2: 12});
    await db.showsDao.markEpisodeWatched(showId, 2, 3);
    final before = (await db.showsDao.getById(showId))!;
    final counts = await db.showsDao.getSeasonCounts(showId);
    final raw = await TmdbService(client).getShowDetails(100);

    await container
        .read(trackedShowsProvider.notifier)
        .syncMetadata(raw, showId);

    expect(await db.showsDao.getById(showId), before);
    expect(await db.showsDao.getSeasonCounts(showId), counts);
    expect(await db.showsDao.countWatchedEpisodes(showId), 1);
    expect(notificationCalls, isEmpty);
  });

  test('animeData fresca evita completamente rete e mapping', () async {
    await saveCache(fresh: true);
    tmdbOffline = true;
    anilist.offline = true;

    final data = await container.readFuture(animeDataProvider(100).future);

    expect(data!.single.nextAiringEpisode!.episode, 9);
    expect(tmdbRequests, isEmpty);
    expect(anilist.requests, 0);
    expect(yuna.requests, 0);
  });

  test('animeData scaduta durante outage conserva numerazione cour', () async {
    await saveCache();
    anilist.offline = true;

    final data = await container.readFuture(animeDataProvider(100).future);

    expect(data!.single.seasonNumber, 1);
    expect(data.single.anilistId, 200);
    expect(data.single.nextAiringEpisode!.episode, 8);
    expect(await db.animeCacheDao.getFreshAnimeSeasons(100), isNull);
    expect(anilist.requests, 1);
  });

  test('animeData senza cache durante outage restituisce null, non TMDB',
      () async {
    anilist.offline = true;

    expect(await container.readFuture(animeDataProvider(100).future), isNull);
    expect(await db.animeCacheDao.getStaleAnimeSeasons(100), isNull);
  });

  test('seasonDetail senza anime cache non chiede cour sintetici a TMDB',
      () async {
    anilist.offline = true;

    final result = await container.readFuture(
      seasonDetailProvider(showId: 100, seasonNumber: 5).future,
    );

    expect(result.seasonNumber, 5);
    expect(result.episodeCount, 0);
    expect(result.episodes, isNull);
    expect(tmdbRequests, isNotEmpty);
    expect(tmdbRequests.every((u) => u.path == '/3/tv/100'), isTrue);
  });

  test('ricerca sequel scarta il primo risultato con data troppo lontana',
      () async {
    await (db.delete(db.yunaCache)).go();
    yuna.ids = [];
    anilist.searchResults = [
      AniListMedia(
          id: 199,
          status: 'FINISHED',
          format: 'TV',
          episodes: 170,
          startDate: DateTime(2017, 10, 3),
          streamingEpisodes: const []),
      AniListMedia(
          id: 200,
          status: 'RELEASING',
          format: 'TV',
          episodes: 12,
          startDate: DateTime(nextWeek.year, nextWeek.month, nextWeek.day),
          streamingEpisodes: const []),
    ];

    final data = await container.readFuture(animeDataProvider(100).future);

    expect(data!.single.anilistId, 200);
    expect(anilist.requestedIds, [
      [200]
    ]);
    expect((await db.animeCacheDao.getFreshAnimeSeasons(100))!.single.anilistId,
        200);
    expect(anilist.searches, ['Anime']);
  });

  test('Da Vedere conta solo elementi visibili usando DB locale offline',
      () async {
    await db.showsDao.deleteShow(showId);
    tmdbOffline = true;
    anilist.offline = true;
    Future<int> insert(int id,
        {String status = 'Returning Series',
        bool future = false,
        bool watched = false}) async {
      final dbId = await db.showsDao.insertShow(TrackedShowsCompanion(
        tmdbId: Value(id),
        title: Value('Serie $id'),
        status: const Value(MediaStatus.watching),
        addedAt: Value(yesterday),
        totalEpisodes: const Value(1),
        totalSeasons: const Value(1),
        tmdbStatus: Value(status),
        nextEpisodeSeason: Value(future ? 1 : null),
        nextEpisodeNumber: Value(future ? 1 : null),
        nextEpisodeAirDate: Value(future ? nextWeek : null),
      ));
      await db.showsDao.insertSeasons(dbId, {1: 1});
      if (watched) await db.showsDao.markEpisodeWatched(dbId, 1, 1);
      return dbId;
    }

    await insert(101); // Nessuna cache: il DB sa che esiste 1x1.
    await insert(102, future: true);
    await insert(103, watched: true); // In pari, ancora in produzione.
    await insert(104, watched: true, status: 'Ended'); // Riepilogo finale.
    await insert(105);
    await db.cacheDao.saveSeasonEpisodes([
      CachedEpisodesCompanion(
        tmdbShowId: const Value(105),
        seasonNumber: const Value(1),
        episodeNumber: const Value(1),
        name: const Value('Futuro'),
        airDate: Value(nextWeek.toIso8601String()),
        cachedAt: Value(yesterday),
      )
    ]);

    final visible =
        await container.readFuture(visibleWatchingShowsProvider.future);

    expect(visible.map((s) => s.show.tmdbId).toSet(), {101, 104});
    expect(visible.length, 2); // Header e lista consumano questo stesso valore.
    expect(tmdbRequests, isEmpty);
    expect(anilist.requests, 0);
    expect(yuna.requests, 0);
  });

  test('Da Vedere usa cour scaduti per distinguere visto e futuro offline',
      () async {
    await saveCache(fresh: true);
    await db.animeCacheDao.expireAnimeCacheForShow(100);
    tmdbOffline = true;
    anilist.offline = true;
    for (var ep = 1; ep <= 8; ep++) {
      await db.showsDao.markEpisodeWatched(showId, 1, ep);
    }

    expect(await container.readFuture(visibleWatchingShowsProvider.future),
        isEmpty);
    await db.showsDao.markEpisodeWatched(showId, 1, 8, watched: false);
    container.invalidate(watchingShowsWithEpisodesProvider);
    container.invalidate(visibleWatchingShowsProvider);
    final visible =
        await container.readFuture(visibleWatchingShowsProvider.future);
    expect(visible.single.watchedCount, 7);
    expect(tmdbRequests, isEmpty);
    expect(anilist.requests, 0);
  });

  test('notifiche anime rispettano orario preciso e cancellazione', () async {
    await saveCache(fresh: true);
    await markWatchedAndRefresh();
    final scheduled =
        notificationCalls.singleWhere((c) => c.method == 'zonedSchedule');
    final args = scheduled.arguments as Map;
    expect(
        DateTime.parse(args['scheduledDateTimeISO8601'] as String)
            .isAtSameMomentAs(nextWeek),
        isTrue);
    expect(args['id'], 100);

    await container
        .read(trackedShowsProvider.notifier)
        .updateStatus(showId, MediaStatus.completed);

    expect(notificationCalls.last.method, 'cancel');
    expect((await db.showsDao.getById(showId))!.status, MediaStatus.completed);
  });

  test('notifica passata ignorata, rischedulazione usa stesso ID e 09:00',
      () async {
    Future<void> schedule(DateTime date) => NotificationService.schedule(
          tmdbId: 100,
          showTitle: 'Serie',
          seasonNumber: 1,
          episodeNumber: 9,
          episodeName: '',
          airDate: date,
        );
    await schedule(yesterday);
    expect(notificationCalls, isEmpty);
    await schedule(nextWeek);
    await schedule(nextWeek.add(const Duration(days: 1)));
    final scheduled =
        notificationCalls.where((c) => c.method == 'zonedSchedule').toList();
    expect(scheduled, hasLength(2));
    for (final call in scheduled) {
      final args = call.arguments as Map;
      expect(args['id'], 100);
      expect(
          DateTime.parse(args['scheduledDateTimeISO8601'] as String)
              .toLocal()
              .hour,
          9);
    }
    await NotificationService.cancel(100);
    expect(notificationCalls.last.method, 'cancel');
  });

  test('syncMetadata aggiorna un cambiamento del solo titolo episodio',
      () async {
    isAnime = false;
    final detail = await container.readFuture(showDetailProvider(100).future);
    final notifier = container.read(trackedShowsProvider.notifier);
    await notifier.syncMetadata(detail, showId);
    await (db.update(db.trackedShows)..where((t) => t.id.equals(showId))).write(
        const TrackedShowsCompanion(nextEpisodeName: Value('Episode 9')));
    final before = (await db.showsDao.getById(showId))!;

    await notifier.syncMetadata(detail, showId);

    final after = (await db.showsDao.getById(showId))!;
    expect(after.nextEpisodeNumber, before.nextEpisodeNumber);
    expect(after.nextEpisodeAirDate, before.nextEpisodeAirDate);
    expect(after.nextEpisodeName, 'Il prossimo episodio');
  });

  test('non aggiorna né riprogramma notifiche per una serie rimossa', () async {
    await db.showsDao.deleteShow(showId);

    await container
        .read(trackedShowsProvider.notifier)
        .rescheduleNotificationById(100);

    expect(await db.showsDao.getAll(), isEmpty);
    expect(notificationCalls, isEmpty);
    expect(anilist.requests, 0);
  });
}
