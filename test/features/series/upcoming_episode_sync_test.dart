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
import 'package:showtracker/features/series/data/tmdb_service.dart';
import 'package:showtracker/features/series/data/yuna_service.dart';
import 'package:showtracker/features/series/providers/series_providers.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class _AniList implements AniListService {
  late AniListMedia media;
  int requests = 0;
  bool offline = false;

  @override
  Future<List<AniListMedia>> fetchBatch(List<int> ids) async {
    requests++;
    if (offline) throw StateError('AniList offline');
    return [media];
  }

  @override
  Future<AniListMedia?> fetchById(int id) async =>
      (await fetchBatch([id])).firstOrNull;

  @override
  Future<List<AniListMedia>> searchByTitle(String title) async =>
      throw StateError('Ricerca inattesa: $title');

  @override
  void dispose() {}
}

class _Yuna implements YunaService {
  @override
  Future<List<int>> getAniListIds(int tmdbId) async => [200];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dexterous.com/flutter/local_notifications');
  late AppDatabase db;
  late ProviderContainer container;
  late _AniList anilist;
  late http.Client client;
  late int showId;
  late DateTime yesterday;
  late DateTime nextWeek;
  late List<MethodCall> notificationCalls;
  bool tmdbOffline = false;
  bool notificationFails = false;
  bool isAnime = true;

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
    notificationCalls = [];
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
      if (tmdbOffline) throw StateError('TMDB offline');
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
              'episode_number': 9,
              'name': 'Il prossimo episodio',
              'air_date': nextWeek.toIso8601String().split('T').first,
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
        yunaServiceProvider.overrideWithValue(_Yuna()),
      ],
    );
  });

  tearDown(() async {
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

  test('errore notifica non impedisce di salvare Y', () async {
    await saveCache(fresh: true);
    notificationFails = true;

    await markWatchedAndRefresh();

    expect((await db.showsDao.getById(showId))!.nextEpisodeNumber, 9);
    expect(
        (await container.readFuture(upcomingEpisodesProvider.future))
            .single
            .episode
            .episodeNumber,
        9);
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
