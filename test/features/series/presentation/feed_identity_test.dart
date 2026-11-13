import 'package:drift/drift.dart' hide isNull;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:showtracker/core/database/app_database.dart';
import 'package:showtracker/features/series/data/models/tmdb_episode.dart';
import 'package:showtracker/features/series/data/models/tmdb_season.dart';
import 'package:showtracker/features/series/data/models/tmdb_show_detail.dart';
import 'package:showtracker/features/series/presentation/widgets/next_episode_card.dart';
import 'package:showtracker/features/series/providers/series_providers.dart';

import '../../../support/app_test_harness.dart';

const _tmdbIds = [101, 102, 103];

void main() {
  const scenarios = [
    _Scenario(
      'rimuovere la prima card conserva le altre in Da Vedere',
      initialHeaders: ['Da Vedere (3)'],
      finalHeaders: ['Da Vedere (2)'],
    ),
    _Scenario(
      'rimozione con provider stagione reale e cache SQLite conserva le altre',
      realSeasonProvider: true,
      initialHeaders: ['Da Vedere (3)'],
      finalHeaders: ['Da Vedere (2)'],
    ),
    _Scenario(
      'avanzare nella stessa stagione non ricarica le altre card',
      firstEpisodeCount: 2,
      initialHeaders: ['Da Vedere (3)'],
      finalHeaders: ['Da Vedere (3)'],
    ),
    _Scenario(
      'migrazione dalla sezione inattivi conserva le card superstiti',
      firstEpisodeCount: 2,
      firstOld: true,
      othersOld: true,
      initialHeaders: ['Non visti da tempo (3)'],
      finalHeaders: ['Da Vedere (1)', 'Non visti da tempo (2)'],
    ),
    _Scenario(
      'scomparsa della prima sezione conserva Non visti da tempo',
      othersOld: true,
      initialHeaders: ['Da Vedere (1)', 'Non visti da tempo (2)'],
      finalHeaders: ['Non visti da tempo (2)'],
    ),
  ];

  for (final scenario in scenarios) {
    testWidgets(scenario.name, (tester) async {
      // Mount every card, not merely the sliver's off-screen cache entries.
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1000, 2400);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      final fixture = _FeedFixture(scenario);
      final app = (await tester.runAsync(fixture.create))!;
      addTearDown(() => app.dispose(tester));
      await app.pump(tester);

      expect(find.byType(NextEpisodeCard), findsNWidgets(3));
      expect(find.byType(NextEpisodeSkeletonCard), findsNothing);
      for (final header in scenario.initialHeaders) {
        expect(find.text(header), findsOneWidget);
      }
      for (final tmdbId in _tmdbIds) {
        final card = fixture.card(tmdbId);
        expect(card.hitTestable(), findsOneWidget);
        expect(
            find.descendant(
                of: card, matching: find.text(_episodeName(tmdbId, 1))),
            findsOneWidget);
        if (!scenario.realSeasonProvider) {
          expect(fixture.seasonBuilds[tmdbId], 1);
        }
        expect(fixture.detailBuilds[tmdbId], 1);
        expect(fixture.seasonDisposals[tmdbId] ?? 0, 0);
        expect(fixture.detailDisposals[tmdbId] ?? 0, 0);
      }

      // These are observations of the real mounted consumers. In particular,
      // do not listen to (or keepAlive) the metadata providers from the test:
      // doing so would conceal an autoDispose/recreation regression.
      final preservedIds = scenario.removesFirst || scenario.firstOld
          ? _tmdbIds.skip(1)
          : _tmdbIds;
      final identities = {
        for (final tmdbId in preservedIds)
          tmdbId: _CardIdentity(
            tester.element(fixture.card(tmdbId)),
            tester.state<State<StatefulWidget>>(fixture.card(tmdbId)),
          ),
      };
      final seasonBuildsBefore = Map<int, int>.of(fixture.seasonBuilds);
      final detailBuildsBefore = Map<int, int>.of(fixture.detailBuilds);

      void expectPreserved(String frame) {
        final diagnostics = '$frame; season builds=${fixture.seasonBuilds}, '
            'season disposals=${fixture.seasonDisposals}, '
            'detail builds=${fixture.detailBuilds}, '
            'detail disposals=${fixture.detailDisposals}';
        // Also catches a whole-list skeleton replacing every card, rather than
        // only a skeleton rendered below an existing NextEpisodeCard element.
        expect(find.byType(NextEpisodeSkeletonCard), findsNothing,
            reason: diagnostics);
        for (final entry in identities.entries) {
          final tmdbId = entry.key;
          final card = fixture.card(tmdbId);
          expect(card, findsOneWidget, reason: diagnostics);
          expect(tester.element(card), same(entry.value.element),
              reason: 'Element della serie $tmdbId cambiato: $diagnostics');
          expect(tester.state<State<StatefulWidget>>(card),
              same(entry.value.state),
              reason: 'State della serie $tmdbId cambiato: $diagnostics');
          expect(fixture.seasonBuilds[tmdbId], seasonBuildsBefore[tmdbId],
              reason: diagnostics);
          expect(fixture.detailBuilds[tmdbId], detailBuildsBefore[tmdbId],
              reason: diagnostics);
          expect(fixture.seasonDisposals[tmdbId] ?? 0, 0, reason: diagnostics);
          expect(fixture.detailDisposals[tmdbId] ?? 0, 0, reason: diagnostics);
        }
      }

      await tester.tap(find.descendant(
        of: fixture.card(_tmdbIds.first),
        matching: find.byIcon(Icons.check),
      ));
      expectPreserved('tap, prima del primo frame');
      await tester.pump(const Duration(milliseconds: 200));
      expectPreserved('animazione a 200 ms');
      await tester.pump(const Duration(milliseconds: 699));
      expectPreserved('prima della scrittura, a 899 ms');
      // Match the real SQLite/fake-clock boundary used by the existing feed
      // test. The final millisecond starts the watched transaction in runAsync.
      await tester.runAsync(() => tester.pump(const Duration(milliseconds: 1)));
      expectPreserved('scadenza del timer a 900 ms');

      // No flush/pumpAndSettle after tapping: inspect EVERY produced frame,
      // including loading/reload and deferred autoDispose frames. SQL barriers
      // let the real DAO streams progress without adding metadata listeners.
      for (var frame = 0; frame < 16; frame++) {
        await tester.runAsync(() async {
          await app.db.customSelect('SELECT 1').get();
          await Future<void>.delayed(Duration.zero);
        });
        expectPreserved('completamenti DB prima del frame $frame');
        await tester.pump(const Duration(milliseconds: 100));
        expectPreserved('frame $frame dopo la scrittura');
      }

      final watched = (await tester.runAsync(() =>
          app.db.showsDao.getEpisodesByShow(fixture.dbIds[_tmdbIds.first]!)))!;
      expect(
        watched
            .where((episode) => episode.watched)
            .map((episode) => (episode.seasonNumber, episode.episodeNumber)),
        [(1, 1)],
      );
      for (final header in scenario.finalHeaders) {
        expect(find.text(header), findsOneWidget);
      }
      for (final oldHeader in scenario.initialHeaders) {
        if (!scenario.finalHeaders.contains(oldHeader)) {
          expect(find.text(oldHeader), findsNothing);
        }
      }
      expect(find.byType(NextEpisodeCard),
          findsNWidgets(scenario.removesFirst ? 2 : 3));
      if (scenario.removesFirst) {
        expect(fixture.card(_tmdbIds.first), findsNothing);
      } else {
        expect(
          find.descendant(
            of: fixture.card(_tmdbIds.first),
            matching: find.text(_episodeName(_tmdbIds.first, 2)),
          ),
          findsOneWidget,
        );
        expect(find.text(_episodeName(_tmdbIds.first, 1)), findsNothing);
      }
      for (final tmdbId in _tmdbIds.skip(1)) {
        expect(
          find.descendant(
            of: fixture.card(tmdbId),
            matching: find.text(_episodeName(tmdbId, 1)),
          ),
          findsOneWidget,
        );
        final episodes = (await tester.runAsync(
            () => app.db.showsDao.getEpisodesByShow(fixture.dbIds[tmdbId]!)))!;
        expect(episodes.where((episode) => episode.watched), isEmpty);
      }
      expect(tester.takeException(), isNull);
    });
  }
}

