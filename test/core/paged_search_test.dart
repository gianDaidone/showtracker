import 'dart:async';

import 'package:fake_async/fake_async.dart';
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

  AsyncNotifierProvider<PagedListNotifier<int>, PagedResults<int>> listProvider(
          ListPageFetcher<int> fetch,
          {Duration? cacheFor}) =>
      AsyncNotifierProvider.autoDispose<PagedListNotifier<int>,
          PagedResults<int>>(
        () => PagedListNotifier((_) => fetch, (i) => i, cacheFor: cacheFor),
      );

  test(
      'loadMore concorrenti condividono una sola richiesta e una pagina vuota chiude',
      () async {
    final pending = Completer<SearchPage<int>>();
    final requested = <int>[];
    final p = listProvider((page) async {
      requested.add(page);
      if (page == 1) return const SearchPage(items: [1], hasMore: true);
      return pending.future;
    });
    container = ProviderContainer(retry: noProviderRetry);
    container.listen(p, (_, __) {});
    await container.read(p.future);
    final notifier = container.read(p.notifier);
    final first = notifier.loadMore();
    final second = notifier.loadMore();
    expect(container.read(p).requireValue.isLoadingMore, isTrue);
    expect(requested, [1, 2]);
    pending.complete(const SearchPage(items: [], hasMore: true));
    await Future.wait([first, second]);
    expect(container.read(p).requireValue.items, [1]);
    expect(container.read(p).requireValue.hasMore, isFalse);
    expect(container.read(p).requireValue.isLoadingMore, isFalse);
    await notifier.loadMore();
    expect(requested, [1, 2]);
  });

  test('loadMore prima della prima pagina non avvia richieste aggiuntive',
      () async {
    final pending = Completer<SearchPage<int>>();
    final requested = <int>[];
    final p = listProvider((page) {
      requested.add(page);
      return pending.future;
    });
    container = ProviderContainer(retry: noProviderRetry);
    container.listen(p, (_, __) {});
    await container.read(p.notifier).loadMore();
    expect(requested, [1]);
    pending.complete(const SearchPage(items: [1], hasMore: false));
    expect((await container.read(p.future)).items, [1]);
  });

  test('prima pagina fallita espone errore e riparte dopo invalidazione',
      () async {
    var calls = 0;
    final p = listProvider((page) async {
      if (++calls == 1) throw StateError('prima pagina offline');
      return const SearchPage(items: [7], hasMore: false);
    });
    container = ProviderContainer(retry: noProviderRetry);
    container.listen(p, (_, __) {});
    await expectLater(container.read(p.future), throwsStateError);
    expect(container.read(p).hasError, isTrue);
    expect(calls, 1);
    container.invalidate(p);
    expect((await container.read(p.future)).items, [7]);
    expect(calls, 2);
  });

  for (final fails in [false, true]) {
    test(
        'disposal durante loadMore ${fails ? 'fallita' : 'riuscita'} non pubblica stato tardivo',
        () async {
      final pending = Completer<SearchPage<int>>();
      final p = listProvider((page) async {
        if (page == 1) return const SearchPage<int>(items: [1], hasMore: true);
        return pending.future;
      });
      container = ProviderContainer(retry: noProviderRetry);
      final listener = container.listen(p, (_, __) {});
      await container.read(p.future);
      final notifier = container.read(p.notifier);
      var updates = 0;
      final stateListener = container.listen(p, (_, __) => updates++);
      final loading = notifier.loadMore();
      listener.close();
      stateListener.close();
      container.dispose();
      final updatesAtDispose = updates;
      if (fails) {
        pending.completeError(StateError('offline dopo disposal'));
      } else {
        pending.complete(const SearchPage(items: [2], hasMore: false));
      }
      await expectLater(loading, completes);
      expect(updates, updatesAtDispose);
      // Il teardown resta proprietario di un container vivo.
      container = ProviderContainer(retry: noProviderRetry);
    });
  }

  test('cache scade dopo ultimo listener, ripresa annulla e riavvia il timer',
      () {
    fakeAsync((async) {
      var calls = 0;
      final p = listProvider((page) async {
        calls++;
        return const SearchPage(items: [1], hasMore: false);
      }, cacheFor: const Duration(minutes: 30));
      container = ProviderContainer(retry: noProviderRetry);
      var listener = container.listen(p, (_, __) {});
      async.flushMicrotasks();
      expect(container.read(p).requireValue.items, [1]);
      listener.close();
      async.elapse(const Duration(minutes: 29));
      async.flushMicrotasks();
      listener = container.listen(p, (_, __) {});
      async.flushMicrotasks();
      expect(calls, 1);
      async.elapse(const Duration(minutes: 31));
      expect(calls, 1); // con listener attivo non scade.
      listener.close();
      async.elapse(const Duration(minutes: 30));
      async.flushMicrotasks();
      listener = container.listen(p, (_, __) {});
      async.flushMicrotasks();
      expect(calls, 2);
      listener.close();
      container.dispose();
      container = ProviderContainer(retry: noProviderRetry);
    });
  });

  test('prima pagina fallita non resta in cache per trenta minuti', () {
    fakeAsync((async) {
      var calls = 0;
      final p = listProvider((page) async {
        if (++calls == 1) throw StateError('offline');
        return const SearchPage(items: [2], hasMore: false);
      }, cacheFor: const Duration(minutes: 30));
      container = ProviderContainer(retry: noProviderRetry);
      var listener = container.listen(p, (_, __) {});
      Object? observedError;
      container.read(p.future).then<void>((_) {},
          onError: (Object error, StackTrace _) => observedError = error);
      async.flushMicrotasks();
      expect(observedError, isA<StateError>());
      expect(container.read(p).error, same(observedError));
      listener.close();
      async.elapse(Duration.zero);
      async.flushMicrotasks();
      listener = container.listen(p, (_, __) {});
      async.flushMicrotasks();
      expect(calls, 2);
      expect(container.read(p).requireValue.items, [2]);
      listener.close();
      container.dispose();
      container = ProviderContainer(retry: noProviderRetry);
    });
  });

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
    setUpWith(
        _FakeSearch([
          [1],
        ]),
        query: 'z');
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
