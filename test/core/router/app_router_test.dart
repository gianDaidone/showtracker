import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:showtracker/core/auth/auth_state.dart';
import 'package:showtracker/core/database/app_database.dart';
import 'package:showtracker/core/router/app_router.dart';
import 'package:showtracker/features/games/presentation/games_screen.dart';
import 'package:showtracker/features/movies/presentation/movies_screen.dart';
import 'package:showtracker/features/onboarding/presentation/onboarding_screen.dart';
import 'package:showtracker/features/series/presentation/next_episodes_screen.dart';
import 'package:showtracker/features/movies/providers/movies_providers.dart';
import 'package:showtracker/features/update/providers/update_providers.dart';
import 'package:showtracker/features/settings/presentation/privacy_info_screen.dart';
import 'package:showtracker/features/settings/presentation/settings_screen.dart';

import '../../support/app_test_harness.dart';

void main() {
  const links = MethodChannel('com.llfbandit.app_links/events');
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(links, (_) async => null);
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(links, null);
  });

  Future<AppTestHarness> mount(WidgetTester tester,
      {bool loggedIn = true}) async {
    final app = (await tester.runAsync(() => AppTestHarness.create(
          auth: loggedIn
              ? const AuthenticatedWithManualKey('test-key')
              : const Unauthenticated(),
        )))!;
    addTearDown(() => app.dispose(tester));
    await app.pump(tester);
    return app;
  }

  testWidgets('senza credenziali mostra onboarding e protegge le route',
      (tester) async {
    final app = await mount(tester, loggedIn: false);
    expect(find.byType(OnboardingScreen), findsOneWidget);
    app.container.read(appRouterProvider).go('/movies');
    await app.flush(tester);
    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.byType(MoviesScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('login e logout aggiornano la route senza perdere la libreria',
      (tester) async {
    final app = await mount(tester, loggedIn: false);
    await tester.runAsync(() => app.db.moviesDao.insertMovie(
          TrackedMoviesCompanion(
            tmdbId: const Value(42),
            title: const Value('Film locale'),
            status: const Value(MediaStatus.planToWatch),
            addedAt: Value(DateTime(2026, 1, 1)),
          ),
        ));
    final auth = app.container.read(authControllerProvider.notifier);
    await auth.loginWithManualKey('test-key');
    await app.flush(tester);
    expect(find.byType(NextEpisodesScreen), findsOneWidget);
    await auth.logout();
    await app.flush(tester);
    expect(find.byType(OnboardingScreen), findsOneWidget);
    final movies =
        await tester.runAsync(() => app.db.moviesDao.watchAll().first);
    expect(movies!.single.title, 'Film locale');
    expect(tester.takeException(), isNull);
  });

  testWidgets('i tab aprono le sezioni corrette e preservano il ritorno',
      (tester) async {
    final app = await mount(tester);
    await tester.tap(find.text('Film').last);
    await app.flush(tester);
    expect(find.byType(MoviesScreen), findsOneWidget);
    await tester.tap(find.text('Giochi').last);
    await app.flush(tester);
    expect(find.byType(GamesScreen), findsOneWidget);
    await tester.tap(find.text('Profilo').last);
    await app.flush(tester);
    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(find.text('Nessun titolo nella libreria'), findsOneWidget);
    expect(find.text('Connesso con API Key'), findsOneWidget);
    await tester.tap(find.text('Serie').last);
    await app.flush(tester);
    expect(find.byType(NextEpisodesScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('profilo aggiorna i conteggi senza cercare aggiornamenti',
      (tester) async {
    final app = await mount(tester);
    expect(app.container.exists(githubReleaseServiceProvider), isFalse);
    await tester.tap(find.text('Profilo').last);
    await app.flush(tester);
    expect(find.text('0 serie · 0 film · 0 giochi'), findsNothing);
    expect(find.text('Nessun titolo nella libreria'), findsOneWidget);
    await tester.runAsync(() => app.db.moviesDao.insertMovie(
          TrackedMoviesCompanion(
            tmdbId: const Value(42),
            title: const Value('Film locale'),
            status: const Value(MediaStatus.planToWatch),
            addedAt: Value(DateTime(2026, 1, 1)),
          ),
        ));
    await tester
        .runAsync(() => app.container.read(trackedMoviesProvider.future));
    await app.flush(tester);
    expect(find.text('0 serie · 1 film · 0 giochi'), findsOneWidget);
    expect(app.container.exists(githubReleaseServiceProvider), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pagina privacy full screen torna al profilo', (tester) async {
    final app = await mount(tester);
    await tester.tap(find.text('Profilo').last);
    await app.flush(tester);
    app.container.read(appRouterProvider).push('/privacy');
    await app.flush(tester);
    expect(find.byType(PrivacyInfoScreen), findsOneWidget);
    app.container.read(appRouterProvider).pop();
    await app.flush(tester);
    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'onboarding su schermo basso lascia raggiungibili tutte le opzioni',
      (tester) async {
    final app = await mount(tester, loggedIn: false);
    await tester.ensureVisible(find.text('Attiva Modulo Videogiochi'));
    await app.flush(tester);
    expect(
        find.text('Attiva Modulo Videogiochi').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('autenticato non resta nella pagina di onboarding',
      (tester) async {
    final app = await mount(tester);
    app.container.read(appRouterProvider).go('/onboarding');
    await app.flush(tester);
    expect(find.byType(NextEpisodesScreen), findsOneWidget);
    expect(find.byType(OnboardingScreen), findsNothing);
  });
}
