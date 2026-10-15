import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:showtracker/core/paged_search.dart';
import 'package:showtracker/core/riverpod_utils.dart';

/// Service finto: [pages] sono le pagine da restituire (1-based), e
/// [failOnce] la pagina che fallisce al primo tentativo.
class _FakeSearch {
  _FakeSearch(this.pages, {this.failOnce});
  final List<List<int>> pages;
  int? failOnce;
  final requested = <int>[];

  Future<SearchPage<int>> fetch(String query, int page) async {
    requested.add(page);
    if (page == failOnce) {
      failOnce = null;
      throw Exception('rete assente');
    }
    return SearchPage(
      items: pages[page - 1],
      hasMore: page < pages.length,
      totalCount: pages.expand((p) => p).length,
    );
  }
}

late _FakeSearch _fake;

final provider = AsyncNotifierProvider.autoDispose
    .family<PagedSearchNotifier<int>, PagedResults<int>, String>(
  (query) => PagedSearchNotifier(query, (_) => _fake.fetch, (i) => i),
);

void main() {
  late ProviderContainer container;

  void setUpWith(_FakeSearch f, {String query = 'zelda'}) {
    _fake = f;
    container = ProviderContainer(retry: noProviderRetry);
    // Un listener tiene in vita il provider autoDispose, come fa la schermata
    container.listen(provider(query), (_, __) {});
  }

  tearDown(() => container.dispose());

  test('accoda le pagine successive e si ferma all\'ultima', () async {
    setUpWith(_FakeSearch([
      [1, 2],
      [3, 4],
      [5],
    ]));
    final notifier = container.read(provider('zelda').notifier);

    expect((await container.read(provider('zelda').future)).items, [1, 2]);
    await notifier.loadMore();
    await notifier.loadMore();

    final state = container.read(provider('zelda')).requireValue;
    expect(state.items, [1, 2, 3, 4, 5]);
    expect(state.hasMore, isFalse);
    expect(state.totalCount, 5);

    await notifier.loadMore(); // niente altre pagine: nessuna richiesta
    expect(_fake.requested, [1, 2, 3]);
  });

  test('scarta i doppioni tra una pagina e l\'altra', () async {
    setUpWith(_FakeSearch([
      [1, 2],
      [2, 3],
    ]));
    await container.read(provider('zelda').future);
    await container.read(provider('zelda').notifier).loadMore();

    expect(container.read(provider('zelda')).requireValue.items, [1, 2, 3]);
  });

  test('se una pagina fallisce tiene i risultati e permette di riprovare',
      () async {
    setUpWith(_FakeSearch([
      [1],
      [2],
    ], failOnce: 2));
    final notifier = container.read(provider('zelda').notifier);
    await container.read(provider('zelda').future);

    await notifier.loadMore();
    var state = container.read(provider('zelda')).requireValue;
    expect(state.items, [1]);
    expect(state.loadMoreFailed, isTrue);

    await notifier.loadMore(); // "Riprova"
    state = container.read(provider('zelda')).requireValue;
    expect(state.items, [1, 2]);
    expect(state.loadMoreFailed, isFalse);
  });

  test('una ricerca di meno di 2 caratteri non chiama il service', () async {
    setUpWith(_FakeSearch([
      [1],
    ]), query: 'z');
    final state = await container.read(provider('z').future);

    expect(state.items, isEmpty);
    expect(_fake.requested, isEmpty);
  });

  test('PagedListNotifier: lista senza query, anche di una pagina sola',
      () async {
    _fake = _FakeSearch([
      [7, 8],
    ]);
    final listProvider = AsyncNotifierProvider.autoDispose<
        PagedListNotifier<int>, PagedResults<int>>(
      () => PagedListNotifier(
        (_) => (page) => _fake.fetch('', page),
        (i) => i,
        cacheFor: const Duration(minutes: 30),
      ),
    );
    container = ProviderContainer(retry: noProviderRetry);
    container.listen(listProvider, (_, __) {});

    final state = await container.read(listProvider.future);
    expect(state.items, [7, 8]);
    expect(state.hasMore, isFalse);

    await container.read(listProvider.notifier).loadMore();
    expect(_fake.requested, [1]);
  });
}
