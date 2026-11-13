import 'dart:async';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:showtracker/core/database/app_database.dart';
import 'package:showtracker/core/database/database_provider.dart';
import 'package:showtracker/core/riverpod_utils.dart';
import 'package:showtracker/features/series/data/anilist_service.dart';
import 'package:showtracker/features/series/data/models/normalized_anime_season.dart';
import 'package:showtracker/features/series/data/tmdb_service.dart';
import 'package:showtracker/features/series/data/watch_next_rules.dart';
import 'package:showtracker/features/series/data/yuna_service.dart';
import 'package:showtracker/features/series/providers/series_providers.dart';

import '../../support/query_counter.dart';

final _past = DateTime.utc(2000);
final _future = DateTime.utc(2099);

class _NoNetworkYuna extends YunaService {
  final void Function() onRequest;
  _NoNetworkYuna(this.onRequest);

  @override
  Future<List<int>> getAniListIds(int tmdbId) async {
    onRequest();
    throw StateError('La visibilità non deve richiedere Yuna');
  }
}

NormalizedAnimeSeason _season({int count = 2}) => NormalizedAnimeSeason(
      seasonNumber: 1,
      tmdbSeasonNumber: 1,
      anilistId: 100,
      episodeCount: count,
      status: 'FINISHED',
      streamingEpisodes: const [],
    );

CachedEpisodesCompanion _cached(int show, int episode, DateTime airingAt) =>
    CachedEpisodesCompanion.insert(
      tmdbShowId: show,
      seasonNumber: 1,
      episodeNumber: episode,
      name: 'Episodio $episode',
      cachedAt: _past,
      airingAt: Value(airingAt),
      airDate: Value(airingAt.year == 2000 ? '2000-01-01' : '2099-01-01'),
    );

/// The pre-bulk pipeline is deliberately kept test-only. Its inputs and the
/// complete-season cache existence test are independent of the new summary.
Future<List<int>> _referenceVisibility(AppDatabase db) async {
  final result = <int>[];
  // One-shot reads intentionally avoid watch().first: Drift retains cancelled
  // stream query snapshots until the next event-loop turn. A reference stream
  // would warm the production JOIN and hide a SELECT in the cold measurement.
  for (final show in await db.showsDao.getAll()) {
    if (show.status != MediaStatus.watching) continue;
    final watchedBySeason = <int, Set<int>>{};
    for (final episode in await db.showsDao.getEpisodesByShow(show.id)) {
      if (episode.watched) {
        watchedBySeason
            .putIfAbsent(episode.seasonNumber, () => {})
            .add(episode.episodeNumber);
      }
    }
    final data =
        ShowWithWatchedEpisodes(show: show, watchedBySeason: watchedBySeason);
    final counts = await db.showsDao.getSeasonCounts(show.id);
    final anime = show.isAnime
        ? await db.animeCacheDao.getFreshAnimeSeasons(show.tmdbId) ??
            await db.animeCacheDao.getStaleAnimeSeasons(show.tmdbId)
        : null;
    final (season, episode) = computeNextToWatch(data.watchedBySeason, counts,
        animeSeasonsData: anime);
    final cached =
        await db.cacheDao.getSeasonEpisodesIgnoringTtl(show.tmdbId, season);
    final aired = resolveHasAired(
      show: show,
      dbSeasonCounts: counts,
      season: season,
      episode: episode,
      animeSeasonsData: anime,
      airedPerTmdb: airedPerCachedEpisodes(cached, episode),
    );
    final lastSeason = data.watchedBySeason.keys.isEmpty
        ? 0
        : data.watchedBySeason.keys.reduce((a, b) => a > b ? a : b);
    final completed = anime != null
        ? cached.isEmpty && !hasLaterUpcomingAnimeSeason(anime, lastSeason)
        : show.totalEpisodes != null &&
            data.watchedCount >= show.totalEpisodes!;
    if (completed && !aired) {
      if (show.tmdbStatus == 'Ended' || show.tmdbStatus == 'Canceled') {
        result.add(show.tmdbId);
      }
    } else if (aired) {
      result.add(show.tmdbId);
    }
  }
  return result;
}

Future<List<ShowWithWatchedEpisodes>> _waitForVisibility(
  ProviderContainer container,
  bool Function(List<ShowWithWatchedEpisodes>) matches,
) async {
  final ready = Completer<List<ShowWithWatchedEpisodes>>();
  final sub = container.listen(visibleWatchingShowsProvider, (_, next) {
    if (ready.isCompleted) return;
    if (next.hasError) {
      ready.completeError(next.error!, next.stackTrace);
    } else if (!next.isLoading && next.value != null && matches(next.value!)) {
      ready.complete(next.value!);
    }
  }, fireImmediately: true);
  try {
    return await ready.future.timeout(const Duration(seconds: 5));
  } finally {
    sub.close();
  }
}