String _episodeName(int tmdbId, int number) =>
    'Episodio $number · Serie $tmdbId';

class _Scenario {
  const _Scenario(
    this.name, {
    this.firstEpisodeCount = 1,
    this.realSeasonProvider = false,
    this.firstOld = false,
    this.othersOld = false,
    required this.initialHeaders,
    required this.finalHeaders,
  });

  final String name;
  final int firstEpisodeCount;
  final bool realSeasonProvider;
  final bool firstOld;
  final bool othersOld;
  final List<String> initialHeaders;
  final List<String> finalHeaders;

  bool get removesFirst => firstEpisodeCount == 1;
}

class _CardIdentity {
  const _CardIdentity(this.element, this.state);

  final Element element;
  final State<StatefulWidget> state;
}

class _FeedFixture {
  _FeedFixture(this.scenario);

  final _Scenario scenario;
  final dbIds = <int, int>{};
  final seasonBuilds = <int, int>{};
  final seasonDisposals = <int, int>{};
  final detailBuilds = <int, int>{};
  final detailDisposals = <int, int>{};

  Finder card(int tmdbId) => find.byWidgetPredicate((widget) =>
      widget is NextEpisodeCard &&
      widget.key == ValueKey<int>(dbIds[tmdbId]!) &&
      widget.showData.show.tmdbId == tmdbId);

