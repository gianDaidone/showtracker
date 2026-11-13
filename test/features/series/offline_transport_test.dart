import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:showtracker/core/database/app_database.dart';
import 'package:showtracker/core/database/database_provider.dart';
import 'package:showtracker/core/riverpod_utils.dart';
import 'package:showtracker/features/series/data/tmdb_service.dart';
import 'package:showtracker/features/series/providers/series_providers.dart';

void main() {
  test('cold DNS failure still exposes tracked local detail and cached season',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final client = MockClient(
        (_) async => throw http.ClientException('Failed host lookup'));
    final container = ProviderContainer(retry: noProviderRetry, overrides: [
      databaseProvider.overrideWithValue(db),
      tmdbServiceProvider.overrideWithValue(TmdbService(client)),
    ]);
    addTearDown(() async {
      container.dispose();
      client.close();
      await db.close();
    });
    final id = await db.showsDao.insertShow(TrackedShowsCompanion(
      tmdbId: const Value(42),
      title: const Value('Titolo salvato'),
      status: const Value(MediaStatus.watching),
      addedAt: Value(DateTime(2020)),
      totalEpisodes: const Value(2),
      totalSeasons: const Value(1),
    ));
    await db.showsDao.insertSeasons(id, {1: 2});
    await db.cacheDao.saveSeasonEpisodes([
      CachedEpisodesCompanion.insert(
          tmdbShowId: 42,
          seasonNumber: 1,
          episodeNumber: 1,
          name: 'Episodio offline',
          airDate: const Value('2020-01-01'),
          cachedAt: DateTime(2020)),
    ]);
    final detail = await container.readFuture(showDetailProvider(42).future);
    expect(detail.name, 'Titolo salvato');
    expect(detail.isLocalSnapshot, isTrue);
    final season = await container
        .readFuture(seasonDetailProvider(showId: 42, seasonNumber: 1).future);
    expect(season.isLocalSnapshot, isTrue);
    expect(season.episodes!.single.name, 'Episodio offline');
  });
}
