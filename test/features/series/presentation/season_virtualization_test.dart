import 'dart:async';

import 'package:drift/drift.dart' hide isNull;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:showtracker/core/database/app_database.dart';
import 'package:showtracker/core/riverpod_utils.dart';
import 'package:showtracker/core/theme/app_theme.dart';
import 'package:showtracker/features/series/data/models/normalized_anime_season.dart';
import 'package:showtracker/features/series/data/models/tmdb_episode.dart';
import 'package:showtracker/features/series/data/models/tmdb_season.dart';
import 'package:showtracker/features/series/data/models/tmdb_show_detail.dart';
import 'package:showtracker/features/series/presentation/show_detail_screen.dart';
import 'package:showtracker/features/series/presentation/widgets/episode_tile.dart';
import 'package:showtracker/features/series/presentation/widgets/season_section.dart';
import 'package:showtracker/features/series/providers/series_providers.dart';

import '../../../support/app_test_harness.dart';

TmdbShowDetail _detail(List<TmdbSeason> seasons) => TmdbShowDetail(
      id: 42,
      name: 'Serie locale',
      inProduction: false,
      genres: const [],
      originCountries: const [],
      seasons: seasons,
    );

Widget _seasonView({
  required TmdbShowDetail detail,
  required TmdbSeason season,
  ScrollController? controller,
  TrackedShow? trackedShow,
}) =>
    MaterialApp(
      theme: AppTheme.dark(),
      home: Scaffold(
        body: CustomScrollView(
          controller: controller,
          scrollCacheExtent: const ScrollCacheExtent.pixels(250),
          slivers: [
            SeasonSection(
              key: ValueKey((detail.id, season.seasonNumber)),
              detail: detail,
              season: season,
              trackedShow: trackedShow,
            ),
          ],
        ),
      ),
    );

Finder _tile(int episodeNumber) => find.byWidgetPredicate(
      (widget) =>
          widget is EpisodeTile &&
          widget.episode.episodeNumber == episodeNumber,
    );

Finder _checkbox(int episodeNumber) => find.descendant(
      of: _tile(episodeNumber),
      matching: find.byType(Checkbox),
    );

void _expectBoundedEpisodes() {
  final mounted = find.byType(EpisodeTile).evaluate().length;
  expect(mounted, greaterThan(0));
  // A 600px viewport + 250px cache on either side should mount only a small
  // fraction of the fixture, not every row of a 200/500-episode season.
  expect(mounted, lessThan(30));
}