void main() {
  late AppDatabase db;
  late QueryCounter counter;
  late ProviderContainer container;
  late http.Client client;
  late AniListService anilist;
  late int requests;

  setUp(() async {
    counter = QueryCounter();
    db = AppDatabase.forTesting(NativeDatabase.memory().interceptWith(counter));
    await db.customSelect('SELECT 1').get();
    requests = 0;
    client = MockClient((request) async {
      requests++;
      throw http.ClientException('Nessuna rete per la visibilità', request.url);
    });
    anilist = AniListService(client: client);
    container = ProviderContainer(retry: noProviderRetry, overrides: [
      databaseProvider.overrideWithValue(db),
      tmdbServiceProvider.overrideWithValue(TmdbService(client)),
      anilistServiceProvider.overrideWithValue(anilist),
      yunaServiceProvider.overrideWithValue(_NoNetworkYuna(() => requests++)),
    ]);
  });

  tearDown(() async {
    container.dispose();
    anilist.dispose();
    client.close();
    await db.close();
  });

  for (final size in [10, 50, 100]) {
    test('provider cold $size serie miste: stessa visibilità, quattro SELECT',
        () async {
      for (var id = 1; id <= size; id++) {
        final anime = id.isEven;
        final localId =
            await db.showsDao.insertShow(TrackedShowsCompanion.insert(
          tmdbId: id,
          title: 'Serie $id',
          status: MediaStatus.watching,
          addedAt: _past.add(Duration(days: id)),
          isAnime: Value(anime),
          totalEpisodes: const Value(2),
          tmdbStatus: Value(id % 5 == 0 ? 'Ended' : 'Returning Series'),
          nextEpisodeSeason: const Value(1),
          nextEpisodeNumber: const Value(2),
          nextEpisodeAirDate: Value(id % 4 == 0 ? _future : _past),
        ));
        await db.showsDao.insertSeasons(localId, {1: 2});
        await db
            .into(db.trackedEpisodes)
            .insert(TrackedEpisodesCompanion.insert(
              showId: localId,
              seasonNumber: 1,
              episodeNumber: 1,
              watched: const Value(true),
            ));
        // Fresh, stale and missing anime caches coexist in each workload.
        if (anime && id % 3 != 0) {
          await db.animeCacheDao.saveAnimeSeasons(id, [_season()]);
          if (id % 3 == 1) await db.animeCacheDao.expireAnimeCacheForShow(id);
        }
        // Both target-present and season-present/target-missing are exercised;
        // complete cache absence uses only the denormalized DB fallback.
        if (id % 4 != 3) {
          await db.cacheDao.saveSeasonEpisodes([
            _cached(id, id % 4 == 2 ? 1 : 2, id % 4 == 0 ? _future : _past),
          ]);
        }
      }
      final expected = await _referenceVisibility(db);
      counter.reset();
      final visible =
          await container.readFuture(visibleWatchingShowsProvider.future);
      expect(visible.map((s) => s.show.tmdbId), expected);
      expect(counter.selects, 4);
      expect(counter.selectParameterCounts.every((n) => n <= 900), isTrue);
      expect(requests, 0);
    });
  }

  test('modifiche della sola cache episodi aggiornano la visibilità', () async {
    final id = await db.showsDao.insertShow(TrackedShowsCompanion.insert(
      tmdbId: 10,
      title: 'Serie',
      status: MediaStatus.watching,
      addedAt: _past,
      nextEpisodeSeason: const Value(1),
      nextEpisodeNumber: const Value(1),
      nextEpisodeAirDate: Value(_future),
    ));
    await db.showsDao.insertSeasons(id, {1: 1});
    final keepAlive =
        container.listen(visibleWatchingShowsProvider, (_, __) {});
    addTearDown(keepAlive.close);
    expect(await container.read(visibleWatchingShowsProvider.future), isEmpty);
    final showBefore = await db.showsDao.getById(id);
    final visible = _waitForVisibility(container, (list) => list.length == 1);
    await db.cacheDao.saveSeasonEpisodes([_cached(10, 1, _past)]);
    expect((await visible).single.show.tmdbId, 10);
    final hidden = _waitForVisibility(container, (list) => list.isEmpty);
    await db.cacheDao.saveSeasonEpisodes([_cached(10, 1, _future)]);
    expect(await hidden, isEmpty);
    expect(await db.showsDao.getById(id), showBefore);
    expect(requests, 0);
  });

  test('stagione in cache senza target non rende completato un anime terminato',
      () async {
    final id = await db.showsDao.insertShow(TrackedShowsCompanion.insert(
      tmdbId: 20,
      title: 'Anime',
      status: MediaStatus.watching,
      addedAt: _past,
      isAnime: const Value(true),
      totalEpisodes: const Value(1),
      tmdbStatus: const Value('Ended'),
    ));
    await db.showsDao.insertSeasons(id, {1: 1});
    await db.showsDao.markEpisodeWatched(id, 1, 1);
    await db.animeCacheDao.saveAnimeSeasons(20, [_season(count: 1)]);
    await db.animeCacheDao.expireAnimeCacheForShow(20);
    await db.cacheDao.saveSeasonEpisodes([_cached(20, 1, _past)]);
    final keepAlive =
        container.listen(visibleWatchingShowsProvider, (_, __) {});
    addTearDown(keepAlive.close);
    // Next target 1x2 is absent, but 1x1 proves the season cache exists.
    expect(await container.read(visibleWatchingShowsProvider.future), isEmpty);
    expect(await _referenceVisibility(db), isEmpty);
    final completed = _waitForVisibility(container, (list) => list.length == 1);
    await db.cacheDao.clearCacheForShow(20);
    expect((await completed).single.show.tmdbId, 20);
    expect(await _referenceVisibility(db), [20]);
    expect(requests, 0);
  });

  test('refresh della sola cache anime rivaluta la numerazione cour', () async {
    final id = await db.showsDao.insertShow(TrackedShowsCompanion.insert(
      tmdbId: 30,
      title: 'Anime',
      status: MediaStatus.watching,
      addedAt: _past,
      isAnime: const Value(true),
    ));
    await db.showsDao.insertSeasons(id, {1: 0});
    final keepAlive =
        container.listen(visibleWatchingShowsProvider, (_, __) {});
    addTearDown(keepAlive.close);
    expect(await container.read(visibleWatchingShowsProvider.future), isEmpty);
    final visible = _waitForVisibility(container, (list) => list.length == 1);
    await db.animeCacheDao.saveAnimeSeasons(30, [_season(count: 1)]);
    expect((await visible).single.show.tmdbId, 30);
    expect(requests, 0);
  });
}
