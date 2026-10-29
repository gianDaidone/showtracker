import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:showtracker/core/database/app_database.dart';
import 'package:showtracker/core/database/database_provider.dart';
import 'package:showtracker/core/riverpod_utils.dart';
import 'package:showtracker/features/games/data/rawg_service.dart';
import 'package:showtracker/features/games/providers/games_providers.dart';
import 'package:showtracker/features/movies/providers/movies_providers.dart';
import 'package:showtracker/features/search/data/discover_rules.dart';
import 'package:showtracker/features/search/providers/discover_providers.dart';
import 'package:showtracker/features/series/data/tmdb_service.dart';
import 'package:showtracker/features/series/providers/series_providers.dart';

enum _Domain { shows, movies, games }

void main() {
  late AppDatabase db;
  late ProviderContainer container;
  late MockClient client;
  late List<http.Request> requests;
  late Set<int> failingSeeds;
  late Set<int> emptySeeds;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    requests = [];
    failingSeeds = {};
    emptySeeds = {};
    client = MockClient((request) async {
      requests.add(request);
      final segments = request.url.pathSegments;
      final seed =
          request.url.path == '/api/games' ? null : int.parse(segments[2]);
      if (seed != null && failingSeeds.contains(seed)) {
        return http.Response('offline simulato', 503);
      }
      if (request.url.path.startsWith('/api/games/')) {
        return http.Response(
            jsonEncode({
              'id': seed,
              'name': 'Gioco $seed',
              'genres': emptySeeds.contains(seed)
                  ? []
                  : [
                      {'id': 4, 'name': 'Action'},
                      {'id': 51, 'name': 'Indie'},
                    ],
            }),
            200);
      }
      final ids = seed == null
          ? [40, 41, 42]
          : emptySeeds.contains(seed)
              ? <int>[]
              : [40, seed == 1 ? 41 : 42];
      return http.Response(
          jsonEncode({
            'page': 1,
            'total_pages': 1,
            'count': 3,
            'next': seed == null && request.url.queryParameters['page'] == '1'
                ? 'next'
                : null,
            'results': [
              for (final id in ids)
                {
                  'id': id,
                  'name': 'Titolo $id',
                  'title': 'Titolo $id',
                  'slug': 'title-$id'
                }
            ],
          }),
          200);
    });
    container = ProviderContainer(retry: noProviderRetry, overrides: [
      databaseProvider.overrideWithValue(db),
      tmdbServiceProvider.overrideWithValue(TmdbService(client)),
      rawgServiceProvider.overrideWithValue(RawgService(client)),
    ]);
  });

  tearDown(() async {
    container.dispose();
    client.close();
    await db.close();
  });

  Future<void> seed(_Domain domain, {int count = 2}) async {
    final date = DateTime.utc(2026, 10, 1);
    for (var id = 1; id <= count; id++) {
      switch (domain) {
        case _Domain.shows:
          await db.showsDao.insertShow(TrackedShowsCompanion.insert(
            tmdbId: id,
            title: 'Serie $id',
            status: MediaStatus.completed,
            addedAt: date,
            userRating: Value(10.0 - id),
          ));
        case _Domain.movies:
          await db.moviesDao.insertMovie(TrackedMoviesCompanion.insert(
            tmdbId: id,
            title: 'Film $id',
            status: MediaStatus.completed,
            addedAt: date,
            userRating: Value(10.0 - id),
          ));
        case _Domain.games:
          await db.gamesDao.insertGame(TrackedGamesCompanion.insert(
            rawgId: id,
            title: 'Gioco $id',
            status: MediaStatus.completed,
            addedAt: date,
            userRating: Value(10.0 - id),
          ));
      }
    }
  }

  ProviderSubscription<dynamic> listen(_Domain domain) {
    // Come la libreria montata nell'app: .future da solo non mantiene attivo
    // lo stream Riverpod 3. Si avvia dopo il seeding per leggere il DB aggiornato.
    switch (domain) {
      case _Domain.shows:
        container.listen(trackedShowsProvider, (_, __) {});
        return container.listen(
            showDiscoverProvider(DiscoverList.forYou), (_, __) {});
      case _Domain.movies:
        container.listen(trackedMoviesProvider, (_, __) {});
        return container.listen(
            movieDiscoverProvider(DiscoverList.forYou), (_, __) {});
      case _Domain.games:
        container.listen(trackedGamesProvider, (_, __) {});
        return container.listen(
            gameDiscoverProvider(DiscoverList.forYou), (_, __) {});
    }
  }

  Future<List<int>> load(_Domain domain) async => switch (domain) {
        _Domain.shows => (await container
                .readFuture(showDiscoverProvider(DiscoverList.forYou).future))
            .items
            .map((x) => x.id)
            .toList(),
        _Domain.movies => (await container
                .readFuture(movieDiscoverProvider(DiscoverList.forYou).future))
            .items
            .map((x) => x.id)
            .toList(),
        _Domain.games => (await container
                .readFuture(gameDiscoverProvider(DiscoverList.forYou).future))
            .items
            .map((x) => x.id)
            .toList(),
      };

  for (final domain in _Domain.values) {
    group(domain.name, () {
      test('senza semi non chiama alcuna API', () async {
        final listener = listen(domain);
        addTearDown(listener.close);
        expect(await load(domain), isEmpty);
        expect(requests, isEmpty);
      });

      test('un seme fallito non nasconde i consigli riusciti', () async {
        await seed(domain);
        failingSeeds = {2};
        final listener = listen(domain);
        addTearDown(listener.close);
        expect(await load(domain),
            domain == _Domain.games ? [40, 41, 42] : [40, 41]);
        expect(
            requests.where((r) =>
                r.url.path.endsWith('/2') ||
                r.url.path.contains('/2/recommendations')),
            hasLength(1));
      });

      test('tutti i semi falliti espongono errore senza retry automatico',
          () async {
        await seed(domain);
        failingSeeds = {1, 2};
        final listener = listen(domain);
        addTearDown(listener.close);
        await expectLater(
            load(domain),
            throwsA(domain == _Domain.games
                ? isA<RawgException>()
                : isA<TmdbException>()));
        await container.pump();
        expect(requests, hasLength(2));
        expect(requests.any((r) => r.url.path == '/api/games'), isFalse);
      });

      test(
          'un risultato vuoto riuscito non viene scambiato per fallimento totale',
          () async {
        await seed(domain);
        failingSeeds = {1};
        emptySeeds = {2};
        final listener = listen(domain);
        addTearDown(listener.close);
        expect(await load(domain), isEmpty);
        expect(requests, hasLength(2));
      });

      test('deduplica e riusa i risultati riaprendo il provider', () async {
        await seed(domain);
        var listener = listen(domain);
        final first = await load(domain);
        expect(first, [40, 41, 42]);
        expect(first.toSet(), hasLength(first.length));
        final count = requests.length;
        listener.close();
        await container.pump();
        listener = listen(domain);
        addTearDown(listener.close);
        expect(await load(domain), first);
        expect(requests, hasLength(count));
      });

      test('limita il numero di semi alle quote previste', () async {
        await seed(domain, count: 7);
        final listener = listen(domain);
        addTearDown(listener.close);
        await load(domain);
        final seedRequests =
            requests.where((r) => r.url.path != '/api/games').toList();
        final limit = domain == _Domain.games ? 3 : 5;
        expect(seedRequests, hasLength(limit));
        expect(
            seedRequests.map((r) => int.parse(r.url.pathSegments[2])).toSet(),
            {for (var id = 1; id <= limit; id++) id});
      });
    });
  }

  test('giochi riusano i generi dei semi nelle pagine successive', () async {
    await seed(_Domain.games, count: 3);
    final listener = listen(_Domain.games);
    addTearDown(listener.close);
    await load(_Domain.games);
    await container
        .read(gameDiscoverProvider(DiscoverList.forYou).notifier)
        .loadMore();
    expect(requests.where((r) => r.url.path.startsWith('/api/games/')),
        hasLength(3));
    final pages = requests.where((r) => r.url.path == '/api/games').toList();
    expect(pages, hasLength(2));
    expect(pages.map((r) => r.url.queryParameters['page']), ['1', '2']);
    expect(pages.map((r) => r.url.queryParameters['genres']), ['4,51', '4,51']);
    expect(pages.every((r) => r.url.queryParameters['ordering'] == '-added'),
        isTrue);
    expect(
        container
            .read(gameDiscoverProvider(DiscoverList.forYou))
            .requireValue
            .items
            .map((g) => g.id),
        [40, 41, 42]);
  });
}
