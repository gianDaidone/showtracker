import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:showtracker/app.dart';
import 'package:showtracker/core/auth/auth_state.dart';
import 'package:showtracker/core/auth/rawg_auth_state.dart';
import 'package:showtracker/core/database/app_database.dart';
import 'package:showtracker/core/database/database_provider.dart';
import 'package:showtracker/core/riverpod_utils.dart';
import 'package:showtracker/core/services/startup_coordinator.dart';
import 'package:showtracker/core/router/app_router.dart';
import 'package:showtracker/features/games/data/rawg_service.dart';
import 'package:showtracker/features/games/providers/games_providers.dart';
import 'package:showtracker/features/series/data/tmdb_service.dart';
import 'package:showtracker/features/series/providers/series_providers.dart';
import 'package:showtracker/features/update/providers/update_providers.dart';

class TestAuthController extends AuthController {
  TestAuthController(this.initial);
  final AuthState initial;

  @override
  Future<AuthState> build() async => initial;

  @override
  Future<void> loginWithManualKey(String apiKey) async {
    state = AsyncData(AuthenticatedWithManualKey(apiKey));
  }

  @override
  Future<void> logout() async {
    state = const AsyncData(Unauthenticated());
  }
}

class _NoStartupReschedule extends TrackedShowsNotifier {
  @override
  Future<void> rescheduleAllNotifications() async {}
}

/// Real DAO streams and routing, isolated from disk, network and platform setup.
class AppTestHarness {
  AppTestHarness._(this.db, this.container, this.client);

  final AppDatabase db;
  final ProviderContainer container;
  final http.Client client;

  static Future<AppTestHarness> create({
    AuthState auth = const AuthenticatedWithManualKey('test-key'),
    bool rescheduleAtStartup = false,
    TmdbService? tmdbService,
    RawgService? rawgService,
    RawgAuthState rawgAuth = const RawgUnauthenticated(),
    List<Override> overrides = const [],
  }) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.customSelect('SELECT 1').get();
    final client = MockClient((request) async {
      throw StateError('Unexpected HTTP request: ${request.url}');
    });
    final container = ProviderContainer(
      retry: noProviderRetry,
      overrides: [
        databaseProvider.overrideWithValue(db),
        authControllerProvider.overrideWith(() => TestAuthController(auth)),
        rawgAuthControllerProvider.overrideWithBuild(
          (ref, notifier) async => rawgAuth,
        ),
        tmdbServiceProvider
            .overrideWithValue(tmdbService ?? TmdbService(client)),
        rawgServiceProvider
            .overrideWithValue(rawgService ?? RawgService(client)),
        packageInfoProvider.overrideWith((ref) async => PackageInfo(
              appName: 'ShowTracker',
              packageName: 'test.showtracker',
              version: '1.1.0',
              buildNumber: '6',
            )),
        if (!rescheduleAtStartup)
          trackedShowsProvider.overrideWith(_NoStartupReschedule.new),
        ...overrides,
      ],
    );
    await container.read(authControllerProvider.future);
    container.listen(trackedShowsProvider, (_, __) {});
    await container.read(trackedShowsProvider.future);
    final app = AppTestHarness._(db, container, client);
    if (rescheduleAtStartup) {
      app._startup = StartupCoordinator(
        container,
        setupWidgets: () async {},
        requestPermission: () async {},
        refreshWidgets: () async {},
      );
    }
    return app;
  }

  StartupCoordinator? _startup;

  Future<void> pump(WidgetTester tester) async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startup?.start();
    });
    final widget = UncontrolledProviderScope(
      container: container,
      child: const ShowTrackerApp(),
    );
    if (_startup != null) {
      // Solo il bootstrap avvia la manutenzione nel primo frame: la relativa
      // transazione SQLite deve partire fuori dal fake clock del runner.
      await tester.runAsync(() => tester.pumpWidget(widget));
    } else {
      await tester.pumpWidget(widget);
    }
    await flush(tester);
  }

  /// SQLite completion runs outside widget fake time; animations stay bounded.
  Future<void> flush(WidgetTester tester) async {
    await tester.runAsync(() async {
      await container.read(trackedShowsProvider.future);
      await db.customSelect('SELECT 1').get();
    });
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      await tester.runAsync(() => Future<void>.value());
    }
  }

  Future<void> dispose(WidgetTester tester) async {
    final router = container.read(appRouterProvider);
    await tester.pumpWidget(const SizedBox.shrink());
    router.dispose();
    container.dispose();
    client.close();
    await tester.runAsync(db.close);
    await tester.pump();
  }
}
