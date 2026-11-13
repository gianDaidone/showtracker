import 'dart:async';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:showtracker/core/database/app_database.dart';
import 'package:showtracker/features/games/data/rawg_service.dart';
import 'package:showtracker/features/series/data/models/normalized_anime_season.dart';
import 'package:showtracker/features/series/data/tmdb_service.dart';
import 'package:showtracker/features/series/data/watch_next_rules.dart';
import 'package:showtracker/features/sync/services/sync_service.dart';

import '../../support/query_counter.dart';

final _old = DateTime.utc(2000);

NormalizedAnimeSeason _cour(int number, {int count = 12}) =>
    NormalizedAnimeSeason(
      seasonNumber: number,
      tmdbSeasonNumber: 1,
      anilistId: 100 + number,
      episodeCount: count,
      status: 'FINISHED',
      streamingEpisodes: const [],
    );

CachedEpisodesCompanion _episode(int show, int season, int episode) =>
    CachedEpisodesCompanion.insert(
      tmdbShowId: show,
      seasonNumber: season,
      episodeNumber: episode,
      name: 'Titolo non necessario al summary',
      overview: const Value('Trama che il summary non deve caricare'),
      cachedAt: _old,
      airDate: const Value('2000-01-01'),
      airingAt: Value(_old),
    );

Future<int> _show(AppDatabase db, int tmdbId) => db.showsDao.insertShow(
      TrackedShowsCompanion.insert(
        tmdbId: tmdbId,
        title: 'Serie $tmdbId',
        status: MediaStatus.watching,
        addedAt: _old,
        updatedAt: Value(_old),
        isAnime: Value(tmdbId.isEven),
      ),
    );

/// One-shot equivalent of the production watching JOIN. Using get(), not
/// watch().first, leaves Drift's stream cache cold for the measured bulk path.
Future<List<ShowWithWatchedEpisodes>> _watchingSnapshot(AppDatabase db) async {
  final rows = await (db.select(db.trackedShows).join([
    leftOuterJoin(
      db.trackedEpisodes,
      db.trackedEpisodes.showId.equalsExp(db.trackedShows.id) &
          db.trackedEpisodes.watched.equals(true),
    ),
  ])
        ..where(db.trackedShows.status.equalsValue(MediaStatus.watching))
        ..orderBy([OrderingTerm.desc(db.trackedShows.addedAt)]))
      .get();
  final shows = <int, TrackedShow>{};
  final watched = <int, Map<int, Set<int>>>{};
  for (final row in rows) {
    final show = row.readTable(db.trackedShows);
    shows[show.id] = show;
    final ep = row.readTableOrNull(db.trackedEpisodes);
    if (ep != null) {
      watched
          .putIfAbsent(show.id, () => {})
          .putIfAbsent(ep.seasonNumber, () => {})
          .add(ep.episodeNumber);
    }
  }
  return [
    for (final show in shows.values)
      ShowWithWatchedEpisodes(
          show: show, watchedBySeason: watched[show.id] ?? {}),
  ];
}

