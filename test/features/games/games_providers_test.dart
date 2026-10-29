import 'dart:async';
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:showtracker/core/database/app_database.dart';
import 'package:showtracker/core/database/database_provider.dart';
import 'package:showtracker/core/riverpod_utils.dart';
import 'package:showtracker/features/games/data/models/rawg_game_detail.dart';
import 'package:showtracker/features/games/providers/games_providers.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;
  const detail = RawgGameDetail(
    id: 100,
    slug: 'gioco',
    name: 'Gioco',
    backgroundImage: 'https://example.test/cover.jpg',
    released: '2035-12-07',
    rating: 4.2,
    playtime: 20,
    platforms: ['PC', 'PlayStation 5'],
  );
  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(retry: noProviderRetry, overrides: [
      databaseProvider.overrideWithValue(db),
    ]);
    // Riverpod 3 mette in pausa gli stream senza listener, anche keepAlive.
    container.listen(trackedGamesProvider, (_, __) {});
    await container.read(trackedGamesProvider.future);
  });
  tearDown(() async {
    container.dispose();
    await db.close();
  });

  test('CRUD notifier scrive metadati e notifica stream locale senza RAWG',
      () async {
    final notifier = container.read(trackedGamesProvider.notifier);
    expect(await container.read(trackedGamesProvider.future), isEmpty);
    final added = Completer<List<TrackedGame>>();
    final removed = Completer<List<TrackedGame>>();
    var sawGame = false;
    final sub = container.listen(trackedGamesProvider, (_, state) {
      final games = state.value;
      if (games == null) return;
      if (games.isNotEmpty) {
        sawGame = true;
        if (!added.isCompleted) added.complete(games);
      } else if (sawGame && !removed.isCompleted) {
        removed.complete(games);
      }
    });
    addTearDown(sub.close);
    await notifier.addGame(detail);
    final streamed = (await added.future).single;
    final game = (await db.gamesDao.getByRawgId(100))!;
    expect(streamed.id, game.id);
    expect(game.coverUrl, detail.backgroundImage);
    expect(game.releaseDate, DateTime(2035, 12, 7));
    expect(game.playtime, 20);
    expect(jsonDecode(game.platforms!), ['PC', 'PlayStation 5']);
    expect(game.voteAverage, 8.4);
    expect(game.userRating, isNull);
    expect(game.status, MediaStatus.planToWatch);
    await notifier.updateStatus(game.id, MediaStatus.watching);
    expect((await db.gamesDao.getByRawgId(100))!.status, MediaStatus.watching);
    await notifier.removeGame(game.id);
    expect(await db.gamesDao.getByRawgId(100), isNull);
    expect(await removed.future, isEmpty);
  });

  test('completato, abbandonato e backlog non conservano voti incompatibili',
      () async {
    final notifier = container.read(trackedGamesProvider.notifier);
    await notifier.addGame(detail);
    final id = (await db.gamesDao.getByRawgId(100))!.id;
    await notifier.markPlayed(id, 9.5);
    var game = (await db.gamesDao.getByRawgId(100))!;
    expect(game.status, MediaStatus.completed);
    expect(game.userRating, 9.5);
    await notifier.markFolded(id);
    game = (await db.gamesDao.getByRawgId(100))!;
    expect(game.status, MediaStatus.dropped);
    expect(game.userRating, isNull);
    await notifier.markPlayed(id, 7);
    await notifier.resetToBacklog(id);
    game = (await db.gamesDao.getByRawgId(100))!;
    expect(game.status, MediaStatus.planToWatch);
    expect(game.userRating, isNull);
    expect(game.voteAverage, 8.4); // Rating RAWG non è quello personale.
  });

  test('aggiunta ripetuta non azzera progressi e voto già salvati', () async {
    final notifier = container.read(trackedGamesProvider.notifier);
    await notifier.addGame(detail);
    final original = (await db.gamesDao.getByRawgId(100))!;
    await notifier.markPlayed(original.id, 8);
    await notifier.addGame(detail);
    final saved = (await db.gamesDao.getByRawgId(100))!;
    expect(saved.id, original.id);
    expect(saved.addedAt, original.addedAt);
    expect(saved.status, MediaStatus.completed);
    expect(saved.userRating, 8);
    expect(await db.gamesDao.watchAll().first, hasLength(1));
  });

  test('metadati opzionali assenti non diventano JSON vuoto o voto zero',
      () async {
    await container.read(trackedGamesProvider.notifier).addGame(
          const RawgGameDetail(id: 101, slug: 'annunciato', name: 'Annunciato'),
        );
    final game = (await db.gamesDao.getByRawgId(101))!;
    expect(game.coverUrl, isNull);
    expect(game.releaseDate, isNull);
    expect(game.playtime, isNull);
    expect(game.platforms, isNull);
    expect(game.voteAverage, isNull);
  });
}
