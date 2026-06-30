import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/services/app_toast.dart';
import '../../../core/theme/app_theme.dart';
import '../data/models/tmdb_movie_detail.dart';
import '../providers/movies_providers.dart';

class MovieDetailScreen extends ConsumerWidget {
  final int tmdbId;
  const MovieDetailScreen({super.key, required this.tmdbId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(movieDetailProvider(tmdbId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: detailAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
        error: (e, _) => _ErrorBody(error: e.toString()),
        data: (detail) => _DetailBody(detail: detail),
      ),
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _DetailBody extends ConsumerWidget {
  final TmdbMovieDetail detail;
  const _DetailBody({required this.detail});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackedList =
        ref.watch(trackedMoviesNotifierProvider).valueOrNull ?? [];
    final TrackedMovy? trackedMovie =
        trackedList.where((m) => m.tmdbId == detail.id).firstOrNull;

    return CustomScrollView(
      slivers: [
        _BackdropAppBar(detail: detail),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(detail: detail),
                const SizedBox(height: 16),
                if (detail.overview?.isNotEmpty == true) ...[
                  _Overview(text: detail.overview!),
                  const SizedBox(height: 16),
                ],
                _TrackButton(detail: detail, trackedMovie: trackedMovie),
                if (trackedMovie != null) ...[
                  const SizedBox(height: 8),
                  _StatusSelector(trackedMovie: trackedMovie),
                ],
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Backdrop AppBar ───────────────────────────────────────────────────────────

class _BackdropAppBar extends ConsumerStatefulWidget {
  final TmdbMovieDetail detail;
  const _BackdropAppBar({required this.detail});

  @override
  ConsumerState<_BackdropAppBar> createState() => _BackdropAppBarState();
}

class _BackdropAppBarState extends ConsumerState<_BackdropAppBar> {
  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      actions: [
        _RefreshButton(tmdbId: widget.detail.id),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: widget.detail.backdropUrl != null
            ? CachedNetworkImage(
                imageUrl: widget.detail.backdropUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    const ColoredBox(color: AppColors.surface),
                errorWidget: (_, __, ___) =>
                    const ColoredBox(color: AppColors.surface),
                imageBuilder: (_, img) => DecoratedBox(
                  decoration: BoxDecoration(
                    image: DecorationImage(image: img, fit: BoxFit.cover),
                  ),
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, AppColors.background],
                        stops: [0.5, 1.0],
                      ),
                    ),
                  ),
                ),
              )
            : const ColoredBox(color: AppColors.surface),
      ),
    );
  }
}

// ── Refresh button ────────────────────────────────────────────────────────────

class _RefreshButton extends ConsumerStatefulWidget {
  final int tmdbId;
  const _RefreshButton({required this.tmdbId});

  @override
  ConsumerState<_RefreshButton> createState() => _RefreshButtonState();
}

class _RefreshButtonState extends ConsumerState<_RefreshButton> {
  bool _refreshing = false;

  Future<void> _refresh() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);

    if (mounted) {
      AppToast.show('Aggiornamento dati...', type: ToastType.info);
    }

    try {
      await Future.wait([
        Future(() async {
          ref.invalidate(movieDetailProvider(widget.tmdbId));
        }),
        Future.delayed(const Duration(seconds: 3)),
      ]);

      if (mounted) {
        AppToast.show('Aggiornamento Completato', type: ToastType.success);
      }
    } catch (_) {
      if (mounted) {
        AppToast.show('Aggiornamento non riuscito', type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: IconButton(
        onPressed: _refreshing ? null : _refresh,
        tooltip: 'Aggiorna dati',
        icon: _refreshing
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.accent,
                ),
              )
            : const Icon(
                Icons.refresh_rounded,
                color: AppColors.textPrimary,
              ),
      ),
    );
  }
}

