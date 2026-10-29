import 'package:drift/drift.dart' hide isNull;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:showtracker/core/database/app_database.dart';
import 'package:showtracker/core/theme/app_theme.dart';
import 'package:showtracker/features/series/presentation/widgets/episode_detail_sheet.dart';

import '../../../support/app_test_harness.dart';

void main() {
  for (final choice in ['Solo questo', 'Segna tutti i precedenti', 'dismiss']) {
    testWidgets('conferma episodi precedenti: $choice', (tester) async {
      final app = (await tester.runAsync(AppTestHarness.create))!;
      addTearDown(() => app.dispose(tester));
      final showId = (await tester.runAsync(() async {
        final id = await app.db.showsDao.insertShow(TrackedShowsCompanion(
          tmdbId: const Value(42),
          title: const Value('Serie locale'),
          status: const Value(MediaStatus.watching),
          addedAt: Value(DateTime(2026, 1, 1)),
        ));
        await app.db.showsDao.insertSeasons(id, {1: 3});
        return id;
      }))!;
      Future<void>? action;
      await tester.pumpWidget(UncontrolledProviderScope(
        container: app.container,
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(body: Consumer(builder: (context, ref, child) {
            return TextButton(
              onPressed: () {
                action = markEpisodeWatchedWithCheck(context, ref,
                    showId: showId, targetSeason: 1, targetEpisode: 3);
              },
              child: const Text('Segna episodio'),
            );
          })),
        ),
      ));
      await tester.runAsync(() => tester.tap(find.text('Segna episodio')));
      await app.flush(tester);
      expect(find.text('Episodi precedenti'), findsOneWidget);
      if (choice == 'dismiss') {
        await tester.tapAt(const Offset(5, 5));
      } else {
        await tester.tap(find.text(choice));
      }
      await app.flush(tester);
      await tester.runAsync(() => action!);
      final episodes = await tester.runAsync(
        () => app.db.showsDao.getEpisodesByShow(showId),
      );
      expect(
        episodes!.where((e) => e.watched).map((e) => e.episodeNumber),
        choice == 'dismiss'
            ? isEmpty
            : choice == 'Solo questo'
                ? [3]
                : [1, 2, 3],
      );
      expect(tester.takeException(), isNull);
    });
  }
}
