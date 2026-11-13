import 'dart:async';
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
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
import 'package:showtracker/features/series/providers/series_providers.dart';

class _AniList extends AniListService {
  @override
  Future<List<AniListMedia>> fetchBatch(List<int> ids) async => [
        const AniListMedia(
            id: 200,
            status: 'FINISHED',
            format: 'TV',
            episodes: 2,
            streamingEpisodes: []),
      ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  late ProviderContainer container;
  late http.Client client;
  late _AniList anilist;
  late List<Uri> requests;
  late Completer<void> gate;
  late Completer<void> entered;
  var gateEnabled = false;
  var anime = false;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.customSelect('SELECT 1').get();
    requests = [];
    gate = Completer<void>();
    entered = Completer<void>();
    anime = false;
    gateEnabled = false;
    client = MockClient((request) async {
      requests.add(request.url);
      if (gateEnabled) {
        if (!entered.isCompleted) entered.complete();
        await gate.future;
      }
      if (request.url.path.contains('/season/')) {
        return http.Response(
            jsonEncode({
              'season_number': 1,
              'episodes': [
                for (var i = 1; i <= 4; i++)
                  {
                    'episode_number': i,
                    'name': 'Episodio $i',
                    'air_date': '2000-01-01'
                  }
              ],
            }),
            200);
      }
      return http.Response(
          jsonEncode({
            'id': 100,
            'name': 'Serie',
            'in_production': false,
            'status': 'Ended',
            'number_of_seasons': 1,
            'number_of_episodes': 4,
            'genres': [
              {'name': anime ? 'Animation' : 'Drama'}
            ],
            'origin_country': [anime ? 'JP' : 'US'],
            'seasons': [
              {'season_number': 1, 'episode_count': 4, 'air_date': '2000-01-01'}
            ],
          }),
          200);
    });
    anilist = _AniList();
    container = ProviderContainer(retry: noProviderRetry, overrides: [
      databaseProvider.overrideWithValue(db),
      tmdbServiceProvider.overrideWithValue(TmdbService(client)),
      anilistServiceProvider.overrideWithValue(anilist),
    ]);
  });
  tearDown(() async {
    container.dispose();
    anilist.dispose();
    await db.close();
    client.close();
  });

  test('due worker concorrenti condividono una scansione; il prossimo riparte',
      () async {
    await db.showsDao.insertShow(TrackedShowsCompanion(
      tmdbId: const Value(100),
      title: const Value('Serie'),
      status: const Value(MediaStatus.watching),
      addedAt: Value(DateTime.now()),
    ));
    gateEnabled = true;
    final notifier = container.read(trackedShowsProvider.notifier);
    final first = notifier.rescheduleAllNotifications();
    final second = notifier.rescheduleAllNotifications();
    expect(identical(first, second), isTrue);
    await entered.future;
    expect(requests.length, 2); // Solo una coppia it/en, anche con due worker.
    gate.complete();
    await Future.wait([first, second]);
    container.invalidate(rawShowDetailProvider(100));
    await notifier.rescheduleAllNotifications();
    expect(requests.length, 4);
  });

  test('merge anime riusa la coppia di richieste dettaglio esterna', () async {
    anime = true;
    await db.animeCacheDao.saveYunaIds(100, [200]);
    final detail = await container.readFuture(showDetailProvider(100).future);
    expect(detail.animeSeasonsData, isNotEmpty);
    expect(requests.where((u) => u.path == '/3/tv/100').length, 2);
  });

  test(
      'due cour concorrenti condividono fetch e salvataggio della redistribuzione',
      () async {
    anime = true;
    await db.animeCacheDao.saveAnimeSeasons(100, [
      for (var s = 1; s <= 2; s++)
        NormalizedAnimeSeason(
            seasonNumber: s,
            tmdbSeasonNumber: 1,
            anilistId: 199 + s,
            episodeCount: 2,
            status: 'FINISHED',
            streamingEpisodes: const []),
    ]);
    gateEnabled = true;
    final first = container
        .readFuture(seasonDetailProvider(showId: 100, seasonNumber: 1).future);
    final second = container
        .readFuture(seasonDetailProvider(showId: 100, seasonNumber: 2).future);
    await entered.future;
    gate.complete();
    final results = await Future.wait([first, second]);
    expect(results.map((s) => s.episodes!.length), [2, 2]);
    expect(requests.where((u) => u.path == '/3/tv/100/season/1').length, 2);
    expect((await db.cacheDao.getSeasonEpisodesIgnoringTtl(100, 1)).length, 2);
    expect((await db.cacheDao.getSeasonEpisodesIgnoringTtl(100, 2)).length, 2);
  });

  test('modifica dei soli conteggi riaggiorna Da Vedere senza query remote',
      () async {
    final id = await db.showsDao.insertShow(TrackedShowsCompanion(
      tmdbId: const Value(100),
      title: const Value('Serie'),
      status: const Value(MediaStatus.watching),
      addedAt: Value(DateTime.now()),
    ));
    final visible = Completer<void>();
    final sub = container.listen(visibleWatchingShowsProvider, (_, next) {
      if (next.value?.isNotEmpty == true && !visible.isCompleted) {
        visible.complete();
      }
    });
    addTearDown(sub.close);
    expect(await container.read(visibleWatchingShowsProvider.future), isEmpty);
    await db.showsDao.insertSeasons(id, {1: 4});
    await visible.future;
    expect(
        container.read(visibleWatchingShowsProvider).value!.single.show.id, id);
    expect(requests, isEmpty);
  });
}
