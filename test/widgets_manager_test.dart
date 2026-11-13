import 'dart:async';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:showtracker/core/auth/auth_state.dart';
import 'package:showtracker/core/database/app_database.dart';
import 'package:showtracker/core/database/database_provider.dart';
import 'package:showtracker/core/riverpod_utils.dart';
import 'package:showtracker/features/series/data/models/normalized_anime_season.dart';
import 'package:showtracker/features/series/data/models/tmdb_episode.dart';
import 'package:showtracker/features/series/data/models/tmdb_season.dart';
import 'package:showtracker/features/series/data/models/tmdb_show_detail.dart';
import 'package:showtracker/features/series/providers/series_providers.dart';
import 'package:showtracker/widgets_manager.dart';

TrackedShow _show({
  String title = 'Serie locale',
  bool anime = false,
  int total = 12,
  String? poster,
}) =>
    TrackedShow(
      id: 1,
      tmdbId: 42,
      title: title,
      isAnime: anime,
      totalEpisodes: total,
      status: MediaStatus.watching,
      addedAt: DateTime(2026),
      posterPath: poster,
    );

UpcomingEpisodeInfo _upcoming(String title, {String? poster}) =>
    UpcomingEpisodeInfo(
      show: _show(title: title, poster: poster),
      episode: const TmdbNextEpisode(
        seasonNumber: 1,
        episodeNumber: 3,
        name: 'Prossimo',
      ),
      airDate: DateTime.now().add(const Duration(days: 7)),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('home_widget');
  late AppDatabase db;
  late ProviderContainer container;
  late List<MethodCall> calls;
  late Map<String, Object?> saved;
  late List<ShowWithWatchedEpisodes> watching;
  late List<UpcomingEpisodeInfo> upcoming;
  late Map<int, int> counts;
  late AuthState auth;
  late Future<TmdbSeason> Function(int) loadSeason;
  late Future<Object?> Function(MethodCall)? onCall;
  late List<int> requestedSeasons;
  var visibilityReads = 0;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.customSelect('SELECT 1').get();
    calls = [];
    saved = {};
    watching = [];
    upcoming = [];
    counts = {1: 12};
    auth = const AuthenticatedWithManualKey('test-only');
    requestedSeasons = [];
    onCall = null;
    visibilityReads = 0;
    loadSeason = (_) async => throw StateError('offline');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      if (call.method == 'saveWidgetData') {
        final args = call.arguments as Map;
        saved[args['id'] as String] = args['data'];
      }
      if (onCall != null) return onCall!(call);
      return true;
    });
    container = ProviderContainer(
      retry: noProviderRetry,
      overrides: [
        databaseProvider.overrideWithValue(db),
        authControllerProvider.overrideWithBuild((ref, notifier) async => auth),
        visibleWatchingShowsProvider.overrideWith((ref) async {
          visibilityReads++;
          return watching;
        }),
        upcomingEpisodesProvider.overrideWith((ref) async => upcoming),
        seasonEpisodeCountsProvider(1).overrideWith((ref) async => counts),
        for (final season in [1, 2, 3, 4, 5])
          seasonDetailProvider(showId: 42, seasonNumber: season)
              .overrideWith((ref) {
            requestedSeasons.add(season);
            return loadSeason(season);
          }),
      ],
    );
    await container.readFuture(authControllerProvider.future);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  int updates() => calls.where((c) => c.method == 'updateWidget').length;

  test('synchronous burst prepares once and explicitly clears empty slots',
      () async {
    await Future.wait([
      ShowTrackerWidgetsManager.updateWidgets(container: container),
      ShowTrackerWidgetsManager.updateWidgets(container: container),
      ShowTrackerWidgetsManager.updateWidgets(container: container),
    ]);
    expect(visibilityReads, 1);
    expect(updates(), 2);
    expect(saved['marathon_title'], 'Tutto in pari!');
    expect(saved['marathon_mark_uri'], '');
    expect(saved['marathon_image'], '');
    expect(saved['upcoming_1_title'], 'Nessuna uscita');
    expect(saved['upcoming_1_image'], '');
    expect(saved['upcoming_2_image'], '');
    expect(calls.length, 19); // 17 data writes + 2 redraws.
  });

  test('a request while publishing drains the latest provider state', () async {
    upcoming = [_upcoming('Prima')];
    final started = Completer<void>();
    final release = Completer<void>();
    onCall = (call) async {
      if (!started.isCompleted && call.method == 'saveWidgetData') {
        started.complete();
        await release.future;
      }
      return true;
    };
    final first = ShowTrackerWidgetsManager.updateWidgets(container: container);
    await started.future;
    upcoming = [_upcoming('Ultima')];
    container.invalidate(upcomingEpisodesProvider);
    final second =
        ShowTrackerWidgetsManager.updateWidgets(container: container);
    final third = ShowTrackerWidgetsManager.updateWidgets(container: container);
    release.complete();
    await Future.wait([first, second, third]);
    expect(saved['upcoming_1_title'], 'Ultima');
    expect(updates(), 4);
    final titles = calls
        .where((c) => c.method == 'saveWidgetData')
        .map((c) => c.arguments as Map)
        .where((a) => a['id'] == 'upcoming_1_title')
        .map((a) => a['data']);
    expect(titles, ['Prima', 'Ultima']);
  });

  test('unchanged trailing publication is skipped, independent flush is not',
      () async {
    final started = Completer<void>();
    final release = Completer<void>();
    onCall = (call) async {
      if (!started.isCompleted) {
        started.complete();
        await release.future;
      }
      return true;
    };
    final first = ShowTrackerWidgetsManager.updateWidgets(container: container);
    await started.future;
    final trailing =
        ShowTrackerWidgetsManager.updateWidgets(container: container);
    release.complete();
    await Future.wait([first, trailing]);
    expect(updates(), 2);
    await ShowTrackerWidgetsManager.updateWidgets(container: container);
    // Another isolate might have changed the preferences between drains.
    expect(updates(), 4);
  });

  test('save rejection does not poison serialization and next flush retries',
      () async {
    onCall = (_) async => false;
    await expectLater(
      ShowTrackerWidgetsManager.updateWidgets(container: container),
      throwsStateError,
    );
    onCall = null;
    await ShowTrackerWidgetsManager.updateWidgets(container: container);
    expect(updates(), 2);
    expect(saved['upcoming_2_image'], '');
  });

  test('redraw exception retries a full snapshot on the next flush', () async {
    onCall = (call) async {
      if (call.method == 'updateWidget') throw PlatformException(code: 'retry');
      return true;
    };
    await expectLater(
      ShowTrackerWidgetsManager.updateWidgets(container: container),
      throwsA(isA<PlatformException>()),
    );
    calls.clear();
    onCall = null;
    await ShowTrackerWidgetsManager.updateWidgets(container: container);
    expect(calls.length, 19);
    expect(updates(), 2);
  });

  test('offline fallback uses shared progress rules, not first unwatched gap',
      () async {
    watching = [
      ShowWithWatchedEpisodes(
        show: _show(),
        watchedBySeason: const {
          1: {1, 3}
        },
      )
    ];
    await ShowTrackerWidgetsManager.updateWidgets(
      container: container,
      watchingList: const [], // Compatibility parameter is deliberately ignored.
    );
    expect(requestedSeasons, [1]);
    expect(saved['marathon_title'], 'Serie locale');
    expect(
        saved['marathon_mark_uri'], 'homeWidget://mark_watched?id=1&s=1&e=4');
    expect(saved['marathon_image'], '');
  });

  test('completion summaries never become mark-watched actions', () async {
    counts = {1: 2};
    watching = [
      ShowWithWatchedEpisodes(
        show: _show(total: 2).copyWith(tmdbStatus: const Value('Ended')),
        watchedBySeason: const {
          1: {1, 2}
        },
      )
    ];
    await ShowTrackerWidgetsManager.updateWidgets(container: container);
    expect(saved['marathon_title'], 'Tutto in pari!');
    expect(saved['marathon_mark_uri'], '');
    expect(requestedSeasons, isEmpty);
  });

  test('stale anime cache selects synthetic cour through season provider',
      () async {
    counts = {1: 1, 2: 1, 3: 1, 4: 1, 5: 12};
    watching = [
      ShowWithWatchedEpisodes(
        show: _show(anime: true, total: 4),
        watchedBySeason: const {
          1: {1},
          2: {1},
          3: {1},
          4: {1}
        },
      )
    ];
    // Normalized cache saves contain the complete contiguous cour set: saving
    // only cour 5 would trigger obsolete-cour cleanup (> seasons.length).
    await db.animeCacheDao.saveAnimeSeasons(42, [
      for (var season = 1; season <= 5; season++)
        NormalizedAnimeSeason(
          seasonNumber: season,
          tmdbSeasonNumber: season == 5 ? 2 : 1,
          anilistId: 195 + season,
          episodeCount: season == 5 ? 12 : 1,
          status: 'FINISHED',
          streamingEpisodes: const [],
        ),
    ]);
    await db.animeCacheDao.expireAnimeCacheForShow(42);
    expect(await db.animeCacheDao.getFreshAnimeSeasons(42), isNull);
    expect(
      (await db.animeCacheDao.getStaleAnimeSeasons(42))!
          .map((season) => season.seasonNumber),
      [1, 2, 3, 4, 5],
    );
    loadSeason = (season) async => TmdbSeason(
          seasonNumber: season,
          episodeCount: 12,
          name: 'Stagione 2 Parte 2',
          episodes: const [
            TmdbEpisode(
              episodeNumber: 1,
              name: 'Cour finale',
              airDate: '2020-01-01',
            )
          ],
        );
    await ShowTrackerWidgetsManager.updateWidgets(container: container);
    expect(requestedSeasons, [5]);
    expect(saved['marathon_episode_title'], 'S02 P2 E01');
    expect(
        saved['marathon_mark_uri'], 'homeWidget://mark_watched?id=1&s=5&e=1');
  });

  test('cached future episode excludes action without remote enrichment',
      () async {
    watching = [
      ShowWithWatchedEpisodes(
        show: _show(),
        watchedBySeason: const {},
      )
    ];
    await db.cacheDao.saveSeasonEpisodes([
      CachedEpisodesCompanion.insert(
        tmdbShowId: 42,
        seasonNumber: 1,
        episodeNumber: 1,
        name: 'Futuro',
        airDate: Value(
            DateTime.now().add(const Duration(days: 30)).toIso8601String()),
        cachedAt: DateTime.now(),
      ),
    ]);
    await ShowTrackerWidgetsManager.updateWidgets(container: container);
    expect(saved['marathon_mark_uri'], '');
    expect(requestedSeasons, isEmpty);
  });

  test('unauthenticated refresh still renders local progress without API calls',
      () async {
    auth = const Unauthenticated();
    container.invalidate(authControllerProvider);
    await container.readFuture(authControllerProvider.future);
    watching = [
      ShowWithWatchedEpisodes(
        show: _show(),
        watchedBySeason: const {},
      )
    ];
    await ShowTrackerWidgetsManager.updateWidgets(container: container);
    expect(
        saved['marathon_mark_uri'], 'homeWidget://mark_watched?id=1&s=1&e=1');
    expect(requestedSeasons, isEmpty);
  });

  test('missing image clears the previous native image value', () async {
    saved['marathon_image'] = '/old-show.jpg';
    saved['upcoming_1_image'] = '/old-upcoming.jpg';
    watching = [
      ShowWithWatchedEpisodes(
        show: _show(),
        watchedBySeason: const {},
      )
    ];
    upcoming = [_upcoming('Senza immagine')];
    await ShowTrackerWidgetsManager.updateWidgets(container: container);
    expect(saved['marathon_image'], '');
    expect(saved['upcoming_1_image'], '');
  });

  test(
      'native writes from different containers do not interleave in this isolate',
      () async {
    final other = ProviderContainer(retry: noProviderRetry, overrides: [
      visibleWatchingShowsProvider.overrideWith((ref) async => []),
      upcomingEpisodesProvider
          .overrideWith((ref) async => [_upcoming('Altro')]),
    ]);
    addTearDown(other.dispose);
    final started = Completer<void>();
    final release = Completer<void>();
    onCall = (call) async {
      if (!started.isCompleted) {
        started.complete();
        await release.future;
      }
      return true;
    };
    final first = ShowTrackerWidgetsManager.updateWidgets(container: container);
    await started.future;
    final second = ShowTrackerWidgetsManager.updateWidgets(container: other);
    release.complete();
    await Future.wait([first, second]);
    expect(calls.length, 38);
    expect(calls[17].method, 'updateWidget');
    expect(calls[18].method, 'updateWidget');
    expect(calls[19].method, 'saveWidgetData');
    expect(saved['upcoming_1_title'], 'Altro');
  });
}
