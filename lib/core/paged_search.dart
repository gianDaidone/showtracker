import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show KeepAliveLink;

/// Una pagina di risultati restituita da un service di ricerca.
class SearchPage<T> {
  final List<T> items;
  final bool hasMore;

  /// Totale dichiarato dall'API (TMDB `total_results`, RAWG `count`).
  final int? totalCount;

  const SearchPage({
    required this.items,
    required this.hasMore,
    this.totalCount,
  });
}

/// Risultati accumulati di una ricerca paginata.
class PagedResults<T> {
  final List<T> items;
  final bool hasMore;
  final int? totalCount;
  final bool isLoadingMore;

  /// L'ultima pagina successiva non è arrivata: niente caricamento
  /// automatico finché l'utente non tocca "Riprova".
  final bool loadMoreFailed;

  const PagedResults({
    required this.items,
    required this.hasMore,
    this.totalCount,
    this.isLoadingMore = false,
    this.loadMoreFailed = false,
  });

  const PagedResults.empty()
      : items = const [],
        hasMore = false,
        totalCount = 0,
        isLoadingMore = false,
        loadMoreFailed = false;

  PagedResults<T> copyWith({bool? isLoadingMore, bool? loadMoreFailed}) =>
      PagedResults(
        items: items,
        hasMore: hasMore,
        totalCount: totalCount,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
      );
}

typedef PageFetcher<T> = Future<SearchPage<T>> Function(String query, int page);
typedef ListPageFetcher<T> = Future<SearchPage<T>> Function(int page);

/// Lista a pagine: `build` carica la prima, [loadMore] accoda le successive
/// scartando i doppioni (le API possono ripetere un elemento tra due pagine se
/// il catalogo cambia nel frattempo).
///
/// [fetcherOf] riceve il `ref` di `build` per fare `watch` del service: se il
/// service cambia (es. nuova chiave API) la lista riparte da pagina 1.
///
/// Con [cacheFor] il provider (autoDispose) resta in vita per quel tempo dopo
/// che l'ultimo listener se ne va: riaprendo la schermata non si rifanno le
/// chiamate. Una prima pagina fallita non resta in cache.
class PagedListNotifier<T> extends AsyncNotifier<PagedResults<T>> {
  PagedListNotifier(
    this.fetcherOf,
    this.idOf, {
    this.label = 'Lista',
    this.cacheFor,
  });

  final ListPageFetcher<T> Function(Ref ref) fetcherOf;
  final Object Function(T item) idOf;

  /// Solo per i log.
  final String label;
  final Duration? cacheFor;

  late ListPageFetcher<T> _fetch;
  int _page = 1;

  @override
  Future<PagedResults<T>> build() async {
    final link = cacheFor == null ? null : _keepAliveFor(cacheFor!);
    _fetch = fetcherOf(ref);
    _page = 1;
    final SearchPage<T> first;
    try {
      first = await _fetch(1);
    } catch (e) {
      // L'errore finisce nell'AsyncValue e lo mostra la schermata, ma va
      // anche nei log: altrimenti resta visibile solo come lista vuota.
      debugPrint('$label fallita: $e');
      link?.close();
      rethrow;
    }
    return PagedResults(
      items: first.items,
      hasMore: first.hasMore,
      totalCount: first.totalCount,
    );
  }

  KeepAliveLink _keepAliveFor(Duration duration) {
    final link = ref.keepAlive();
    Timer? timer;
    ref.onCancel(() {
      timer?.cancel();
      timer = Timer(duration, link.close);
    });
    ref.onResume(() => timer?.cancel());
    ref.onDispose(() => timer?.cancel());
    return link;
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(
        current.copyWith(isLoadingMore: true, loadMoreFailed: false));
    try {
      final next = await _fetch(_page + 1);
      if (!ref.mounted) return;
      _page++;
      final seen = current.items.map(idOf).toSet();
      state = AsyncData(PagedResults(
        items: [
          ...current.items,
          ...next.items.where((item) => seen.add(idOf(item))),
        ],
        // Una pagina vuota chiude la lista anche se l'API dice altrimenti,
        // così il footer non continua a chiedere pagine all'infinito.
        hasMore: next.hasMore && next.items.isNotEmpty,
        totalCount: current.totalCount,
      ));
    } catch (e) {
      debugPrint('$label, pagina ${_page + 1} non caricata: $e');
      if (!ref.mounted) return;
      state = AsyncData(
          current.copyWith(isLoadingMore: false, loadMoreFailed: true));
    }
  }
}

/// [PagedListNotifier] per una ricerca testuale: sotto i 2 caratteri non
/// chiama il service e restituisce una lista vuota.
class PagedSearchNotifier<T> extends PagedListNotifier<T> {
  PagedSearchNotifier(
    this.query,
    PageFetcher<T> Function(Ref ref) fetcherOf,
    Object Function(T item) idOf,
  ) : super(
          (ref) {
            final fetch = fetcherOf(ref);
            return (page) => fetch(query, page);
          },
          idOf,
          label: 'Ricerca "$query"',
        );

  final String query;

  @override
  Future<PagedResults<T>> build() async {
    if (query.length < 2) return PagedResults<T>.empty();
    return super.build();
  }
}
