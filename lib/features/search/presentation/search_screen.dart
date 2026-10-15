import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants.dart';
import '../../../core/paged_search.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/paged_list_footer.dart';
import '../../games/data/models/rawg_game.dart';
import '../../games/providers/games_providers.dart';
import '../../movies/data/models/tmdb_movie.dart';
import '../../movies/providers/movies_providers.dart';
import '../../series/data/models/tmdb_show.dart';
import '../../series/providers/series_providers.dart';
import '../providers/search_providers.dart';
import 'discover_view.dart';
import 'widgets/search_result_tile.dart';

// ── Filtro attivo ─────────────────────────────────────────────────────────────

enum _SearchFilter {
  all,
  series,
  movie,
  game;

  /// Il tipo mostrato da questo filtro; null per "Tutti".
  SearchResultType? get resultType => switch (this) {
        all => null,
        series => SearchResultType.series,
        movie => SearchResultType.movie,
        game => SearchResultType.game,
      };

  static _SearchFilter of(SearchResultType type) => switch (type) {
        SearchResultType.series => series,
        SearchResultType.movie => movie,
        SearchResultType.game => game,
      };
}

/// Risultati per tipo mostrati con il filtro "Tutti" (una pagina TMDB).
const _allFilterCap = 20;

_SearchFilter _parseFilter(String? raw) => switch (raw) {
      'series' => _SearchFilter.series,
      'movie' => _SearchFilter.movie,
      'game' => _SearchFilter.game,
      _ => _SearchFilter.all,
    };

// ── Screen ────────────────────────────────────────────────────────────────────

class SearchScreen extends StatefulWidget {
  final String? initialFilter;
  const SearchScreen({super.key, this.initialFilter});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';
  late _SearchFilter _filter;

  @override
  void initState() {
    super.initState();
    _filter = _parseFilter(widget.initialFilter);
  }

  @override
  void didUpdateWidget(SearchScreen old) {
    super.didUpdateWidget(old);
    if (widget.initialFilter != old.initialFilter) {
      setState(() => _filter = _parseFilter(widget.initialFilter));
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() {}); // aggiorna il pulsante clear in tempo reale
    _debounce?.cancel();
    final trimmed = value.trim();
    if (trimmed.length < 2) {
      setState(() => _query = '');
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _query = trimmed);
    });
  }

  void _onClear() {
    _controller.clear();
    _debounce?.cancel();
    setState(() => _query = '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          final route = switch (widget.initialFilter) {
                            'game' => '/games',
                            'movie' => '/movies',
                            _ => '/series',
                          };
                          context.go(route);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        color: Colors.transparent,
                        child: const Icon(
                          Icons.arrow_back,
                          color: AppColors.textPrimary,
                          size: 26,
                        ),
                      ),
                    ),
                  ),
                  SvgPicture.asset(
                    'assets/images/tmdb_logo.svg',
                    height: 18, // Più piccolo e centrato
                  ),
                ],
              ),
            ),

            // ── Barra di ricerca ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _SearchBar(
                controller: _controller,
                onChanged: _onChanged,
                onSubmitted: (v) {
                  _debounce?.cancel();
                  setState(() => _query = v.trim());
                },
                onClear: _onClear,
              ),
            ),

            // ── Badge filtro ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _FilterBadges(
                active: _filter,
                onSelect: (f) => setState(() => _filter = f),
              ),
            ),

            // ── Contenuto ────────────────────────────────────────────────
            Expanded(
              child: _query.isEmpty
                  ? DiscoverView(
                      type: _filter.resultType,
                      onSeeAll: (type) => setState(
                          () => _filter = _SearchFilter.of(type)),
                    )
                  : _Results(query: _query, filter: _filter),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Barra di ricerca ──────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider, width: 1.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: true,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 15),
              decoration: const InputDecoration(
                hintText: 'Cerca serie TV, film e giochi...',
                hintStyle: TextStyle(
                    color: AppColors.textSecondary, fontSize: 15),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          if (controller.text.isNotEmpty) ...[
            GestureDetector(
              onTap: onClear,
              child: const Icon(Icons.cancel,
                  color: AppColors.textSecondary, size: 20),
            ),
            const SizedBox(width: 8),
          ],
          const Icon(Icons.search, color: AppColors.accent, size: 26),
        ],
      ),
    );
  }
}

// ── Badge filtro ──────────────────────────────────────────────────────────────

typedef _FilterDef = ({_SearchFilter type, String label});

class _FilterBadges extends StatelessWidget {
  final _SearchFilter active;
  final ValueChanged<_SearchFilter> onSelect;

  const _FilterBadges({required this.active, required this.onSelect});

