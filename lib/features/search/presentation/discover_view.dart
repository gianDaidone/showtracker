import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../../core/database/app_database.dart';
import '../../../core/paged_search.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/paged_list_footer.dart';
import '../../games/data/models/rawg_game.dart';
import '../../games/providers/games_providers.dart';
import '../../movies/data/models/tmdb_movie.dart';
import '../../movies/providers/movies_providers.dart';
import '../../series/data/models/tmdb_show.dart';
import '../../series/providers/series_providers.dart';
import '../data/discover_rules.dart';
import '../providers/discover_providers.dart';
import '../providers/search_providers.dart';
import 'widgets/search_result_tile.dart';

/// Elementi per riga con il filtro "Tutti": una pagina TMDB.
const _rowCap = 20;

/// Cosa mostra Cerca a barra vuota: con "Tutti" ([type] null) una riga
/// orizzontale per tipo, con un filtro le liste Per te / Di tendenza / Più
/// votati di quel tipo, a scorrimento verticale.
class DiscoverView extends ConsumerStatefulWidget {
  final SearchResultType? type;
  final ValueChanged<SearchResultType> onSeeAll;

  const DiscoverView({super.key, required this.type, required this.onSeeAll});

  @override
  ConsumerState<DiscoverView> createState() => _DiscoverViewState();
}

class _DiscoverViewState extends ConsumerState<DiscoverView> {
  /// Lista scelta con le chip, per tipo: cambiando filtro e tornando indietro
  /// resta quella.
  final _chosen = <SearchResultType, DiscoverList>{};

  @override
  Widget build(BuildContext context) {
    final type = widget.type;
    if (type == null) {
      return ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        children: [
          for (final t in SearchResultType.values)
            if (t != SearchResultType.game || kEnableGames)
              _DiscoverRow(type: t, onSeeAll: () => widget.onSeeAll(t)),
        ],
      );
    }

    final hasSeeds = _watchHasSeeds(ref, type);
    if (hasSeeds == null) return const _Spinner();
    final list = _chosen[type] ??
        (hasSeeds ? DiscoverList.forYou : DiscoverList.trending);
    return Column(
      children: [
        _ListChips(
          active: list,
          onSelect: (l) => setState(() => _chosen[type] = l),
        ),
        Expanded(
          child: _DiscoverList(
            // Chiave per tipo e lista: altrimenti la posizione di scorrimento
            // passerebbe da una lista all'altra
            key: ValueKey((type, list)),
            type: type,
            list: list,
            hasSeeds: hasSeeds,
          ),
        ),
      ],
    );
  }
}

// ── Dati ──────────────────────────────────────────────────────────────────────

/// Se l'utente ha titoli di [type] da cui partire per "Per te"; null finché i
/// tracciati non sono caricati.
bool? _watchHasSeeds(WidgetRef ref, SearchResultType type) {
  bool? has<T>(AsyncValue<List<T>> a, List<T> Function(List<T>) seeds) =>
      a.hasValue ? seeds(a.requireValue).isNotEmpty : null;
  return switch (type) {
    SearchResultType.series => ref.watch(
        trackedShowsProvider.select((a) => has(a, showSeeds))),
    SearchResultType.movie => ref.watch(
        trackedMoviesProvider.select((a) => has(a, movieSeeds))),
    SearchResultType.game => ref.watch(
        trackedGamesProvider.select((a) => has(a, gameSeeds))),
  };
}

/// Una lista da scoprire già convertita in [SearchResult], senza i titoli che
/// l'utente traccia già (in qualsiasi stato).
class _Feed {
  final AsyncValue<PagedResults<Object?>> async;
  final List<SearchResult> items;
  final VoidCallback loadMore;
  final VoidCallback retry;

  const _Feed({
    required this.async,
    required this.items,
    required this.loadMore,
    required this.retry,
  });
}