void main() {
  for (final count in [200, 500]) {
    testWidgets('$count episodi: viewport limitato, scroll e riapertura',
        (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      final season = TmdbSeason(
        seasonNumber: 1,
        episodeCount: count,
        name: 'Stagione lunga',
        episodes: [
          for (var i = 1; i <= count; i++)
            TmdbEpisode(
              episodeNumber: i,
              name: 'Episodio locale $i',
              airDate: '2020-01-01',
            ),
        ],
      );
      await tester.pumpWidget(ProviderScope(
        retry: noProviderRetry,
        overrides: [
          seasonDetailProvider(showId: 42, seasonNumber: 1)
              .overrideWith((ref) async => season),
        ],
        child: _seasonView(
          detail: _detail([season]),
          season: season,
          controller: controller,
        ),
      ));
      expect(find.byType(EpisodeTile), findsNothing);
      await tester.tap(find.text('Stagione lunga'));
      await tester.pumpAndSettle();
      _expectBoundedEpisodes();
      expect(_tile(1), findsOneWidget);
      expect(_tile(count - 20), findsNothing);
      expect(find.byType(Checkbox), findsNothing);

      await tester.scrollUntilVisible(
        _tile(count - 20),
        600,
        maxScrolls: 100,
      );
      await tester.pumpAndSettle();
      expect(_tile(count - 20), findsOneWidget);
      expect(_tile(1), findsNothing);
      _expectBoundedEpisodes();

      controller.jumpTo(0);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Stagione lunga'));
      await tester.pumpAndSettle();
      expect(find.byType(EpisodeTile), findsNothing);
      await tester.tap(find.text('Stagione lunga'));
      await tester.pumpAndSettle();
      expect(_tile(1), findsOneWidget);
      _expectBoundedEpisodes();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('più cour aperte mantengono lo stato dopo scroll e riordino',
      (tester) async {
    const first = TmdbSeason(
      seasonNumber: 1,
      episodeCount: 1,
      name: 'Stagione 1 Parte 1 · Fall 2020',
      episodes: [
        TmdbEpisode(
            episodeNumber: 1, name: 'Prima cour', airDate: '2020-01-01'),
      ],
    );
    const second = TmdbSeason(
      seasonNumber: 2,
      episodeCount: 1,
      name: 'Stagione 1 Parte 2 · Winter 2021',
      episodes: [
        TmdbEpisode(
            episodeNumber: 1, name: 'Seconda cour', airDate: '2021-01-01'),
      ],
    );
    final animeDetail = _detail([first, second]).copyWith(animeSeasonsData: [
      const NormalizedAnimeSeason(
        seasonNumber: 1,
        tmdbSeasonNumber: 1,
        anilistId: 101,
        episodeCount: 1,
        status: 'FINISHED',
        streamingEpisodes: [],
      ),
      const NormalizedAnimeSeason(
        seasonNumber: 2,
        tmdbSeasonNumber: 1,
        anilistId: 102,
        episodeCount: 1,
        status: 'FINISHED',
        streamingEpisodes: [],
      ),
    ]);
    var currentDetail = animeDetail;
    final app = (await tester.runAsync(() => AppTestHarness.create(overrides: [
          showDetailProvider(42).overrideWith((ref) async => currentDetail),
          seasonDetailProvider(showId: 42, seasonNumber: 1)
              .overrideWith((ref) async => first),
          seasonDetailProvider(showId: 42, seasonNumber: 2)
              .overrideWith((ref) async => second),
        ])))!;
    addTearDown(() => app.dispose(tester));
    // Re-evaluating showDetail keeps the screen/body mounted, as a metadata
    // refresh does, but changes the order of the keyed section slivers.
    await tester.pumpWidget(UncontrolledProviderScope(
      container: app.container,
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: const ShowDetailScreen(tmdbId: 42),
      ),
    ));
    await app.flush(tester);
    Future<void> revealHeader(TmdbSeason season) async {
      await tester.scrollUntilVisible(find.text(season.name!), 200);
      // Alignment zero can leave a header beneath the pinned SliverAppBar.
      await Scrollable.ensureVisible(
        tester.element(find.text(season.name!)),
        alignment: 0.5,
      );
      await tester.pumpAndSettle();
    }

    final firstTile = find.byKey(const ValueKey((42, 1, 1)));
    final secondTile = find.byKey(const ValueKey((42, 2, 1)));
    await revealHeader(first);
    await tester.tap(find.text(first.name!));
    await app.flush(tester);
    await tester.scrollUntilVisible(firstTile, 150);
    expect(firstTile, findsOneWidget);
    await revealHeader(second);
    await tester.tap(find.text(second.name!));
    await app.flush(tester);
    await tester.scrollUntilVisible(secondTile, 150);
    expect(secondTile, findsOneWidget);
    expect(find.byIcon(Icons.expand_less), findsNWidgets(2));

    currentDetail = animeDetail.copyWith(seasons: [second, first]);
    app.container.invalidate(showDetailProvider(42));
    await app.flush(tester);
    final scrollable =
        tester.state<ScrollableState>(find.byType(Scrollable).first);
    scrollable.position.jumpTo(0);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(firstTile, 200);
    expect(firstTile, findsOneWidget);
    await revealHeader(second);
    await tester.scrollUntilVisible(secondTile, 150);
    expect(secondTile, findsOneWidget);
    expect(find.byIcon(Icons.expand_less), findsNWidgets(2));
    await revealHeader(second);
    await tester.tap(find.text(second.name!));
    await tester.pumpAndSettle();
    expect(secondTile, findsNothing);
    await tester.scrollUntilVisible(firstTile, 150);
    expect(firstTile, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('loading, errore e stagione vuota restano sliver validi',
      (tester) async {
    const season =
        TmdbSeason(seasonNumber: 1, episodeCount: 0, name: 'In arrivo');
    final response = Completer<TmdbSeason>();
    var fail = true;
    final container = ProviderContainer(
      retry: noProviderRetry,
      overrides: [
        seasonDetailProvider(showId: 42, seasonNumber: 1).overrideWith((ref) {
          if (!response.isCompleted) return response.future;
          if (fail) throw StateError('offline');
          return Future.value(season);
        }),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: _seasonView(detail: _detail([season]), season: season),
    ));
    expect(find.text('In corso'), findsOneWidget);
    await tester.tap(find.text('In arrivo'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    response.completeError(StateError('offline'));
    await tester.pumpAndSettle();
    expect(
        find.textContaining('Errore nel caricamento episodi:'), findsOneWidget);
    fail = false;
    container.invalidate(seasonDetailProvider(showId: 42, seasonNumber: 1));
    await tester.pumpAndSettle();
    expect(find.text('Nessun episodio disponibile.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('batch, checkbox, precedenti e futuro conservano i contratti',
      (tester) async {
    final season = TmdbSeason(
      seasonNumber: 1,
      episodeCount: 4,
      name: 'Stagione 1',
      episodes: [
        const TmdbEpisode(episodeNumber: 1, name: 'Uno', airDate: '2020-01-01'),
        TmdbEpisode(
          episodeNumber: 2,
          name: 'Due',
          airDate: '2020-01-02',
          airingAt: DateTime(2020, 1, 1, 12),
        ),
        const TmdbEpisode(episodeNumber: 3, name: 'Tre', airDate: '2020-01-03'),
        const TmdbEpisode(
            episodeNumber: 4, name: 'Futuro', airDate: '2099-01-01'),
      ],
    );
    final app = (await tester.runAsync(() => AppTestHarness.create(overrides: [
          seasonDetailProvider(showId: 42, seasonNumber: 1)
              .overrideWith((ref) async => season),
        ])))!;
    addTearDown(() => app.dispose(tester));
    final trackedShow = (await tester.runAsync(() async {
      final id = await app.db.showsDao.insertShow(TrackedShowsCompanion(
        tmdbId: const Value(42),
        title: const Value('Serie locale'),
        status: const Value(MediaStatus.watching),
        addedAt: Value(DateTime(2026, 1, 1)),
      ));
      await app.db.showsDao.insertSeasons(id, {1: 4});
      return (await app.db.showsDao.getById(id))!;
    }))!;
    await tester.pumpWidget(UncontrolledProviderScope(
      container: app.container,
      child: _seasonView(
        detail: _detail([season]),
        season: season,
        trackedShow: trackedShow,
      ),
    ));
    await app.flush(tester);
    await tester.tap(find.text('Stagione 1'));
    await app.flush(tester);
    expect(find.text('0 / 4 ep. visti'), findsOneWidget);
    expect(tester.widget<EpisodeTile>(_tile(1)).isBatchRelease, isTrue);
    expect(tester.widget<EpisodeTile>(_tile(2)).isBatchRelease, isTrue);
    expect(tester.widget<EpisodeTile>(_tile(3)).isBatchRelease, isFalse);
    expect(_checkbox(4), findsNothing);
    expect(find.text('01/01/2099'), findsOneWidget);

    await tester.runAsync(() => tester.tap(_checkbox(1)));
    await app.flush(tester);
    expect(tester.widget<Checkbox>(_checkbox(1)).value, isTrue);
    expect(find.text('1 / 4 ep. visti'), findsOneWidget);
    await tester.runAsync(() => tester.tap(_checkbox(3)));
    await app.flush(tester);
    expect(find.text('Episodi precedenti'), findsOneWidget);
    await tester.tap(find.text('Segna tutti i precedenti'));
    await app.flush(tester);
    expect(find.text('3 / 4 ep. visti'), findsOneWidget);
    expect(tester.widget<Checkbox>(_checkbox(2)).value, isTrue);
    await tester.runAsync(() => tester.tap(_checkbox(2)));
    await app.flush(tester);
    expect(find.text('2 / 4 ep. visti'), findsOneWidget);
    expect(tester.widget<Checkbox>(_checkbox(2)).value, isFalse);
    expect(tester.widget<EpisodeTile>(_tile(2)).isBatchRelease, isTrue);

    await tester.tap(find.text('Due'));
    await app.flush(tester);
    expect(find.text('Segna come Visto'), findsOneWidget);
    expect(find.text('S01 E02'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Futuro'));
    await tester.pumpAndSettle();
    expect(find.text('Segna come Visto'), findsNothing);
    expect(find.text('Visto'), findsNothing);
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    final episodes = await tester.runAsync(
      () => app.db.showsDao.getEpisodesByShow(trackedShow.id),
    );
    expect(
        episodes!.where((e) => e.watched).map((e) => e.episodeNumber), [1, 3]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sola lettura apre il dettaglio ma non mostra azioni visto',
      (tester) async {
    const season = TmdbSeason(
      seasonNumber: 1,
      episodeCount: 1,
      name: 'Stagione 1',
      episodes: [
        TmdbEpisode(
            episodeNumber: 1, name: 'Solo lettura', airDate: '2020-01-01'),
      ],
    );
    await tester.pumpWidget(ProviderScope(
      retry: noProviderRetry,
      overrides: [
        seasonDetailProvider(showId: 42, seasonNumber: 1)
            .overrideWith((ref) async => season),
      ],
      child: _seasonView(detail: _detail([season]), season: season),
    ));
    await tester.tap(find.text('Stagione 1'));
    await tester.pumpAndSettle();
    expect(find.text('1 episodi'), findsOneWidget);
    expect(tester.widget<EpisodeTile>(_tile(1)).onToggle, isNull);
    expect(find.byType(Checkbox), findsNothing);
    await tester.tap(find.text('Solo lettura'));
    await tester.pumpAndSettle();
    expect(find.text('S01 E01'), findsOneWidget);
    expect(find.text('Segna come Visto'), findsNothing);
    expect(find.text('Visto'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
