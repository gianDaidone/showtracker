import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../games/providers/games_providers.dart';
import '../../movies/providers/movies_providers.dart';
import '../../series/providers/series_providers.dart';
import '../providers/search_providers.dart';

// ── Filtro attivo ─────────────────────────────────────────────────────────────

enum _SearchFilter { all, series, movie, game }

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
                  ? const _EmptyHint()
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

// ── Hint iniziale ─────────────────────────────────────────────────────────────

class _EmptyHint extends StatelessWidget {
  const _EmptyHint();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Inizia la tua ricerca',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Cerca serie TV, film e giochi\nDigita almeno 2 caratteri',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
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

    final showsAsync = showShows
        ? ref.watch(searchShowsProvider(query))
        : const AsyncValue<List>.data([]);
    final moviesAsync = showMovies
        ? ref.watch(searchMoviesProvider(query))
        : const AsyncValue<List>.data([]);
    final gamesAsync = showGames
        ? ref.watch(searchGamesProvider(query))
        : const AsyncValue<List>.data([]);

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

    final rawShows =
        showShows ? (ref.watch(searchShowsProvider(query)).valueOrNull ?? []) : [];
    final rawMovies =
        showMovies ? (ref.watch(searchMoviesProvider(query)).valueOrNull ?? []) : [];
    final rawGames =
        showGames ? (ref.watch(searchGamesProvider(query)).valueOrNull ?? []) : [];

    final results = <SearchResult>[
      for (final s in rawShows)
        SearchResult(
          type: SearchResultType.series,
          title: s.name,
          subtitle: s.year?.toString(),
          imageUrl: s.posterUrl,
          mediaId: s.id,
          sortYear: s.year,
        ),
      for (final m in rawMovies)
        SearchResult(
          type: SearchResultType.movie,
          title: m.title,
          subtitle: m.year?.toString(),
          imageUrl: m.posterUrl,
          mediaId: m.id,
          sortYear: m.year,
        ),
      for (final g in rawGames)
        SearchResult(
          type: SearchResultType.game,
          title: g.name,
          subtitle: g.year?.toString(),
          imageUrl: g.coverUrl,
          mediaId: g.id,
          sortYear: g.year,
        ),
    ];

    if (results.isEmpty && !anyLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Row(
            children: [
              Text(
                '${results.length} '
                '${results.length == 1 ? 'risultato' : 'risultati'}',
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
            itemCount: results.length,
            itemBuilder: (_, i) => _ResultTile(result: results[i]),
          ),
        ),
      ],
    );
  }
}

// ── Tile singolo risultato ────────────────────────────────────────────────────

class _ResultTile extends StatelessWidget {
  final SearchResult result;
  const _ResultTile({required this.result});

  void _onTap(BuildContext context) {
    switch (result.type) {
      case SearchResultType.series:
        context.push('/series/detail/${result.mediaId}');
      case SearchResultType.movie:
        context.push('/movies/detail/${result.mediaId}');
      case SearchResultType.game:
        context.push('/games/detail/${result.mediaId}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: () => _onTap(context),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _Thumbnail(url: result.imageUrl, type: result.type),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    if (result.subtitle?.isNotEmpty == true) ...[
                      Text(
                        result.subtitle!,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                    ],
                    _TypeBadge(type: result.type),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Badge tipo ────────────────────────────────────────────────────────────────

class _TypeBadge extends StatelessWidget {
  final SearchResultType type;
  const _TypeBadge({required this.type});

  String get _label => switch (type) {
        SearchResultType.series => 'Serie TV',
        SearchResultType.movie => 'Film',
        SearchResultType.game => 'Gioco',
      };

  Color get _color => switch (type) {
        SearchResultType.series => AppColors.accent,
        SearchResultType.movie => const Color(0xFF4FC3F7),
        SearchResultType.game => const Color(0xFF81C784),
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _color.withAlpha(30),
        border: Border.all(color: _color.withAlpha(120)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        _label,
        style: TextStyle(
          color: _color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ── Thumbnail ─────────────────────────────────────────────────────────────────

class _Thumbnail extends StatelessWidget {
  final String? url;
  final SearchResultType type;
  const _Thumbnail({required this.url, required this.type});

  IconData get _fallbackIcon => switch (type) {
        SearchResultType.series => Icons.tv,
        SearchResultType.movie => Icons.movie,
        SearchResultType.game => Icons.videogame_asset,
      };

  // RAWG restituisce URL diretti; TMDB usa path → aggiungiamo il base URL solo per serie/film
  String? get _resolvedUrl {
    if (url == null) return null;
    if (type == SearchResultType.game) return url; // già URL completo
    return url; // il posterUrl di TmdbShow/TmdbMovie già include il base
  }

  @override
  Widget build(BuildContext context) {
    final resolved = _resolvedUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 64,
        height: 96,
        child: resolved != null
            ? CachedNetworkImage(
                imageUrl: resolved,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    const ColoredBox(color: AppColors.divider),
                errorWidget: (_, __, ___) => ColoredBox(
                  color: AppColors.divider,
                  child: Center(
                    child: Icon(_fallbackIcon,
                        color: AppColors.textSecondary, size: 20),
                  ),
                ),
              )
            : ColoredBox(
                color: AppColors.divider,
                child: Center(
                  child: Icon(_fallbackIcon,
                      color: AppColors.textSecondary, size: 20),
                ),
              ),
      ),
    );
  }
}
