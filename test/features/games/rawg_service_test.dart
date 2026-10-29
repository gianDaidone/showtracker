import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:showtracker/core/paged_search.dart';
import 'package:showtracker/core/riverpod_utils.dart';
import 'package:showtracker/features/games/data/models/rawg_game.dart';
import 'package:showtracker/features/games/data/rawg_service.dart';

Map<String, dynamic> _game(int id) =>
    {'id': id, 'name': 'Zelda $id', 'slug': 'zelda-$id'};

void main() {
  late List<http.Request> requests;
  late MockClient client;

  setUp(() => requests = []);
  tearDown(() => client.close());

  test('query corta non fa richieste; prima pagina fonde rilevanza e popolari',
      () async {
    client = MockClient((request) async {
      requests.add(request);
      final popular = request.url.queryParameters['search_precise'] == 'true';
      return http.Response(
          jsonEncode({
            'results': popular ? [_game(2), _game(3)] : [_game(1), _game(2)],
            'next': popular ? null : 'next-page',
            'count': popular ? 2 : 99,
          }),
          200);
    });
    final service = RawgService(client);
    expect((await service.searchGames('z')).items, isEmpty);
    expect(requests, isEmpty);
    final page = await service.searchGames('zelda');
    expect(page.items.map((g) => g.id).toSet(), {1, 2, 3});
    expect(page.items, hasLength(3));
    expect(page.hasMore, isTrue);
    expect(page.totalCount, 99);
    expect(requests, hasLength(2));
    for (final request in requests) {
      expect(request.url.host, 'api.rawg.io');
      expect(request.url.path, '/api/games');
      expect(request.url.queryParameters['search'], 'zelda');
      expect(request.url.queryParameters['page'], '1');
      expect(request.url.queryParameters['page_size'], '40');
      expect(request.url.queryParameters.containsKey('key'), isFalse);
    }
    expect(
        requests
            .singleWhere(
                (r) => r.url.queryParameters.containsKey('search_precise'))
            .url
            .queryParameters['ordering'],
        '-added');
  });

  test('pagine successive fanno una sola richiesta di rilevanza', () async {
    client = MockClient((request) async {
      requests.add(request);
      return http.Response(
          jsonEncode({
            'results': [_game(4)],
            'next': null,
            'count': 41
          }),
          200);
    });
    final page = await RawgService(client).searchGames('zelda', page: 2);
    expect(requests.single.url.queryParameters,
        {'search': 'zelda', 'page': '2', 'page_size': '40'});
    expect(page.items.single.id, 4);
    expect(page.hasMore, isFalse);
    expect(page.totalCount, 41);
  });

  test(
      'discovery conserva filtri date e generi e ferma il paging alla pagina 10',
      () async {
    client = MockClient((request) async {
      requests.add(request);
      final page = int.parse(request.url.queryParameters['page']!);
      return http.Response(
          jsonEncode({
            'results': [_game(page)],
            'next': 'always-more',
            'count': 2000
          }),
          200);
    });
    final service = RawgService(client);
    final provider = AsyncNotifierProvider.autoDispose<
        PagedListNotifier<RawgGame>, PagedResults<RawgGame>>(
      () => PagedListNotifier(
          (_) => (page) => service.discoverGames(
                ordering: '-added',
                dates: '2026-07-01,2026-10-01',
                genreIds: [4, 51],
                page: page,
              ),
          (g) => g.id),
    );
    final container = ProviderContainer(retry: noProviderRetry);
    addTearDown(container.dispose);
    container.listen(provider, (_, __) {});
    await container.read(provider.future);
    for (var i = 0; i < 15; i++) {
      await container.read(provider.notifier).loadMore();
    }
    expect(requests, hasLength(RawgService.discoverMaxPages));
    expect(requests.map((r) => int.parse(r.url.queryParameters['page']!)),
        orderedEquals(List.generate(10, (i) => i + 1)));
    for (final request in requests) {
      expect(request.url.queryParameters['dates'], '2026-07-01,2026-10-01');
      expect(request.url.queryParameters['genres'], '4,51');
      expect(request.url.queryParameters['ordering'], '-added');
      expect(request.url.queryParameters['page_size'], '40');
    }
    final state = container.read(provider).requireValue;
    expect(state.items, hasLength(10));
    expect(state.hasMore, isFalse);
    expect(state.totalCount, 2000);
  });

  test('discovery senza filtri non invia parametri vuoti', () async {
    client = MockClient((request) async {
      requests.add(request);
      return http.Response('{"results":null,"next":null}', 200);
    });
    final page =
        await RawgService(client).discoverGames(ordering: '-metacritic');
    expect(requests.single.url.queryParameters,
        {'ordering': '-metacritic', 'page': '1', 'page_size': '40'});
    expect(page.items, isEmpty);
    expect(page.hasMore, isFalse);
    expect(page.totalCount, isNull);
  });

  for (final status in [401, 429, 500, 503]) {
    test('risposta HTTP $status produce RawgException', () async {
      client = MockClient((_) async => http.Response('not-json', status));
      await expectLater(
          RawgService(client).discoverGames(ordering: '-added'),
          throwsA(isA<RawgException>()
              .having((e) => e.message, 'message', contains('$status'))));
    });
  }

  test('JSON corrotto propaga FormatException; screenshots offline sono vuoti',
      () async {
    client = MockClient((_) async => http.Response('<html>', 200));
    final service = RawgService(client);
    await expectLater(service.getGameDetails(1), throwsFormatException);
    expect(await service.getScreenshots(1), isEmpty);
  });
}
