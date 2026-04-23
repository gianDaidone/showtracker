import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/services/app_toast.dart';
import '../../../core/theme/app_theme.dart';
import '../data/models/tmdb_show_detail.dart';
import '../providers/series_providers.dart';
import 'widgets/season_section.dart';

class ShowDetailScreen extends ConsumerWidget {
  final int tmdbId;
  const ShowDetailScreen({super.key, required this.tmdbId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(showDetailProvider(tmdbId));

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

class _DetailBody extends ConsumerStatefulWidget {
  final TmdbShowDetail detail;
  const _DetailBody({required this.detail});

  @override
  ConsumerState<_DetailBody> createState() => _DetailBodyState();
}

class _DetailBodyState extends ConsumerState<_DetailBody> {
  @override
  void initState() {
    super.initState();
    // Reschedule anime notification once when the detail page opens so that
    // stale cached nextAiringEpisode data doesn't block scheduling.
    if (widget.detail.isAnime && widget.detail.animeSeasonsData != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref
            .read(trackedShowsNotifierProvider.notifier)
            .rescheduleNotification(widget.detail);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = widget.detail;
    final trackedList =
        ref.watch(trackedShowsNotifierProvider).valueOrNull ?? [];
    final TrackedShow? trackedShow =
        trackedList.where((s) => s.tmdbId == detail.id).firstOrNull;

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
                _TrackButton(detail: detail, trackedShow: trackedShow),
                if (trackedShow != null) ...[
                  const SizedBox(height: 8),
                  _StatusSelector(trackedShow: trackedShow),
                ],
                const SizedBox(height: 24),
                const Text(
                  'Stagioni',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
        if (detail.seasons.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Nessuna stagione disponibile.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          )
        else
          SliverList.builder(
            itemCount: detail.seasons.length,
            itemBuilder: (_, i) => SeasonSection(
              detail: detail,
              season: detail.seasons[i],
              trackedShow: trackedShow,
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }
}

// ── Backdrop AppBar ───────────────────────────────────────────────────────────

class _BackdropAppBar extends StatelessWidget {
  final TmdbShowDetail detail;
  const _BackdropAppBar({required this.detail});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: detail.backdropUrl != null
            ? CachedNetworkImage(
                imageUrl: detail.backdropUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) => const ColoredBox(color: AppColors.surface),
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

// ── Header (poster + meta) ────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final TmdbShowDetail detail;
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
                    child: Icon(Icons.tv, color: AppColors.textSecondary, size: 36),
                  ),
          ),
        ),
        const SizedBox(width: 14),
        // Testo
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      detail.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (detail.isAnime) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withAlpha(30),
                        border: Border.all(
                            color: AppColors.accent.withAlpha(150)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'ANIME',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (detail.year != null) ...[
                const SizedBox(height: 4),
                Text(
                  '${detail.year}',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
              const SizedBox(height: 6),
              Text(
                detail.statusLabel,
                style: const TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 6),
              _MetaRow(detail: detail),
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

class _MetaRow extends StatelessWidget {
  final TmdbShowDetail detail;
  const _MetaRow({required this.detail});

  @override
  Widget build(BuildContext context) {
    final parts = <String>[
      if (detail.numberOfSeasons != null)
        '${detail.numberOfSeasons} stagion${detail.numberOfSeasons == 1 ? "e" : "i"}',
      if (detail.numberOfEpisodes != null)
        '${detail.numberOfEpisodes} episodi',
    ];
    if (parts.isEmpty) return const SizedBox.shrink();
    return Text(
      parts.join(' · '),
      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
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
  final TmdbShowDetail detail;
  final TrackedShow? trackedShow;
  const _TrackButton({required this.detail, required this.trackedShow});

  @override
  ConsumerState<_TrackButton> createState() => _TrackButtonState();
}

class _TrackButtonState extends ConsumerState<_TrackButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final isTracked = widget.trackedShow != null;

    return SizedBox(
      width: double.infinity,
      child: isTracked
          ? OutlinedButton.icon(
              onPressed: _loading ? null : _remove,
              icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
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
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Icon(Icons.add, color: Colors.black),
              label: const Text(
                'Aggiungi alla libreria',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
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
          .read(trackedShowsNotifierProvider.notifier)
          .addShow(widget.detail);
    } catch (e) {
      AppToast.show('Impossibile aggiungere "${widget.detail.name}"');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _remove() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Rimuovi serie?',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'Rimuoverai "${widget.detail.name}" e tutti i progressi episodi salvati.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Rimuovi', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _loading = true);
    try {
      await ref
          .read(trackedShowsNotifierProvider.notifier)
          .removeShow(widget.trackedShow!.id);
    } catch (_) {
      AppToast.show('Impossibile rimuovere "${widget.detail.name}"');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

// ── Status selector ───────────────────────────────────────────────────────────

class _StatusSelector extends ConsumerWidget {
  final TrackedShow trackedShow;
  const _StatusSelector({required this.trackedShow});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: MediaStatus.values.map((s) {
          final selected = trackedShow.status == s;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(s.label),
              selected: selected,
              selectedColor: AppColors.accent,
              backgroundColor: AppColors.surface,
              labelStyle: TextStyle(
                color: selected ? Colors.black : AppColors.textSecondary,
                fontWeight:
                    selected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
              onSelected: (_) => ref
                  .read(trackedShowsNotifierProvider.notifier)
                  .updateStatus(trackedShow.id, s),
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
