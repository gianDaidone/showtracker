import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:showtracker/core/riverpod_utils.dart';
import 'package:showtracker/core/router/app_router.dart';
import 'package:showtracker/core/widgets/animated_refresh_button.dart';
import 'package:showtracker/features/series/data/tmdb_service.dart';
import 'package:showtracker/features/series/presentation/show_detail_screen.dart';
import 'package:showtracker/features/series/presentation/widgets/next_episode_card.dart';
import 'package:showtracker/features/series/providers/series_providers.dart';

import '../../../support/app_test_harness.dart';
import '../cold_offline_test.dart' show seedColdShow, coldSnapshot;

void main() {
  late MockClient client;
  late List<Uri> requests;
  setUp(() {
    requests = [];
    client = MockClient((request) async {
      requests.add(request.url);
      throw http.ClientException('Failed host lookup: api.themoviedb.org');
    });
  });
  tearDown(() => client.close());

  Future<AppTestHarness> create(WidgetTester tester) async =>
      (await tester.runAsync(() => AppTestHarness.create(
            tmdbService: TmdbService(client),
          )))!;

  Future<void> settleHome(AppTestHarness app, WidgetTester tester,
      {bool anime = false}) async {
    // Start via the real screen first; await its SQLite work outside fake time.
    await app.pump(tester);
    await tester.runAsync(() async {
      await app.container.readFuture(visibleWatchingShowsProvider.future);
      if (anime) {
        await app.container.readFuture(showDetailProvider(42).future);
        await app.container.readFuture(
            seasonDetailProvider(showId: 42, seasonNumber: 2).future);
      }
    });
    await app.flush(tester);
  }

  Future<void> openDetail(AppTestHarness app, WidgetTester tester,
      {int id = 42}) async {
    app.container.read(appRouterProvider).go('/series/detail/$id');
    await tester.pump();
    await tester.runAsync(() async {
      final future = app.container.readFuture(showDetailProvider(id).future);
      if (id == 999) {
        await expectLater(future, throwsA(isA<http.ClientException>()));
      } else {
        await future;
      }
    });
    await app.flush(tester);
  }

  void expectCleanTransport(WidgetTester tester) {
    expect(find.textContaining('ClientException'), findsNothing);
    expect(find.textContaining('Failed host lookup'), findsNothing);
    expect(find.textContaining('api.themoviedb.org'), findsNothing);
    expect(requests.every((u) => u.host == 'api.themoviedb.org'), isTrue);
    expect(tester.takeException(), isNull);
  }

  testWidgets(
      'cold Regina Rossa never resurrects undated S3E1 or its count',
      (tester) => http.runWithClient(() async {
            final app = await create(tester);
            addTearDown(() => app.dispose(tester));
            await tester.runAsync(() => seedColdShow(app.db, expired: true));
            final before = await tester.runAsync(() => coldSnapshot(app.db));
            await settleHome(app, tester);
            expect(find.text('Sei in pari!'), findsOneWidget);
            expect(find.text('Da Vedere (1)'), findsNothing);
            expect(find.byType(NextEpisodeCard), findsNothing);
            // Opening detail must reach real providers too, even when the list hid it.
            await openDetail(app, tester);
            expect(find.text('Regina Rossa'), findsWidgets);
            expect(find.textContaining('dati salvati', findRichText: true),
                findsWidgets);
            expect(requests, isNotEmpty);
            expectCleanTransport(tester);
            expect(await tester.runAsync(() => coldSnapshot(app.db)), before);
          }, () => client));

  for (final expired in [false, true]) {
    testWidgets(
        'cold anime ${expired ? 'expired' : 'fresh'} keeps S01 P2 E01',
        (tester) => http.runWithClient(() async {
              final app = await create(tester);
              addTearDown(() => app.dispose(tester));
              await tester.runAsync(
                  () => seedColdShow(app.db, anime: true, expired: expired));
              final before = await tester.runAsync(() => coldSnapshot(app.db));
              await settleHome(app, tester, anime: true);
              expect(find.text('Non visti da tempo (1)'), findsOneWidget);
              expect(find.byType(NextEpisodeCard), findsOneWidget);
              expect(find.text('S01 P2 E01'), findsOneWidget);
              expect(find.text('S02 E01'), findsNothing);
              expect(find.text('Il secondo cour'), findsOneWidget);
              await openDetail(app, tester);
              expect(find.text('Anime salvato'), findsWidgets);
              expect(find.textContaining('dati salvati', findRichText: true),
                  findsWidgets);
              expectCleanTransport(tester);
              final detailScroll = find
                  .descendant(
                    of: find.byType(ShowDetailScreen),
                    matching: find.byType(Scrollable),
                  )
                  .first;
              final secondCour = find.textContaining('Stagione 1 Parte 2');
              await tester.scrollUntilVisible(secondCour, 250,
                  scrollable: detailScroll, maxScrolls: 8);
              await Scrollable.ensureVisible(tester.element(secondCour),
                  alignment: 0.5);
              await tester.tap(secondCour);
              await app.flush(tester);
              final cachedTitle = find.text('Il secondo cour');
              await tester.scrollUntilVisible(cachedTitle, 200,
                  scrollable: detailScroll, maxScrolls: 4);
              expect(cachedTitle, findsOneWidget);
              expectCleanTransport(tester);
              expect(await tester.runAsync(() => coldSnapshot(app.db)), before);
              tester.state<ScrollableState>(detailScroll).position.jumpTo(0);
              await app.flush(tester);
              await tester.ensureVisible(find.byType(AnimatedRefreshButton));

              // A failed manual refresh may expire caches, never remove their payload.
              final trackedBefore = await tester
                  .runAsync(() => coldSnapshot(app.db, includeCache: false));
              final episodes = await tester.runAsync(
                  () => app.db.cacheDao.getSeasonEpisodesIgnoringTtl(42, 2));
              final cours = await tester.runAsync(
                  () => app.db.animeCacheDao.getStaleAnimeSeasons(42));
              await tester.tap(find.byType(AnimatedRefreshButton));
              await app.flush(tester);
              await tester.runAsync(() =>
                  app.container.readFuture(showDetailProvider(42).future));
              await tester.pump(const Duration(milliseconds: 600));
              await app.flush(tester);
              expect(
                  tester
                      .widget<AnimatedRefreshButton>(
                          find.byType(AnimatedRefreshButton))
                      .state,
                  RefreshState.error);
              final retainedEpisodes = await tester.runAsync(
                  () => app.db.cacheDao.getSeasonEpisodesIgnoringTtl(42, 2));
              expect(
                  retainedEpisodes!
                      .map((e) => e.copyWith(cachedAt: DateTime.utc(2000))),
                  episodes!
                      .map((e) => e.copyWith(cachedAt: DateTime.utc(2000))));
              expect(
                  await tester.runAsync(
                      () => coldSnapshot(app.db, includeCache: false)),
                  trackedBefore);
              final retained = await tester.runAsync(
                  () => app.db.animeCacheDao.getStaleAnimeSeasons(42));
              expect(retained!.map((s) => s.toJson()),
                  cours!.map((s) => s.toJson()));
              // La voce dello status selector esiste anche se non selezionata;
              // il confronto trackedBefore sopra verifica che non sia cambiata.
              expect(find.text('Segna come Completata'), findsNothing);
              expectCleanTransport(tester);
              await tester.pump(const Duration(milliseconds: 1600));
              await app.flush(tester);
            }, () => client));
  }

  testWidgets(
      'untracked cold detail explains connection failure without DNS',
      (tester) => http.runWithClient(() async {
            final app = await create(tester);
            addTearDown(() => app.dispose(tester));
            await settleHome(app, tester);
            await openDetail(app, tester, id: 999);
            expect(find.textContaining('connessione'), findsOneWidget);
            expect(find.text('Riprova'), findsOneWidget);
            expect(find.byIcon(Icons.error_outline), findsOneWidget);
            expect(requests, isNotEmpty);
            expectCleanTransport(tester);
          }, () => client));
}
