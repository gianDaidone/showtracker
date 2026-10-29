import 'package:drift/drift.dart' hide isNull;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:showtracker/core/database/app_database.dart';
import 'package:showtracker/features/series/data/models/tmdb_episode.dart';
import 'package:showtracker/features/series/data/models/tmdb_season.dart';
import 'package:showtracker/features/series/data/models/tmdb_show_detail.dart';
import 'package:showtracker/features/series/presentation/widgets/next_episode_card.dart';
import 'package:showtracker/features/series/providers/series_providers.dart';

import '../../../support/app_test_harness.dart';

void main() {
  testWidgets('Da Vedere conta le card e il visto aggiorna progressi e lista',
      (tester) async {
    const episode = TmdbEpisode(
        episodeNumber: 1, name: 'Primo episodio', airDate: '2020-01-01');
    const season =
        TmdbSeason(seasonNumber: 1, episodeCount: 1, episodes: [episode]);
    const detail = TmdbShowDetail(
      id: 42,
      name: 'Serie locale',
      inProduction: true,
      numberOfSeasons: 1,
      numberOfEpisodes: 1,
      genres: [],
      originCountries: [],
      seasons: [season],
    );
    final app = (await tester.runAsync(() => AppTestHarness.create(overrides: [
          showDetailProvider(42).overrideWith((ref) async => detail),
          seasonDetailProvider(showId: 42, seasonNumber: 1)
              .overrideWith((ref) async => season),
        ])))!;
    addTearDown(() => app.dispose(tester));
    final id = (await tester.runAsync(() async {
      final id = await app.db.showsDao.insertShow(TrackedShowsCompanion(
        tmdbId: const Value(42),
        title: const Value('Serie locale'),
        status: const Value(MediaStatus.watching),
        totalEpisodes: const Value(1),
        totalSeasons: const Value(1),
        addedAt: Value(DateTime.now()),
      ));
      await app.db.showsDao.insertSeasons(id, {1: 1});
      await app.db.cacheDao.saveSeasonEpisodes([
        CachedEpisodesCompanion.insert(
          tmdbShowId: 42,
          seasonNumber: 1,
          episodeNumber: 1,
          name: episode.name,
          airDate: Value(episode.airDate),
          cachedAt: DateTime.now(),
        ),
      ]);
      return id;
    }))!;
    await app.pump(tester);
    expect(find.text('Da Vedere (1)'), findsOneWidget);
    expect(find.byType(NextEpisodeCard), findsOneWidget);
    expect(find.text('Primo episodio'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.check));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 699));
    // La scadenza del timer avvia SQLite: eseguila nel contesto asincrono reale,
    // come gli altri accessi al DB, senza lasciare I/O nella zona del fake clock.
    await tester.runAsync(() => tester.pump(const Duration(milliseconds: 1)));
    await app.flush(tester);
    final episodes =
        await tester.runAsync(() => app.db.showsDao.getEpisodesByShow(id));
    expect(episodes!.where((e) => e.watched).map((e) => e.episodeNumber), [1]);
    expect(find.byType(NextEpisodeCard), findsNothing);
    expect(find.text('Da Vedere (1)'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
