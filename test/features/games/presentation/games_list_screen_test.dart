import 'package:drift/drift.dart' hide isNull;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:showtracker/core/database/app_database.dart';
import 'package:showtracker/core/theme/app_theme.dart';
import 'package:showtracker/features/games/presentation/games_list_screen.dart';
import 'package:showtracker/features/games/providers/games_providers.dart';

import '../../../support/app_test_harness.dart';

void main() {
  testWidgets('libreria giochi filtra per titolo senza modificare i dati',
      (tester) async {
    final app = (await tester.runAsync(AppTestHarness.create))!;
    addTearDown(() => app.dispose(tester));
    await tester.runAsync(() async {
      for (final entry in [
        (1, 'Portal', MediaStatus.planToWatch),
        (2, 'Celeste', MediaStatus.completed)
      ]) {
        await app.db.gamesDao.insertGame(TrackedGamesCompanion(
          rawgId: Value(entry.$1),
          title: Value(entry.$2),
          status: Value(entry.$3),
          addedAt: Value(DateTime(2026, 1, entry.$1)),
        ));
      }
    });
    app.container.listen(trackedGamesProvider, (_, __) {});
    await tester
        .runAsync(() => app.container.read(trackedGamesProvider.future));
    await tester.pumpWidget(UncontrolledProviderScope(
      container: app.container,
      child: MaterialApp(theme: AppTheme.dark(), home: const GamesListScreen()),
    ));
    await app.flush(tester);
    expect(find.text('Portal'), findsOneWidget);
    expect(find.text('Celeste'), findsOneWidget);
    await tester.tap(find.byTooltip('Filtra giochi'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), '  pOrTaL  ');
    await app.flush(tester);
    expect(find.text('Portal'), findsOneWidget);
    expect(find.text('Celeste'), findsNothing);
    await tester.tap(find.byTooltip('Annulla'));
    await app.flush(tester);
    expect(find.text('Celeste'), findsOneWidget);
    final rows = await tester.runAsync(() => app.db.gamesDao.watchAll().first);
    expect(rows!.length, 2);
    expect(tester.takeException(), isNull);
  });
}