  Future<AppTestHarness> create() async {
    final overrides = <Override>[];
    final seasons = <int, TmdbSeason>{};
    for (final tmdbId in _tmdbIds) {
      final episodeCount =
          tmdbId == _tmdbIds.first ? scenario.firstEpisodeCount : 2;
      final season = TmdbSeason(
        seasonNumber: 1,
        episodeCount: episodeCount,
        episodes: [
          for (var number = 1; number <= episodeCount; number++)
            TmdbEpisode(
              episodeNumber: number,
              name: _episodeName(tmdbId, number),
              airDate: '2020-01-01',
            ),
        ],
      );
      seasons[tmdbId] = season;
      final detail = TmdbShowDetail(
        id: tmdbId,
        name: 'Serie $tmdbId',
        inProduction: true,
        numberOfSeasons: 1,
        numberOfEpisodes: episodeCount,
        genres: const [],
        originCountries: const [],
        seasons: [season],
      );
      overrides.add(showDetailProvider(tmdbId).overrideWith((ref) async {
        detailBuilds.update(tmdbId, (count) => count + 1, ifAbsent: () => 1);
        ref.onDispose(() {
          detailDisposals.update(tmdbId, (count) => count + 1,
              ifAbsent: () => 1);
        });
        return detail;
      }));
      if (!scenario.realSeasonProvider) {
        overrides.add(seasonDetailProvider(showId: tmdbId, seasonNumber: 1)
            .overrideWith((ref) async {
          seasonBuilds.update(tmdbId, (count) => count + 1, ifAbsent: () => 1);
          ref.onDispose(() {
            seasonDisposals.update(tmdbId, (count) => count + 1,
                ifAbsent: () => 1);
          });
          return season;
        }));
      }
    }

    final app = await AppTestHarness.create(overrides: overrides);
    final now = DateTime.now();
    for (var index = 0; index < _tmdbIds.length; index++) {
      final tmdbId = _tmdbIds[index];
      final season = seasons[tmdbId]!;
      final old = index == 0 ? scenario.firstOld : scenario.othersOld;
      final id = await app.db.showsDao.insertShow(TrackedShowsCompanion(
        tmdbId: Value(tmdbId),
        title: Value('Serie $tmdbId'),
        status: const Value(MediaStatus.watching),
        totalEpisodes: Value(season.episodeCount),
        totalSeasons: const Value(1),
        // Distinct timestamps make the marked card deterministically first.
        addedAt: Value(now.subtract(Duration(minutes: index))),
        lastWatchedAt:
            Value(old ? now.subtract(const Duration(days: 60)) : now),
      ));
      dbIds[tmdbId] = id;
      await app.db.showsDao.insertSeasons(id, {1: season.episodeCount});
      await app.db.cacheDao.saveSeasonEpisodes([
        for (final episode in season.episodes!)
          CachedEpisodesCompanion.insert(
            tmdbShowId: tmdbId,
            seasonNumber: 1,
            episodeNumber: episode.episodeNumber,
            name: episode.name,
            airDate: Value(episode.airDate),
            cachedAt: now,
          ),
      ]);
    }
    return app;
  }
}