// ── Header (poster + meta) ────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final TmdbMovieDetail detail;
  const _Header({required this.detail});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Poster
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 90,
            height: 135,
            child: detail.posterUrl != null
                ? CachedNetworkImage(
                    imageUrl: detail.posterUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        const ColoredBox(color: AppColors.divider),
                  )
                : const ColoredBox(
                    color: AppColors.divider,
                    child: Icon(Icons.movie,
                        color: AppColors.textSecondary, size: 36),
                  ),
          ),
        ),
        const SizedBox(width: 14),
        // Testo
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                detail.title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (detail.year != null) ...[
                const SizedBox(height: 4),
                Text(
                  '${detail.year}',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
              if (detail.runtimeFormatted != null) ...[
                const SizedBox(height: 4),
                Text(
                  detail.runtimeFormatted!,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
              if (detail.genres.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  detail.genres.take(3).join(' · '),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
              if (detail.voteAverage != null && detail.voteAverage! > 0) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.star, color: AppColors.accent, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      detail.voteAverage!.toStringAsFixed(1),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ── Overview ──────────────────────────────────────────────────────────────────

class _Overview extends StatefulWidget {
  final String text;
  const _Overview({required this.text});

  @override
  State<_Overview> createState() => _OverviewState();
}

class _OverviewState extends State<_Overview> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.text,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
            maxLines: _expanded ? null : 3,
            overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            _expanded ? 'Mostra meno' : 'Mostra tutto',
            style: const TextStyle(color: AppColors.accent, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ── Track button ──────────────────────────────────────────────────────────────

class _TrackButton extends ConsumerStatefulWidget {
  final TmdbMovieDetail detail;
  final TrackedMovy? trackedMovie;
  const _TrackButton({required this.detail, required this.trackedMovie});

  @override
  ConsumerState<_TrackButton> createState() => _TrackButtonState();
}

class _TrackButtonState extends ConsumerState<_TrackButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final isTracked = widget.trackedMovie != null;

    return SizedBox(
      width: double.infinity,
      child: isTracked
          ? OutlinedButton.icon(
              onPressed: _loading ? null : _remove,
              icon: const Icon(Icons.remove_circle_outline,
                  color: Colors.redAccent),
              label: const Text(
                'Rimuovi dalla libreria',
                style: TextStyle(color: Colors.redAccent),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.redAccent),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            )
          : FilledButton.icon(
              onPressed: _loading ? null : _add,
              icon: _loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.black),
                    )
                  : const Icon(Icons.add, color: Colors.black),
              label: const Text(
                'Aggiungi alla libreria',
                style:
                    TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
    );
  }

  Future<void> _add() async {
    setState(() => _loading = true);
    try {
      await ref
          .read(trackedMoviesNotifierProvider.notifier)
          .addMovie(widget.detail);
    } catch (_) {
      AppToast.show('Impossibile aggiungere "${widget.detail.title}"');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _remove() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Rimuovi film?',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'Rimuoverai "${widget.detail.title}" dalla tua libreria.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Rimuovi',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _loading = true);
    try {
      await ref
          .read(trackedMoviesNotifierProvider.notifier)
          .removeMovie(widget.trackedMovie!.id);
    } catch (_) {
      AppToast.show('Impossibile rimuovere "${widget.detail.title}"');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

// ── Status selector ───────────────────────────────────────────────────────────

class _StatusSelector extends ConsumerWidget {
  final TrackedMovy trackedMovie;
  const _StatusSelector({required this.trackedMovie});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Per i film usiamo solo gli status rilevanti
    const movieStatuses = [
      MediaStatus.planToWatch,
      MediaStatus.watching,
      MediaStatus.completed,
      MediaStatus.dropped,
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: movieStatuses.map((s) {
          final selected = trackedMovie.status == s;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(s.label),
              selected: selected,
              selectedColor: AppColors.accent,
              backgroundColor: AppColors.surface,
              labelStyle: TextStyle(
                color:
                    selected ? Colors.black : AppColors.textSecondary,
                fontWeight:
                    selected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
              onSelected: (_) => ref
                  .read(trackedMoviesNotifierProvider.notifier)
                  .updateStatus(trackedMovie.id, s),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Error body ────────────────────────────────────────────────────────────────

class _ErrorBody extends StatelessWidget {
  final String error;
  const _ErrorBody({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
