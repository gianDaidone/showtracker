import 'package:drift/drift.dart' hide isNull;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:showtracker/core/database/app_database.dart';
import 'package:showtracker/features/movies/providers/movies_providers.dart';

import '../../../support/app_test_harness.dart';

void main() {
  testWidgets('segna film visto una sola volta e aggiorna la lista dal DB',
      (tester) async {
    final app = (await tester.runAsync(AppTestHarness.create))!;
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
    await tester.runAsync(
      () => app.container.read(trackedMoviesProvider.future),
    );
    await app.pump(tester);
    await tester.tap(find.text('Film').last);
    await app.flush(tester);
    expect(find.text('Film locale'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.check));
    await tester.tap(find.byIcon(Icons.check));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 700));
    await app.flush(tester);
    final movie = await tester.runAsync(() => app.db.moviesDao.getByTmdbId(42));
    expect(movie!.status, MediaStatus.completed);
    expect(find.text('Film locale'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