_Feed _watchFeed(WidgetRef ref, SearchResultType type, DiscoverList list) {
  switch (type) {
    case SearchResultType.series:
      final p = showDiscoverProvider(list);
      final async = ref.watch(p);
      final tracked = {
        for (final s in ref.watch(trackedShowsProvider).value ??
            const <TrackedShow>[])
          s.tmdbId,
      };
      return _Feed(
        async: async,
        items: [
          for (final s in async.value?.items ?? const <TmdbShow>[])
            if (!tracked.contains(s.id)) SearchResult.fromShow(s),
        ],
        loadMore: () => ref.read(p.notifier).loadMore(),
        retry: () => ref.invalidate(p),
      );
    case SearchResultType.movie:
      final p = movieDiscoverProvider(list);
      final async = ref.watch(p);
      final tracked = {
        for (final m in ref.watch(trackedMoviesProvider).value ??
            const <TrackedMovy>[])
          m.tmdbId,
      };
      return _Feed(
        async: async,
        items: [
          for (final m in async.value?.items ?? const <TmdbMovie>[])
            if (!tracked.contains(m.id)) SearchResult.fromMovie(m),
        ],
        loadMore: () => ref.read(p.notifier).loadMore(),
        retry: () => ref.invalidate(p),
      );
    case SearchResultType.game:
      final p = gameDiscoverProvider(list);
      final async = ref.watch(p);
      final tracked = {
        for (final g in ref.watch(trackedGamesProvider).value ??
            const <TrackedGame>[])
          g.rawgId,
      };
      return _Feed(
        async: async,
        items: [
          for (final g in async.value?.items ?? const <RawgGame>[])
            if (!tracked.contains(g.id)) SearchResult.fromGame(g),
        ],
        loadMore: () => ref.read(p.notifier).loadMore(),
        retry: () => ref.invalidate(p),
      );
  }
}

String _typeLabel(SearchResultType type) => switch (type) {
      SearchResultType.series => 'Serie TV',
      SearchResultType.movie => 'Film',
      SearchResultType.game => 'Giochi',
    };

// ── "Tutti": una riga orizzontale per tipo ────────────────────────────────────

class _DiscoverRow extends ConsumerWidget {
  final SearchResultType type;
  final VoidCallback onSeeAll;

  const _DiscoverRow({required this.type, required this.onSeeAll});

  static const _posterWidth = 110.0;
  static const _posterHeight = 165.0;
  // Poster + due righe di titolo + anno, con margine per il testo ingrandito
  static const _rowHeight = _posterHeight + 60;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasSeeds = _watchHasSeeds(ref, type);

    // "Per te" se ci sono semi; se non dà niente (consigli tutti già
    // tracciati), "Di tendenza", così la riga non resta vuota.
    var list = hasSeeds == true ? DiscoverList.forYou : DiscoverList.trending;
    var feed = hasSeeds == null ? null : _watchFeed(ref, type, list);
    if (feed != null &&
        list == DiscoverList.forYou &&
        feed.async.hasValue &&
        !feed.async.isLoading &&
        feed.items.isEmpty) {
      list = DiscoverList.trending;
      feed = _watchFeed(ref, type, list);
    }

    final items = feed?.items.take(_rowCap).toList() ?? const [];
    final Widget body;
    if (feed == null || (feed.async.isLoading && items.isEmpty)) {
      body = ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, __) => Align(
          alignment: Alignment.topCenter,
          child: Container(
            width: _posterWidth,
            height: _posterHeight,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      );
    } else if (feed.async.hasError && items.isEmpty) {
      body = _ErrorMessage(error: feed.async.error!, onRetry: feed.retry);
    } else if (items.isEmpty) {
      body = const Center(
        child: Text(
          'Niente da mostrare per ora',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      );
    } else {
      body = ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) => i == items.length
            ? _SeeAllCard(
                width: _posterWidth,
                height: _posterHeight,
                onTap: onSeeAll,
              )
            : _PosterCard(
                result: items[i],
                width: _posterWidth,
                height: _posterHeight,
              ),
      );
    }

    final suffix = list == DiscoverList.forYou ? 'per te' : 'di tendenza';
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 4, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${_typeLabel(type)} $suffix',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onSeeAll,
                  child: const Text(
                    'Vedi tutti',
                    style: TextStyle(
                        color: AppColors.accent, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: _rowHeight, child: body),
        ],
      ),
    );
  }
}

