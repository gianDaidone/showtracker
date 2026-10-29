import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:showtracker/app.dart';
import 'package:showtracker/core/auth/auth_state.dart';
import 'package:showtracker/core/auth/rawg_auth_state.dart';
import 'package:showtracker/core/database/app_database.dart';
import 'package:showtracker/core/database/database_provider.dart';
import 'package:showtracker/core/riverpod_utils.dart';
import 'package:showtracker/core/router/app_router.dart';
import 'package:showtracker/features/movies/presentation/movies_screen.dart';
import 'package:showtracker/features/series/presentation/next_episodes_screen.dart';
import 'package:showtracker/features/series/providers/series_providers.dart';

class _NoStartupReschedule extends TrackedShowsNotifier {
  @override
  Future<void> rescheduleAllNotifications() async {}
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('avvio e navigazione Android con archivio isolato',
      (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.customSelect('SELECT 1').get();
    final container = ProviderContainer(
      retry: noProviderRetry,
      overrides: [
        databaseProvider.overrideWithValue(db),
        authControllerProvider.overrideWithBuild(
          (ref, notifier) async => const AuthenticatedWithManualKey('test-key'),
        ),
        rawgAuthControllerProvider.overrideWithBuild(
          (ref, notifier) async => const RawgUnauthenticated(),
        ),
        trackedShowsProvider.overrideWith(_NoStartupReschedule.new),
      ],
    );
    await container.read(authControllerProvider.future);
    final router = container.read(appRouterProvider);
    try {
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: const ShowTrackerApp(),
      ));
      await tester.pumpAndSettle();
      expect(find.byType(NextEpisodesScreen), findsOneWidget);
      expect(find.text('Nessuna serie in visione'), findsOneWidget);

      await db.moviesDao.insertMovie(TrackedMoviesCompanion(
        tmdbId: const Value(42),
        title: const Value('Film locale di prova'),
        status: const Value(MediaStatus.planToWatch),
        addedAt: Value(DateTime(2026, 1, 1)),
      ));
      await tester.tap(find.text('Film').last);
      await tester.pumpAndSettle();
      expect(find.byType(MoviesScreen), findsOneWidget);
      expect(find.text('Film locale di prova'), findsOneWidget);
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      router.dispose();
      container.dispose();
      await db.close();
    }
  });
}
