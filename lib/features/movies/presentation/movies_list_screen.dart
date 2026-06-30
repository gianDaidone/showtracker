import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/movies_providers.dart';

class MoviesListScreen extends ConsumerStatefulWidget {
  const MoviesListScreen({super.key});

  @override
  ConsumerState<MoviesListScreen> createState() => _MoviesListScreenState();
}

class _MoviesListScreenState extends ConsumerState<MoviesListScreen> {
  bool _isSearching = false;
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startSearch() => setState(() => _isSearching = true);

  void _stopSearch() => setState(() {
        _isSearching = false;
        _query = '';
        _controller.clear();
      });

  @override
  Widget build(BuildContext context) {
    final moviesAsync = ref.watch(trackedMoviesNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: _isSearching
            ? TextField(
                controller: _controller,
                autofocus: true,
                style: const TextStyle(color: AppColors.textPrimary),
                cursorColor: AppColors.accent,
                decoration: const InputDecoration(
                  hintText: 'Filtra i tuoi film…',
                  hintStyle: TextStyle(color: AppColors.textSecondary),
                  border: InputBorder.none,
                ),
                onChanged: (v) => setState(() => _query = v.trim()),
              )
            : const Text(
                'I miei film',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
        actions: [
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.close, color: AppColors.textPrimary),
              tooltip: 'Annulla',
              onPressed: _stopSearch,
            )
          else
            IconButton(
              icon: const Icon(Icons.search, color: AppColors.textPrimary),
              tooltip: 'Filtra film',
              onPressed: _startSearch,
            ),
        ],
      ),
      body: moviesAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.accent)),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Errore:\n$e',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ),
        data: (movies) {
          if (movies.isEmpty) return const _EmptyState();

          final filtered = _query.isEmpty
              ? movies
              : movies
                  .where((m) =>
                      m.title.toLowerCase().contains(_query.toLowerCase()))
                  .toList();

          if (filtered.isEmpty) {
            return _NoResults(query: _query);
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 24),
            itemCount: filtered.length,
            itemBuilder: (_, i) => _MovieCard(movie: filtered[i]),
          );
        },
      ),
    );
  }
}

// ── Nessun risultato per il filtro ────────────────────────────────────────────

class _NoResults extends StatelessWidget {
  final String query;
  const _NoResults({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, size: 56, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              'Nessun film trovato\nper "$query"',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Card ──────────────────────────────────────────────────────────────────────

class _MovieCard extends StatelessWidget {
  final TrackedMovy movie;
  const _MovieCard({required this.movie});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => context.push('/movies/detail/${movie.tmdbId}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _Poster(path: movie.posterPath),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      movie.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    _StatusChip(status: movie.status),
                    if (movie.releaseYear != null || movie.userRating != null) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          if (movie.releaseYear != null) ...[
                            Text(
                              '${movie.releaseYear}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                          if (movie.releaseYear != null && movie.userRating != null)
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 6),
                              child: Text('•', style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                            ),
                          if (movie.userRating != null) ...[
                            const Icon(Icons.star, color: AppColors.accent, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              movie.userRating!.toStringAsFixed(1),
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
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

class _Poster extends StatelessWidget {
  final String? path;
  const _Poster({this.path});

  @override
  Widget build(BuildContext context) {
    final url = path != null ? 'https://image.tmdb.org/t/p/w185$path' : null;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 60,
        height: 90,
        child: url != null
            ? CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    const ColoredBox(color: AppColors.divider),
                errorWidget: (_, __, ___) => const ColoredBox(
                  color: AppColors.divider,
                  child: Center(
                    child: Icon(Icons.movie,
                        color: AppColors.textSecondary, size: 28),
                  ),
                ),
              )
            : const ColoredBox(
                color: AppColors.divider,
                child: Center(
                  child: Icon(Icons.movie,
                      color: AppColors.textSecondary, size: 28),
                ),
              ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final MediaStatus status;
  const _StatusChip({required this.status});

  static const _colors = {
    MediaStatus.watching: Color(0xFFFF9C01),
    MediaStatus.completed: Color(0xFF4CAF50),
    MediaStatus.paused: Color(0xFFFFC107),
    MediaStatus.dropped: Color(0xFFF44336),
    MediaStatus.planToWatch: Color(0xFF2196F3),
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[status] ?? AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(120),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ── Stato vuoto ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.movie_outlined,
                size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            const Text(
              'Nessun film aggiunto',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Usa il tab Cerca per trovare\nun film e aggiungerlo.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.go('/search?filter=movie'),
              icon: const Icon(Icons.search),
              label: const Text('Cerca un film'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