void main() {
  late AppDatabase db;
  late QueryCounter counter;

  setUp(() async {
    counter = QueryCounter();
    db = AppDatabase.forTesting(NativeDatabase.memory().interceptWith(counter));
    // Schema opening is intentionally excluded from every measured workload.
    await db.customSelect('SELECT 1').get();
    counter.reset();
  });
  tearDown(() => db.close());

  for (final size in [10, 50, 100]) {
    for (final cacheState in ['fresh', 'stale', 'missing']) {
      test('pipeline $size serie, anime $cacheState: quattro SELECT', () async {
        for (var id = 1; id <= size; id++) {
          final localId = await _show(db, id);
          await db.showsDao.insertSeasons(localId, {1: 12});
          await db.cacheDao.saveSeasonEpisodes([_episode(id, 1, 1)]);
          if (id.isEven && cacheState != 'missing') {
            await db.animeCacheDao.saveAnimeSeasons(id, [_cour(1)]);
            if (cacheState == 'stale') {
              await db.animeCacheDao.expireAnimeCacheForShow(id);
            }
          }
        }

        // Original N+1 workload, retained as a deterministic reference only.
        counter.reset();
        final baseline = await _watchingSnapshot(db);
        final baselineCounts = <int, Map<int, int>>{};
        final baselineAnime = <int, List<NormalizedAnimeSeason>?>{};
        final baselineEpisodes = <int, List<CachedEpisode>>{};
        for (final data in baseline) {
          baselineCounts[data.show.id] =
              await db.showsDao.getSeasonCounts(data.show.id);
          if (data.show.isAnime) {
            baselineAnime[data.show.tmdbId] = await db.animeCacheDao
                    .getFreshAnimeSeasons(data.show.tmdbId) ??
                await db.animeCacheDao.getStaleAnimeSeasons(data.show.tmdbId);
          }
          baselineEpisodes[data.show.tmdbId] = await db.cacheDao
              .getSeasonEpisodesIgnoringTtl(data.show.tmdbId, 1);
        }
        final animeCount = size ~/ 2;
        expect(counter.selects,
            1 + 2 * size + animeCount * (cacheState == 'fresh' ? 1 : 2));

        counter.reset();
        final watching =
            await db.showsDao.watchWatchingShowsWithEpisodes().first;
        final counts = await db.showsDao.watchSeasonCounts().first;
        final anime = await db.animeCacheDao.getStaleAnimeSeasonsForShows(
            watching.where((s) => s.show.isAnime).map((s) => s.show.tmdbId));
        final summaries = await db.cacheDao
            .getEpisodeSummaries(watching.map((s) => (s.show.tmdbId, 1, 1)));
        expect(counter.selects, 4);
        expect(counter.selectParameterCounts.every((n) => n <= 900), isTrue);
        for (final data in watching) {
          final tmdbId = data.show.tmdbId;
          expect(counts[data.show.id], baselineCounts[data.show.id]);
          if (data.show.isAnime) {
            expect(anime[tmdbId]!.map((s) => s.toJson()),
                (baselineAnime[tmdbId] ?? []).map((s) => s.toJson()));
          }
          final summary = summaries[(tmdbId, 1, 1)]!;
          expect(summary.hasSeason, baselineEpisodes[tmdbId]!.isNotEmpty);
          expect(airedPerCachedEpisodes(summary.targetEpisodes, 1),
              airedPerCachedEpisodes(baselineEpisodes[tmdbId]!, 1));
        }
      });
    }
  }

  test('summary distingue stagione presente, target assente e date nulle',
      () async {
    await db.cacheDao.saveSeasonEpisodes([
      _episode(1, 1, 1),
      _episode(2, 1, 2).copyWith(
          airDate: const Value('2099-01-01'), airingAt: const Value(null)),
      _episode(3, 1, 2)
          .copyWith(airDate: const Value(null), airingAt: const Value(null)),
    ]);
    final result = await db.cacheDao.getEpisodeSummaries(
        [(1, 1, 2), (2, 1, 2), (3, 1, 2), (4, 1, 2), (1, 1, 2)]);
    expect(result, hasLength(4));
    expect(result[(1, 1, 2)]!.hasSeason, isTrue);
    expect(result[(1, 1, 2)]!.targetEpisodes, isEmpty);
    expect(result[(4, 1, 2)]!.hasSeason, isFalse);
    expect(result[(4, 1, 2)]!.targetEpisodes, isEmpty);
    expect(
        airedPerCachedEpisodes(result[(2, 1, 2)]!.targetEpisodes, 2), isFalse);
    expect(
        airedPerCachedEpisodes(result[(3, 1, 2)]!.targetEpisodes, 2), isFalse);
    // Explicit timestamp wins over the contradictory future calendar date.
    await db.cacheDao.saveSeasonEpisodes([
      _episode(2, 1, 2).copyWith(airDate: const Value('2099-01-01')),
    ]);
    final updated = await db.cacheDao.getEpisodeSummaries([(2, 1, 2)]);
    expect(
        airedPerCachedEpisodes(updated[(2, 1, 2)]!.targetEpisodes, 2), isTrue);
  });

  test('bulk vuoti non interrogano il DB; chunk hanno al massimo 900 parametri',
      () async {
    expect(await db.cacheDao.getEpisodeSummaries([]), isEmpty);
    expect(await db.animeCacheDao.getStaleAnimeSeasonsForShows([]), isEmpty);
    expect(counter.selects, 0);
    final summaries = await db.cacheDao
        .getEpisodeSummaries(List.generate(601, (i) => (i, 1, 1)));
    expect(summaries, hasLength(601));
    expect(counter.selects, 3);
    expect(counter.selectParameterCounts, [900, 900, 3]);
    counter.reset();
    final anime = await db.animeCacheDao
        .getStaleAnimeSeasonsForShows(List.generate(1801, (i) => i));
    expect(anime, hasLength(1801));
    expect(anime.values.every((s) => s.isEmpty), isTrue);
    expect(counter.selects, 3);
    expect(counter.selectParameterCounts, [900, 900, 1]);
  });

  test(
      'bulk anime conserva ordine, intero set parzialmente scaduto e isolamento',
      () async {
    await db.animeCacheDao.saveAnimeSeasons(1, [_cour(2), _cour(1)]);
    await db.animeCacheDao.saveAnimeSeasons(99, [_cour(1)]);
    await (db.update(db.animeSeasonCache)
          ..where((s) => s.tmdbShowId.equals(1) & s.seasonNumber.equals(2)))
        .write(AnimeSeasonCacheCompanion(validUntil: Value(_old)));
    counter.reset();
    final result =
        await db.animeCacheDao.getStaleAnimeSeasonsForShows([1, 2, 1]);
    expect(counter.selects, 1);
    expect(result.keys, [1, 2]);
    expect(result[1]!.map((s) => s.seasonNumber), [1, 2]);
    expect(result[2], isEmpty);
    expect(await db.animeCacheDao.getFreshAnimeSeasons(1), isNull);
  });

  test('stream conteggi emette una mappa condivisa dopo upsert batch',
      () async {
    final id = await _show(db, 1);
    final other = await _show(db, 2);
    final counts = StreamIterator(db.showsDao.watchSeasonCounts());
    addTearDown(counts.cancel);
    expect(await counts.moveNext(), isTrue);
    expect(counts.current, isEmpty);
    final next = counts.moveNext();
    await db.showsDao.insertSeasons(id, {1: 12, 2: 24});
    expect(await next, isTrue);
    expect(counts.current, {
      id: {1: 12, 2: 24}
    });
    final nextOther = counts.moveNext();
    await db.showsDao.insertSeasons(other, {1: 5});
    expect(await nextOther, isTrue);
    expect(counts.current, {
      id: {1: 12, 2: 24},
      other: {1: 5}
    });
  });

  test('100 righe: un dispatch batch per save, non 100 insert executor',
      () async {
    final id = await _show(db, 1);
    counter.reset();
    await db.cacheDao
        .saveSeasonEpisodes(List.generate(100, (i) => _episode(1, 1, i + 1)));
    expect(counter.batchDispatches, 1);
    expect(counter.batchStatements, 100);
    expect(counter.inserts, 0);
    counter.reset();
    await db.showsDao.insertSeasons(id, {for (var n = 1; n <= 100; n++) n: 12});
    expect(counter.batchDispatches, 1);
    expect(counter.batchStatements, 100);
    expect(counter.inserts, 0);
    counter.reset();
    await db.animeCacheDao
        .saveAnimeSeasons(1, List.generate(100, (i) => _cour(i + 1)));
    expect(counter.batchDispatches, 1);
    expect(counter.batchStatements, 100);
    expect(counter.inserts, 0);
  });

  test('season batch e cour cleanup falliti ripristinano tutte le righe',
      () async {
    final id = await _show(db, 1);
    await db.showsDao.insertSeasons(id, {1: 12});
    await db.customStatement('''
      CREATE TRIGGER reject_season BEFORE INSERT ON tracked_seasons
      WHEN NEW.season_number = 2
      BEGIN SELECT RAISE(ABORT, 'rollback'); END
    ''');
    await expectLater(db.showsDao.insertSeasons(id, {1: 20, 2: 12}),
        throwsA(isA<Exception>()));
    expect(await db.showsDao.getSeasonCounts(id), {1: 12});

    await db.animeCacheDao.saveAnimeSeasons(1, [_cour(1), _cour(2)]);
    await db.customStatement('''
      CREATE TRIGGER reject_cleanup BEFORE DELETE ON anime_season_cache
      BEGIN SELECT RAISE(ABORT, 'rollback'); END
    ''');
    await expectLater(
        db.animeCacheDao.saveAnimeSeasons(1, [_cour(1, count: 20)]),
        throwsA(isA<Exception>()));
    final cached = await db.animeCacheDao.getStaleAnimeSeasons(1);
    expect(cached!.map((s) => s.episodeCount), [12, 12]);
  });

  for (final previous in [false, true]) {
    test('show timestamp e progressi rollback atomico (precedenti=$previous)',
        () async {
      final id = await _show(db, 1);
      await db.showsDao.insertSeasons(id, {1: 12});
      await db.customStatement('''
        CREATE TRIGGER reject_episode BEFORE INSERT ON tracked_episodes
        WHEN NEW.episode_number = 2
        BEGIN SELECT RAISE(ABORT, 'rollback'); END
      ''');
      await expectLater(
          previous
              ? db.showsDao.markAllPreviousEpisodesWatched(id, 1, 3)
              : db.showsDao.markEpisodeWatched(id, 1, 2),
          throwsA(isA<Exception>()));
      final show = (await db.showsDao.getById(id))!;
      expect(show.lastWatchedAt, isNull);
      expect(show.updatedAt!.toUtc(), _old);
      expect(await db.showsDao.getEpisodesByShow(id), isEmpty);
    });
  }

  test('join non pubblica show aggiornato senza i progressi corrispondenti',
      () async {
    final id = await _show(db, 1);
    final joined = StreamIterator(db.showsDao.watchWatchingShowsWithEpisodes());
    addTearDown(joined.cancel);
    expect(await joined.moveNext(), isTrue);
    final next = joined.moveNext();
    await db.showsDao.markEpisodeWatched(id, 1, 1);
    expect(await next, isTrue);
    expect(joined.current.single.watchedCount, 1);
    expect(joined.current.single.show.lastWatchedAt, isNotNull);
  });

  for (final size in [0, 10, 50, 100]) {
    test('export $size serie: quattro SELECT e payload invariato', () async {
      for (var id = 1; id <= size; id++) {
        final localId = await _show(db, id);
        await db.batch((b) {
          for (final ep in [1, 2, 4]) {
            b.insert(
                db.trackedEpisodes,
                TrackedEpisodesCompanion.insert(
                  showId: localId,
                  seasonNumber: 1,
                  episodeNumber: ep,
                  watched: Value(ep != 4),
                ));
          }
        });
      }
      await db.moviesDao.insertMovie(TrackedMoviesCompanion.insert(
          tmdbId: 1001,
          title: 'Film',
          status: MediaStatus.completed,
          addedAt: _old));
      await db.gamesDao.insertGame(TrackedGamesCompanion.insert(
          rawgId: 1002,
          title: 'Gioco',
          status: MediaStatus.paused,
          addedAt: _old));
      final client = MockClient((request) async {
        fail('Export locale non deve chiamare HTTP: ${request.url}');
      });
      addTearDown(client.close);
      final service = SyncService(db, db.showsDao, db.gamesDao, db.moviesDao,
          TmdbService(client), RawgService(client));
      counter.reset();
      final exported = await service.exportData();
      expect(counter.selects, 4);
      expect(exported.shows, hasLength(size));
      for (var id = 1; id <= size; id++) {
        final data = exported.shows['$id']!;
        expect(data.eps, {'1': '1-2'});
        expect(data.status, 'watching');
        expect(data.updatedAt, _old.millisecondsSinceEpoch ~/ 1000);
      }
      expect(exported.movies['1001']!.status, 'completed');
      expect(exported.games['1002']!.status, 'paused');
    });
  }
}
