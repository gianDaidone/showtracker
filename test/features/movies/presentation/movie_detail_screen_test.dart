import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:showtracker/core/database/app_database.dart';
import 'package:showtracker/core/router/app_router.dart';
import 'package:showtracker/features/movies/data/models/tmdb_movie_detail.dart';
import 'package:showtracker/features/movies/providers/movies_providers.dart';

import '../../../support/app_test_harness.dart';

void main() {
  for (final confirm in [false, true]) {
    testWidgets('rimozione film: conferma=$confirm', (tester) async {
      final app =
          (await tester.runAsync(() => AppTestHarness.create(overrides: [
                movieDetailProvider(42).overrideWith((ref) async =>
                    const TmdbMovieDetail(
                        id: 42, title: 'Film locale', genres: [])),
              ])))!;
      addTearDown(() => app.dispose(tester));
      await tester.runAsync(() => app.db.moviesDao.insertMovie(
            TrackedMoviesCompanion(
              tmdbId: const Value(42),
              title: const Value('Film locale'),
              status: const Value(MediaStatus.planToWatch),
              addedAt: Value(DateTime(2026, 1, 1)),
            ),
          ));
      app.container.listen(trackedMoviesProvider, (_, __) {});
      await tester
          .runAsync(() => app.container.read(trackedMoviesProvider.future));
      await app.pump(tester);
      app.container.read(appRouterProvider).push('/movies/detail/42');
      await app.flush(tester);
      await tester.scrollUntilVisible(find.text('Rimuovi dalla libreria'), 250,
          scrollable: find.byType(Scrollable).last);
      await tester.tap(find.text('Rimuovi dalla libreria'));
      await app.flush(tester);
      expect(find.text('Rimuovi film?'), findsOneWidget);
      await tester.tap(find.text(confirm ? 'Rimuovi' : 'Annulla'));
      await app.flush(tester);
      final movie =
          await tester.runAsync(() => app.db.moviesDao.getByTmdbId(42));
      expect(movie, confirm ? isNull : isNotNull);
      expect(find.text('Rimuovi film?'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