class _PosterCard extends StatelessWidget {
  final SearchResult result;
  final double width;
  final double height;

  const _PosterCard({
    required this.result,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => openSearchResult(context, result),
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SearchResultThumbnail(
              url: result.imageUrl,
              type: result.type,
              width: width,
              height: height,
              borderRadius: 10,
            ),
            const SizedBox(height: 6),
            Text(
              result.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
            if (result.subtitle?.isNotEmpty == true)
              Text(
                result.subtitle!,
                maxLines: 1,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 11),
              ),
          ],
        ),
      ),
    );
  }
}

class _SeeAllCard extends StatelessWidget {
  final double width;
  final double height;
  final VoidCallback onTap;

  const _SeeAllCard({
    required this.width,
    required this.height,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.divider),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.arrow_forward, color: AppColors.accent),
              SizedBox(height: 8),
              Text(
                'Vedi tutti',
                style: TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Filtro singolo: chip + lista verticale ────────────────────────────────────

class _ListChips extends StatelessWidget {
  final DiscoverList active;
  final ValueChanged<DiscoverList> onSelect;

  const _ListChips({required this.active, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          for (final l in DiscoverList.values)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onTap: () => onSelect(l),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: l == active
                        ? AppColors.accent.withAlpha(40)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: l == active
                          ? AppColors.accent.withAlpha(140)
                          : AppColors.divider.withAlpha(80),
                    ),
                  ),
                  child: Text(
                    l.label,
                    style: TextStyle(
                      color: l == active
                          ? AppColors.accent
                          : AppColors.textSecondary,
                      fontWeight:
                          l == active ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DiscoverList extends ConsumerWidget {
  final SearchResultType type;
  final DiscoverList list;
  final bool hasSeeds;

  const _DiscoverList({
    super.key,
    required this.type,
    required this.list,
    required this.hasSeeds,
  });

  String get _noun => switch (type) {
        SearchResultType.series => 'serie',
        SearchResultType.movie => 'film',
        SearchResultType.game => 'gioco',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = _watchFeed(ref, type, list);
    final paged = feed.async.value;

    if (paged == null || (feed.async.isLoading && feed.items.isEmpty)) {
      if (feed.async.hasError) {
        return _ErrorMessage(error: feed.async.error!, onRetry: feed.retry);
      }
      return const _Spinner();
    }

    final hasFooter = paged.hasMore || paged.loadMoreFailed;
    if (feed.items.isEmpty && !hasFooter) {
      final message = list == DiscoverList.forYou && !hasSeeds
          ? 'Segui o completa qualche $_noun e qui troverai dei consigli'
          : 'Niente da mostrare per ora';
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 24),
      itemCount: feed.items.length + (hasFooter ? 1 : 0),
      itemBuilder: (_, i) => i == feed.items.length
          ? PagedListFooter(results: paged, onLoadMore: feed.loadMore)
          : SearchResultTile(result: feed.items[i]),
    );
  }
}

// ── Stati comuni ──────────────────────────────────────────────────────────────

class _Spinner extends StatelessWidget {
  const _Spinner();

  @override
  Widget build(BuildContext context) => const Center(
      child: CircularProgressIndicator(color: AppColors.accent));
}

class _ErrorMessage extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _ErrorMessage({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$error',
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
            ),
            TextButton(
              onPressed: onRetry,
              child: const Text(
                'Riprova',
                style: TextStyle(
                    color: AppColors.accent, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
