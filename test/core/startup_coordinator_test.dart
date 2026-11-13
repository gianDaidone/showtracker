import 'dart:async';

import 'package:drift/native.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:showtracker/core/auth/auth_state.dart';
import 'package:showtracker/core/database/app_database.dart';
import 'package:showtracker/core/database/database_provider.dart';
import 'package:showtracker/core/riverpod_utils.dart';
import 'package:showtracker/core/services/startup_coordinator.dart';

import '../support/app_test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  late ProviderContainer container;

  Future<void> create(AuthState auth) async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.customSelect('SELECT 1').get();
    container = ProviderContainer(retry: noProviderRetry, overrides: [
      databaseProvider.overrideWithValue(db),
      authControllerProvider.overrideWith(() => TestAuthController(auth)),
    ]);
    await container.read(authControllerProvider.future);
  }

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  test('bootstrap idempotente: widget indipendenti dal prompt', () async {
    await create(const AuthenticatedWithManualKey('test-only'));
    final permission = Completer<void>();
    final widgetReady = Completer<void>();
    var setups = 0;
    var requests = 0;
    var scans = 0;
    final startup = StartupCoordinator(
      container,
      setupWidgets: () async {
        setups++;
      },
      requestPermission: () {
        requests++;
        return permission.future;
      },
      refreshWidgets: () async {
        if (!widgetReady.isCompleted) widgetReady.complete();
      },
      refreshMetadata: () async {
        scans++;
      },
    );
    final first = startup.start();
    expect(identical(first, startup.start()), isTrue);
    await widgetReady.future;
    expect(setups, 1);
    expect(requests, 1);
    expect(scans, 0);
    permission.complete();
    await first;
    expect(scans, 1);
    await startup.start();
    expect(scans, 1);
  });

  test('cache-only episode update queues home widget refresh', () async {
    await create(const Unauthenticated());
    final id = await db.showsDao.insertShow(TrackedShowsCompanion.insert(
      tmdbId: 42,
      title: 'Serie locale',
      status: MediaStatus.watching,
      addedAt: DateTime(2020),
    ));
    await db.showsDao.insertSeasons(id, {1: 1});
    await db.cacheDao.saveSeasonEpisodes([
      CachedEpisodesCompanion.insert(
          tmdbShowId: 42,
          seasonNumber: 1,
          episodeNumber: 1,
          name: 'Senza data',
          cachedAt: DateTime.now()),
    ]);
    final initial = Completer<void>();
    Completer<void>? changed;
    final startup = StartupCoordinator(
      container,
      setupWidgets: () async {},
      requestPermission: () async {},
      refreshMetadata: () async {},
      refreshWidgets: () async {
        if (!initial.isCompleted) initial.complete();
        final pending = changed;
        if (pending != null && !pending.isCompleted) pending.complete();
      },
    );
    await startup.start();
    await initial.future;
    await container.pump();
    changed = Completer<void>();
    await db.cacheDao.saveSeasonEpisodes([
      CachedEpisodesCompanion.insert(
          tmdbShowId: 42,
          seasonNumber: 1,
          episodeNumber: 1,
          name: 'Uscito',
          airDate: const Value('2020-01-01'),
          cachedAt: DateTime.now()),
    ]);
    await changed.future.timeout(const Duration(seconds: 5));
  });

  test('nessun worker prima del login; primo login lo avvia una volta',
      () async {
    await create(const Unauthenticated());
    final scanned = Completer<void>();
    var scans = 0;
    final startup = StartupCoordinator(
      container,
      setupWidgets: () async {},
      requestPermission: () async {},
      refreshWidgets: () async {},
      refreshMetadata: () async {
        scans++;
        if (!scanned.isCompleted) scanned.complete();
      },
    );
    await startup.start();
    expect(scans, 0);
    await container
        .read(authControllerProvider.notifier)
        .loginWithManualKey('test-only');
    await scanned.future;
    expect(scans, 1);
    await container
        .read(authControllerProvider.notifier)
        .loginWithManualKey('test-only-2');
    await container.pump();
    expect(scans, 1);
  });
}
