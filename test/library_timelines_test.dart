import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:showtracker/core/auth/rawg_auth_state.dart';
import 'package:showtracker/core/database/app_database.dart';
import 'package:showtracker/core/theme/app_theme.dart';
import 'package:showtracker/features/games/presentation/games_screen.dart';
import 'package:showtracker/features/games/providers/games_providers.dart';
import 'package:showtracker/features/movies/presentation/movies_screen.dart';
import 'package:showtracker/features/movies/providers/movies_providers.dart';

import 'support/app_test_harness.dart';

void main() {
  testWidgets('Film raggruppa le uscite senza spostare i titoli senza data',
      (tester) async {
    final app = (await tester.runAsync(seedMovies))!;
    addTearDown(() => app.dispose(tester));
    await mountLibrary(tester, app, const MoviesScreen());
    expect(find.text(watchlistTitle), findsOneWidget);
    expect(tester.widget<Text>(find.text(watchlistTitle)).maxLines, isNull);

    await tester.tap(find.text('In Uscita'));
    await app.flush(tester);
    expect(find.textContaining('Domani'), findsOneWidget);
    expect(find.text('Film in uscita A'), findsOneWidget);
    expect(find.text('Film in uscita B'), findsOneWidget);
    expect(find.text('Film in uscita tra due mesi'), findsOneWidget);
    expect(find.text(watchlistTitle), findsNothing);
    expect(find.textContaining('Prossimamente'), findsNothing);
    setCompactViewport(tester);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Giochi raggruppa le uscite e mantiene voto e ripristino',
      (tester) async {
    final app = (await tester.runAsync(seedGames))!;
    addTearDown(() => app.dispose(tester));
    await mountLibrary(tester, app, const GamesScreen());
    expect(find.text('4 giochi in libreria'), findsOneWidget);
    expect(find.text(backlogTitle), findsOneWidget);
    expect(find.text('PlayStation 5'), findsOneWidget);

    await tester.tap(find.text('In Uscita'));
    await app.flush(tester);
    expect(find.textContaining('Domani'), findsOneWidget);
    expect(find.text('Gioco in uscita A'), findsOneWidget);
    expect(find.text('Gioco in uscita B'), findsOneWidget);
    expect(find.text('Data da annunciare'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Data da annunciare')).dy,
      greaterThan(tester.getBottomLeft(find.text('Gioco in uscita B')).dy),
    );
    expect(find.text('Gioco senza data'), findsOneWidget);

    await tester.tap(find.text('Backlog').first);
    await app.flush(tester);
    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();
    await tester.tap(find.text('8'));
    await tester.pumpAndSettle();
    await tester.runAsync(() => tester.tap(find.text('Conferma')));
    await app.flush(tester);
    final completed =
        await tester.runAsync(() => app.db.gamesDao.getByRawgId(1));
    expect(completed!.status, MediaStatus.completed);
    expect(completed.userRating, 8);

    await tester.tap(find.text('Giocati'));
    await app.flush(tester);
    expect(find.text('Completati (1)'), findsOneWidget);
    expect(find.text('8.0/10'), findsOneWidget);
    await tester.runAsync(() => tester.tap(find.byIcon(Icons.check)));
    await app.flush(tester);
    final reset = await tester.runAsync(() => app.db.gamesDao.getByRawgId(1));
    expect(reset!.status, MediaStatus.planToWatch);
    expect(reset.userRating, isNull);
    setCompactViewport(tester);
    await tester.tap(find.text('Backlog').first);
    await app.flush(tester);
    expect(find.text(backlogTitle), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final (path, filter, searchTooltip, libraryTooltip, title, seed, screen)
      in [
    (
      'movies',
      'movie',
      'Cerca film',
      'Vai ai miei film',
      watchlistTitle,
      seedMovies,
      const MoviesScreen()
    ),
    (
      'games',
      'game',
      'Cerca giochi',
      'Vai ai miei giochi',
      backlogTitle,
      seedGames,
      const GamesScreen()
    ),
  ]) {
    testWidgets('Header e card $path aprono le destinazioni corrette',
        (tester) async {
      final app = (await tester.runAsync(seed))!;
      final router = GoRouter(initialLocation: '/$path', routes: [
        GoRoute(path: '/$path', builder: (_, __) => screen),
        GoRoute(
          path: '/$path/list',
          builder: (_, __) => const Scaffold(body: Text('Libreria aperta')),
        ),
        GoRoute(
          path: '/$path/detail/:id',
          builder: (_, state) =>
              Scaffold(body: Text('Dettaglio ${state.pathParameters['id']}')),
        ),
        GoRoute(
          path: '/search',
          builder: (_, state) => Scaffold(
              body: Text('Filtro ${state.uri.queryParameters['filter']}')),
        ),
      ]);
      addTearDown(() async {
        await app.dispose(tester);
        router.dispose();
      });
      await tester.pumpWidget(UncontrolledProviderScope(
        container: app.container,
        child: MaterialApp.router(routerConfig: router, theme: AppTheme.dark()),
      ));
      await app.flush(tester);

      await tester.tap(find.text(title));
      await app.flush(tester);
      expect(find.text('Dettaglio 1'), findsOneWidget);
      router.pop();
      await app.flush(tester);

      await tester.tap(find.byTooltip(libraryTooltip));
      await app.flush(tester);
      expect(find.text('Libreria aperta'), findsOneWidget);
      router.pop();
      await app.flush(tester);

      await tester.tap(find.byTooltip(searchTooltip));
      await app.flush(tester);
      expect(find.text('Filtro $filter'), findsOneWidget);
    });
  }
}

void setCompactViewport(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(320, 860);
  tester.platformDispatcher.textScaleFactorTestValue = 1.4;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

const watchlistTitle = 'Il curioso caso di un film con un titolo molto lungo';
const backlogTitle =
    'Un gioco di avventura con un titolo particolarmente lungo';

Future<AppTestHarness> seedMovies() async {
  final app = await AppTestHarness.create();
  final now = DateTime.now();
  final tomorrow = DateTime(now.year, now.month, now.day + 1);
  for (final (index, (title, date)) in [
    (watchlistTitle, null),
    ('Film in uscita A', tomorrow),
    ('Film in uscita B', tomorrow),
    (
      'Film in uscita tra due mesi',
      DateTime(now.year, now.month, now.day + 60)
    ),
  ].indexed) {
    await app.db.moviesDao.insertMovie(TrackedMoviesCompanion(
      tmdbId: Value(index + 1),
      title: Value(title),
      status: const Value(MediaStatus.planToWatch),
      releaseDate: Value(date),
      releaseYear: Value(date?.year ?? 2025),
      addedAt: Value(now),
    ));
  }
  app.container.listen(trackedMoviesProvider, (_, __) {});
  app.container.listen(upcomingMoviesProvider, (_, __) {});
  await app.container.read(trackedMoviesProvider.future);
  await app.container.read(upcomingMoviesProvider.future);
  return app;
}

Future<AppTestHarness> seedGames() async {
  final app = await AppTestHarness.create(
    rawgAuth: const RawgAuthenticated('rawg-test'),
  );
  final now = DateTime.now();
  final tomorrow = DateTime(now.year, now.month, now.day + 1);
  for (final (index, (title, date)) in [
    (backlogTitle, DateTime(2024)),
    ('Gioco in uscita A', tomorrow),
    ('Gioco in uscita B', tomorrow),
    ('Gioco senza data', null),
  ].indexed) {
    await app.db.gamesDao.insertGame(TrackedGamesCompanion(
      rawgId: Value(index + 1),
      title: Value(title),
      status: const Value(MediaStatus.planToWatch),
      releaseDate: Value(date),
      platforms: const Value('["PC", "PlayStation 5"]'),
      addedAt: Value(now),
    ));
  }
  app.container.listen(trackedGamesProvider, (_, __) {});
  await app.container.read(trackedGamesProvider.future);
  return app;
}

Future<void> mountLibrary(
  WidgetTester tester,
  AppTestHarness app,
  Widget screen,
) async {
  await tester.pumpWidget(UncontrolledProviderScope(
    container: app.container,
    child: MaterialApp(theme: AppTheme.dark(), home: screen),
  ));
  await app.flush(tester);
}