  static const List<_FilterDef> _filters = [
    (type: _SearchFilter.all, label: 'Tutti'),
    (type: _SearchFilter.series, label: 'Serie TV'),
    (type: _SearchFilter.movie, label: 'Film'),
    if (kEnableGames) (type: _SearchFilter.game, label: 'Giochi'),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: _filters
            .map((f) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _FilterBadge(
                    label: f.label,
                    active: active == f.type,
                    onTap: () => onSelect(f.type),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _FilterBadge extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _FilterBadge({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.divider.withAlpha(120) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: active
              ? null
              : Border.all(color: AppColors.divider.withAlpha(50)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? AppColors.accent : AppColors.textSecondary,
            fontWeight: active ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// ── Risultati ─────────────────────────────────────────────────────────────────

class _Results extends ConsumerWidget {
  final String query;
  final _SearchFilter filter;
  const _Results({required this.query, required this.filter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showShows =
        filter == _SearchFilter.all || filter == _SearchFilter.series;
    final showMovies =
        filter == _SearchFilter.all || filter == _SearchFilter.movie;
    final showGames =
        filter == _SearchFilter.all || filter == _SearchFilter.game;

    const none = AsyncValue<PagedResults<Never>>.data(PagedResults.empty());
    final AsyncValue<PagedResults<TmdbShow>> showsAsync =
        showShows ? ref.watch(showSearchProvider(query)) : none;
    final AsyncValue<PagedResults<TmdbMovie>> moviesAsync =
        showMovies ? ref.watch(movieSearchProvider(query)) : none;
    final AsyncValue<PagedResults<RawgGame>> gamesAsync =
        showGames ? ref.watch(gameSearchProvider(query)) : none;

    // Spinner a pagina intera solo mentre il provider attivo carica
    final isFullLoading = switch (filter) {
      _SearchFilter.series => showsAsync.isLoading,
      _SearchFilter.movie => moviesAsync.isLoading,
      _SearchFilter.game => gamesAsync.isLoading,
      _ => showsAsync.isLoading && moviesAsync.isLoading && gamesAsync.isLoading,
    };

    if (isFullLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.accent));
    }

    final anyLoading = switch (filter) {
      _SearchFilter.series => showsAsync.isLoading,
      _SearchFilter.movie => moviesAsync.isLoading,
      _SearchFilter.game => gamesAsync.isLoading,
      _ => showsAsync.isLoading || moviesAsync.isLoading || gamesAsync.isLoading,
    };

    // Con "Tutti" ogni tipo resta alla prima pagina (20 risultati), così uno
    // non sommerge gli altri; con un filtro la lista scorre e carica le
    // pagine successive.
    final single = filter != _SearchFilter.all;
    List<T> visible<T>(List<T> items) =>
        single ? items : items.take(_allFilterCap).toList();
    final rawShows = visible(showsAsync.value?.items ?? const <TmdbShow>[]);
    final rawMovies = visible(moviesAsync.value?.items ?? const <TmdbMovie>[]);
    final rawGames = visible(gamesAsync.value?.items ?? const <RawgGame>[]);

    // La lista paginata del filtro attivo (null con "Tutti")
    final (PagedResults<Object?>? paged, VoidCallback? loadMore) =
        switch (filter) {
      _SearchFilter.series => (
          showsAsync.value,
          () => ref.read(showSearchProvider(query).notifier).loadMore(),
        ),
      _SearchFilter.movie => (
          moviesAsync.value,
          () => ref.read(movieSearchProvider(query).notifier).loadMore(),
        ),
      _SearchFilter.game => (
          gamesAsync.value,
          () => ref.read(gameSearchProvider(query).notifier).loadMore(),
        ),
      _ => (null, null),
    };
    final hasFooter =
        paged != null && (paged.hasMore || paged.loadMoreFailed);

    final results = [
      ...rawShows.map(SearchResult.fromShow),
      ...rawMovies.map(SearchResult.fromMovie),
      ...rawGames.map(SearchResult.fromGame),
    ];

    if (results.isEmpty && !anyLoading) {
      // Una ricerca fallita non è "nessun risultato": prima il messaggio
      // mostrava lo stesso testo e nascondeva l'errore.
      final failed = [
        if (showShows) showsAsync,
        if (showMovies) moviesAsync,
        if (showGames) gamesAsync,
      ].where((a) => a.hasError);
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (failed.isNotEmpty) ...[
                const Text(
                  'Ricerca non riuscita',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${failed.first.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                ),
              ] else ...[
                const Text(
                  'Nessun risultato',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Nessun contenuto trovato per "$query"',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 14),
                ),
              ],
            ],
          ),
        ),
      );
    }

    // Con un filtro il totale dichiarato dall'API, non solo i caricati
    final count = paged?.totalCount ?? results.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Row(
            children: [
              Text(
                '$count '
                '${count == 1 ? 'risultato' : 'risultati'}',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13),
              ),
              if (anyLoading) ...[
                const SizedBox(width: 8),
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                      strokeWidth: 1.5, color: AppColors.textSecondary),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: results.length + (hasFooter ? 1 : 0),
            itemBuilder: (_, i) => i == results.length
                ? PagedListFooter(results: paged!, onLoadMore: loadMore!)
                : SearchResultTile(result: results[i]),
          ),
        ),
      ],
    );
  }
}
