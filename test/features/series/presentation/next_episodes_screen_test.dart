import 'package:drift/drift.dart' hide isNull;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:showtracker/core/database/app_database.dart';
import 'package:showtracker/core/theme/app_theme.dart';
import 'package:showtracker/features/series/presentation/next_episodes_screen.dart';
import 'package:showtracker/features/series/data/models/tmdb_episode.dart';
import 'package:showtracker/features/series/data/models/tmdb_season.dart';
import 'package:showtracker/features/series/data/models/tmdb_show_detail.dart';
import 'package:showtracker/features/series/presentation/widgets/next_episode_card.dart';
import 'package:showtracker/features/series/presentation/widgets/upcoming_episode_card.dart';
import 'package:showtracker/features/series/providers/series_providers.dart';

import '../../../support/app_test_harness.dart';

void main() {
  testWidgets('episodio annunciato senza data non lascia un conteggio fantasma',
      (tester) async {
    const announced = TmdbEpisode(episodeNumber: 1, name: 'Episode 1');
    const season =
        TmdbSeason(seasonNumber: 3, episodeCount: 1, episodes: [announced]);
    const detail = TmdbShowDetail(
      id: 42,
      name: 'Serie senza data',
      inProduction: true,
      numberOfEpisodes: 14,
      numberOfSeasons: 3,
      genres: [],
      originCountries: [],
      seasons: [season],
    );
    final app = (await tester.runAsync(() => AppTestHarness.create(overrides: [
          showDetailProvider(42).overrideWith((ref) async => detail),
          seasonDetailProvider(showId: 42, seasonNumber: 3)
              .overrideWith((ref) async => season),
        ])))!;
    addTearDown(() => app.dispose(tester));
    await tester.runAsync(() async {
      final id = await app.db.showsDao.insertShow(TrackedShowsCompanion(
        tmdbId: const Value(42),
        title: const Value('Serie senza data'),
        status: const Value(MediaStatus.watching),
        totalEpisodes: const Value(14),
        totalSeasons: const Value(3),
        tmdbStatus: const Value('Returning Series'),
        addedAt: Value(DateTime.now()),
      ));
      await app.db.showsDao.insertSeasons(id, {1: 7, 2: 6, 3: 1});
      for (var s = 1; s <= 2; s++) {
        for (var e = 1; e <= (s == 1 ? 7 : 6); e++) {
          await app.db.showsDao.markEpisodeWatched(id, s, e);
        }
      }
      await app.db.cacheDao.saveSeasonEpisodes([
        CachedEpisodesCompanion.insert(
            tmdbShowId: 42,
            seasonNumber: 3,
            episodeNumber: 1,
            name: 'Episode 1',
            cachedAt: DateTime.now()),
      ]);
    });
    await app.pump(tester);
    expect(find.text('Sei in pari!'), findsOneWidget);
    expect(find.text('Da Vedere (1)'), findsNothing);
    expect(find.byType(NextEpisodeCard), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Da Vedere conta le card e il visto aggiorna progressi e lista',
      (tester) async {
    const episode = TmdbEpisode(
        episodeNumber: 1, name: 'Primo episodio', airDate: '2020-01-01');
    const season =
        TmdbSeason(seasonNumber: 1, episodeCount: 1, episodes: [episode]);
    const detail = TmdbShowDetail(
      id: 42,
      name: 'Serie locale',
      inProduction: true,
      numberOfSeasons: 1,
      numberOfEpisodes: 1,
      genres: [],
      originCountries: [],
      seasons: [season],
    );
    final app = (await tester.runAsync(() => AppTestHarness.create(overrides: [
          showDetailProvider(42).overrideWith((ref) async => detail),
          seasonDetailProvider(showId: 42, seasonNumber: 1)
              .overrideWith((ref) async => season),
        ])))!;
    addTearDown(() => app.dispose(tester));
    final id = (await tester.runAsync(() async {
      final id = await app.db.showsDao.insertShow(TrackedShowsCompanion(
        tmdbId: const Value(42),
        title: const Value('Serie locale'),
        status: const Value(MediaStatus.watching),
        totalEpisodes: const Value(1),
        totalSeasons: const Value(1),
        addedAt: Value(DateTime.now()),
      ));
      await app.db.showsDao.insertSeasons(id, {1: 1});
      await app.db.cacheDao.saveSeasonEpisodes([
        CachedEpisodesCompanion.insert(
          tmdbShowId: 42,
          seasonNumber: 1,
          episodeNumber: 1,
          name: episode.name,
          airDate: Value(episode.airDate),
          cachedAt: DateTime.now(),
        ),
      ]);
      return id;
    }))!;
    await app.pump(tester);
    expect(find.text('Da Vedere (1)'), findsOneWidget);
    expect(find.byType(NextEpisodeCard), findsOneWidget);
    expect(find.text('Primo episodio'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.check));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 699));
    // La scadenza del timer avvia SQLite: eseguila nel contesto asincrono reale,
    // come gli altri accessi al DB, senza lasciare I/O nella zona del fake clock.
    await tester.runAsync(() => tester.pump(const Duration(milliseconds: 1)));
    await app.flush(tester);
    final episodes =
        await tester.runAsync(() => app.db.showsDao.getEpisodesByShow(id));
    expect(episodes!.where((e) => e.watched).map((e) => e.episodeNumber), [1]);
    expect(find.byType(NextEpisodeCard), findsNothing);
    expect(find.text('Da Vedere (1)'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Da Vedere usa il totale locale e aggiorna la barra dopo il visto',
      (tester) async {
    const title = 'Il Signore degli Anelli: Gli Anelli del Potere';
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final episodes = [
      for (var n = 1; n <= 4; n++)
        TmdbEpisode(
            episodeNumber: n, name: 'Capitolo $n', airDate: '2020-01-01'),
      TmdbEpisode(
          episodeNumber: 5,
          name: 'Capitolo 5',
          airDate: tomorrow.toIso8601String()),
    ];
    final season =
        TmdbSeason(seasonNumber: 1, episodeCount: 5, episodes: episodes);
    final detail = TmdbShowDetail(
      id: 42,
      name: title,
      inProduction: true,
      numberOfSeasons: 1,
      numberOfEpisodes: 5,
      genres: const [],
      originCountries: const [],
      isLocalSnapshot: true,
      seasons: const [TmdbSeason(seasonNumber: 1, episodeCount: 0)],
      nextEpisodeToAir: TmdbNextEpisode(
        seasonNumber: 1,
        episodeNumber: 5,
        name: 'Capitolo 5',
        airDate: tomorrow.toIso8601String(),
      ),
    );
    final app = (await tester.runAsync(() => AppTestHarness.create(overrides: [
          showDetailProvider(42).overrideWith((ref) async => detail),
          seasonDetailProvider(showId: 42, seasonNumber: 1)
              .overrideWith((ref) async => season),
        ])))!;
    addTearDown(() => app.dispose(tester));
    await tester.runAsync(() async {
      final id = await app.db.showsDao.insertShow(TrackedShowsCompanion(
        tmdbId: const Value(42),
        title: const Value(title),
        status: const Value(MediaStatus.watching),
        totalEpisodes: const Value(5),
        totalSeasons: const Value(1),
        nextEpisodeSeason: const Value(1),
        nextEpisodeNumber: const Value(5),
        nextEpisodeAirDate: Value(tomorrow),
        addedAt: Value(DateTime.now()),
      ));
      await app.db.showsDao.insertSeasons(id, {1: 5});
      await app.db.showsDao.markEpisodeWatched(id, 1, 1);
      await app.db.cacheDao.saveSeasonEpisodes([
        for (final episode in episodes)
          CachedEpisodesCompanion.insert(
            tmdbShowId: 42,
            seasonNumber: 1,
            episodeNumber: episode.episodeNumber,
            name: episode.name,
            airDate: Value(episode.airDate),
            cachedAt: DateTime.now(),
          ),
      ]);
    });

    await _pumpNarrowSeries(tester, app);

    final card = find.byType(NextEpisodeCard);
    final progress = find.descendant(
      of: card,
      matching: find.byType(LinearProgressIndicator),
    );
    expect(tester.widget<Text>(find.text(title)).maxLines, isNull);
    expect(find.text('+2 ep'), findsOneWidget);
    expect(tester.widget<LinearProgressIndicator>(progress).value, 1 / 5);
    final thumbnail = find.descendant(
      of: card,
      matching: find.byType(ClipRRect),
    );
    tester.view.physicalSize = const Size(1024, 860);
    tester.platformDispatcher.textScaleFactorTestValue = 1;
    await tester.pump();
    final normalThumbnail = tester.getRect(thumbnail);
    expect(normalThumbnail.height, greaterThan(68));
    expect(
        normalThumbnail.bottom, closeTo(tester.getRect(progress).bottom, 0.5));

    tester.view.physicalSize = const Size(320, 860);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    await tester.pump();
    final tallThumbnail = tester.getRect(thumbnail);
    expect(tallThumbnail.height, 112);
    expect(
        tallThumbnail.top, closeTo(tester.getRect(find.text(title)).top, 0.5));
    expect(tallThumbnail.bottom, lessThan(tester.getRect(progress).bottom));
    tester.platformDispatcher.textScaleFactorTestValue = 1.4;
    await tester.pump();

    final markButton = find.descendant(
      of: card,
      matching: find.byIcon(Icons.check),
    );
    final progressRect = tester.getRect(progress);
    final episodeTitleRect = tester.getRect(find.text('Capitolo 2'));
    expect(progressRect.top, greaterThan(episodeTitleRect.bottom));
    expect(progressRect.right, lessThan(tester.getRect(markButton).left));

    await tester.tap(markButton);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 699));
    await tester.runAsync(() => tester.pump(const Duration(milliseconds: 1)));
    await app.flush(tester);

    expect(find.text('+1 ep'), findsOneWidget);
    expect(find.text('+2 ep'), findsNothing);
    expect(tester.widget<LinearProgressIndicator>(progress).value, 2 / 5);
    expect(tester.takeException(), isNull);
  });

  testWidgets('In Uscita raggruppa le date e mostra solo gli orari precisi',
      (tester) async {
    const longTitle = 'Dragon Ball Super: Beerus, il dio della distruzione';
    final today = DateTime.now();
    final tomorrow = DateTime(today.year, today.month, today.day + 1, 17, 53);
    final farFuture = DateTime(today.year, today.month, today.day + 35, 9);
    final entries = [
      (longTitle, tomorrow, true),
      ('Il Signore degli Anelli: Gli Anelli del Potere', tomorrow, false),
      ('Una serie più avanti', farFuture, false),
    ];
    final app = (await tester.runAsync(() => AppTestHarness.create(overrides: [
          for (var i = 0; i < entries.length; i++)
            seasonDetailProvider(showId: 101 + i, seasonNumber: 1).overrideWith(
                (ref) async =>
                    const TmdbSeason(seasonNumber: 1, episodeCount: 0)),
          upcomingEpisodesProvider.overrideWith((ref) async => [
                for (final (index, (title, date, precise)) in entries.indexed)
                  UpcomingEpisodeInfo(
                    show: TrackedShow(
                      id: index + 1,
                      tmdbId: 101 + index,
                      title: title,
                      status: MediaStatus.watching,
                      isAnime: precise,
                      addedAt: today,
                    ),
                    episode: TmdbNextEpisode(
                      seasonNumber: 1,
                      episodeNumber: index + 1,
                      name: 'Titolo episodio',
                    ),
                    airDate: DateUtils.dateOnly(date),
                    preciseAirTime: precise ? date : null,
                  ),
              ]),
        ])))!;
    addTearDown(() => app.dispose(tester));

    await _pumpNarrowSeries(tester, app, initialTab: 1);

    expect(find.textContaining('Domani · '), findsOneWidget);
    expect(find.textContaining('Prossimamente'), findsNothing);
    expect(find.textContaining('In Arrivo'), findsNothing);
    expect(tester.widget<Text>(find.text(longTitle)).maxLines, isNull);
    expect(find.text('S01 E01'), findsOneWidget);
    final time = find.text('17:53');
    expect(time, findsOneWidget);
    final timedCard = find.ancestor(
      of: time,
      matching: find.byType(UpcomingEpisodeCard),
    );
    expect(tester.widget<Text>(time).style?.fontSize, greaterThan(12));
    expect(
      tester.getCenter(time).dy,
      closeTo(tester.getCenter(timedCard).dy, 0.5),
    );
    final timeline = find.descendant(
      of: find.byType(CustomScrollView),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      find.text('S01 E02'),
      180,
      scrollable: timeline,
    );
    expect(find.text('09:00'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('Una serie più avanti'),
      180,
      scrollable: timeline,
    );
    expect(find.text('S01 E03'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('In Uscita espande le anteprime dello stesso rilascio',
      (tester) async {
    final now = DateTime.now();
    final scheduledAt = DateTime(now.year, now.month, now.day + 1, 9);
    final date = scheduledAt.toIso8601String().split('T').first;
    final season = TmdbSeason(
      seasonNumber: 1,
      episodeCount: 4,
      episodes: [
        TmdbEpisode(episodeNumber: 3, name: 'Oltre la soglia', airDate: date),
        TmdbEpisode(episodeNumber: 2, name: 'Il ritorno', airDate: date),
        TmdbEpisode(
          episodeNumber: 4,
          name: 'Un altro giorno',
          airDate: scheduledAt.add(const Duration(days: 1)).toIso8601String(),
        ),
      ],
    );
    final app = (await tester.runAsync(() async {
      final app = await AppTestHarness.create(overrides: [
        seasonDetailProvider(showId: 90, seasonNumber: 1)
            .overrideWith((ref) async => season),
      ]);
      await app.db.showsDao.insertShow(TrackedShowsCompanion(
        tmdbId: const Value(90),
        title: const Value('Una nuova stagione'),
        status: const Value(MediaStatus.watching),
        nextEpisodeSeason: const Value(1),
        nextEpisodeNumber: const Value(1),
        nextEpisodeAirDate: Value(scheduledAt),
        addedAt: Value(now),
      ));
      app.container.listen(upcomingEpisodesProvider, (_, __) {});
      await app.container.read(upcomingEpisodesProvider.future);
      return app;
    }))!;
    addTearDown(() => app.dispose(tester));
    await _pumpNarrowSeries(tester, app, initialTab: 1);

    final toggle = find.text('+2 episodi nello stesso giorno');
    expect(find.textContaining('Domani'), findsOneWidget);
    expect(find.byType(UpcomingEpisodeCard), findsOneWidget);
    expect(toggle, findsOneWidget);
    expect(find.text('S01 E02'), findsNothing);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(find.text('S01 E02'), findsOneWidget);
    expect(find.text('S01 E03'), findsOneWidget);
    expect(find.text('S01 E04'), findsNothing);
    expect(find.text('09:00'), findsNothing);
    expect(tester.getTopLeft(find.text('S01 E02')).dy,
        lessThan(tester.getTopLeft(find.text('S01 E03')).dy));

    await tester.tap(find.text('Oltre la soglia'));
    await app.flush(tester);
    final sheet = find.byType(BottomSheet);
    expect(
      find.descendant(of: sheet, matching: find.text('Oltre la soglia')),
      findsOneWidget,
    );
    expect(find.text('Segna come Visto'), findsNothing);
    Navigator.of(tester.element(sheet)).pop();
    await app.flush(tester);
    await tester.tap(find.text('Nascondi altri episodi'));
    await tester.pumpAndSettle();
    expect(find.text('S01 E02'), findsNothing);
    expect(toggle, findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpNarrowSeries(
  WidgetTester tester,
  AppTestHarness app, {
  int initialTab = 0,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(320, 860);
  tester.platformDispatcher.textScaleFactorTestValue = 1.4;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: app.container,
    child: MaterialApp(
      theme: AppTheme.dark(),
      home: NextEpisodesScreen(initialTab: initialTab),
    ),
  ));
  await app.flush(tester);
}
