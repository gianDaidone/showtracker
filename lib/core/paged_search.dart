import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

/// Ricerca a pagine: `build` carica la prima, [loadMore] accoda le successive
/// scartando i doppioni (le API possono ripetere un elemento tra due pagine se
/// il catalogo cambia nel frattempo).
///
/// [fetcherOf] riceve il `ref` di `build` per fare `watch` del service: se il
/// service cambia (es. nuova chiave API) la ricerca riparte da pagina 1.
class PagedSearchNotifier<T> extends AsyncNotifier<PagedResults<T>> {
  PagedSearchNotifier(this.query, this.fetcherOf, this.idOf);

  final String query;
  final PageFetcher<T> Function(Ref ref) fetcherOf;
  final Object Function(T item) idOf;

  late PageFetcher<T> _fetch;
  int _page = 1;

  @override
  Future<PagedResults<T>> build() async {
    _fetch = fetcherOf(ref);
    _page = 1;
    if (query.length < 2) return PagedResults<T>.empty();
    final SearchPage<T> first;
    try {
      first = await _fetch(query, 1);
    } catch (e) {
      // L'errore finisce nell'AsyncValue e lo mostra la schermata, ma va
      // anche nei log: altrimenti resta visibile solo come lista vuota.
      debugPrint('Ricerca "$query" fallita: $e');
      rethrow;
    }
    return PagedResults(
      items: first.items,
      hasMore: first.hasMore,
      totalCount: first.totalCount,
    );
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(
        current.copyWith(isLoadingMore: true, loadMoreFailed: false));
    try {
      final next = await _fetch(query, _page + 1);
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
      debugPrint('Ricerca "$query", pagina ${_page + 1} non caricata: $e');
      if (!ref.mounted) return;
      state = AsyncData(
          current.copyWith(isLoadingMore: false, loadMoreFailed: true));
    }
  }
}
