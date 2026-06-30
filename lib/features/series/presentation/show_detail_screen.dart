import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/services/app_toast.dart';
import '../../../core/widgets/animated_refresh_button.dart';
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

    // Mantieni i dati precedenti durante un refresh (es. quando l'utente
    // tocca l'icona "Aggiorna dati anime"): la pagina resta visibile e
    // l'icona stessa mostra lo spinner finché non arrivano i dati nuovi.
    final detail = detailAsync.valueOrNull;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: detail != null
          ? _DetailBody(detail: detail)
          : detailAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.accent),
              ),
              error: (e, _) => _ErrorBody(error: e.toString()),
              data: (_) => const SizedBox.shrink(),
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
  void didUpdateWidget(_DetailBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Quando i dati anime arrivano per la prima volta dopo un refresh
    // (animeSeasonsData passa da null a popolato), riprogramma la notifica
    // con l'orario preciso AniList: initState non si rinnova sui rebuild.
    final wasMissing = oldWidget.detail.animeSeasonsData == null;
    final isPresent = widget.detail.animeSeasonsData != null;
    if (widget.detail.isAnime && wasMissing && isPresent) {
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
                _TrackButton(detail: detail, trackedShow: trackedShow),
                if (trackedShow != null) ...[
                  const SizedBox(height: 8),
                  _StatusSelector(trackedShow: trackedShow),
                ],
                const SizedBox(height: 24),
                _InfoBox(detail: detail),
                const SizedBox(height: 24),
                if (detail.overview?.isNotEmpty == true) ...[
                  const Text(
                    'Trama',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _Overview(text: detail.overview!),
                  const SizedBox(height: 24),
                ],
                const Text(
                  'Episodi',
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
        if (trackedShow != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: _RemoveShowButton(detail: detail, trackedShow: trackedShow),
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
      actions: [
        _RefreshButton(tmdbId: detail.id, isAnime: detail.isAnime),
      ],
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

// ── Refresh button ────────────────────────────────────────────────────────────

class _RefreshButton extends ConsumerStatefulWidget {
  final int tmdbId;
  final bool isAnime;
  const _RefreshButton({required this.tmdbId, required this.isAnime});

  @override
  ConsumerState<_RefreshButton> createState() => _RefreshButtonState();
}

class _RefreshButtonState extends ConsumerState<_RefreshButton> {
  RefreshState _state = RefreshState.idle;

  Future<void> _refresh() async {
    if (_state != RefreshState.idle) return;
    setState(() => _state = RefreshState.refreshing);

    try {
      await Future.wait([
        Future(() async {
          // Clear standard TMDB episode cache so we fetch fresh data.
          await ref.read(cacheDaoProvider).clearCacheForShow(widget.tmdbId);
          
          if (widget.isAnime) {
            await ref
                .read(animeCacheDaoProvider)
                .clearAnimeCacheForShow(widget.tmdbId);
            ref.invalidate(animeDataProvider(widget.tmdbId));
          }
          // The invalidate might not be async, but Future.wait takes futures.
          // Reading the provider future forces us to wait for it to resolve
          // if we wanted to await the new data. However, ref.invalidate is sync.
          // Let's just do it inside this future block so we don't block the UI thread.
          ref.invalidate(showDetailProvider(widget.tmdbId));
        }),
        Future.delayed(const Duration(milliseconds: 1500)),
      ]);

      if (mounted) {
        setState(() => _state = RefreshState.success);
        await Future.delayed(const Duration(milliseconds: 1500));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _state = RefreshState.error);
        await Future.delayed(const Duration(milliseconds: 1500));
      }
    } finally {
      if (mounted) setState(() => _state = RefreshState.idle);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedRefreshButton(
      state: _state,
      onPressed: _refresh,
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
              Text(
                detail.name,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (detail.voteAverage != null && detail.voteAverage! > 0)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: AppColors.accent, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          detail.voteAverage!.toStringAsFixed(1),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  if (detail.year != null)
                    Text(
                      '${detail.year}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  if (detail.isAnime)
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
              ),
              if (detail.genres.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: detail.genres.map((g) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.divider.withAlpha(80),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      g,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )).toList(),
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
    if (widget.trackedShow != null) return const SizedBox.shrink();

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
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
}

// ── Remove button (Secondary Action) ──────────────────────────────────────────

class _RemoveShowButton extends ConsumerStatefulWidget {
  final TmdbShowDetail detail;
  final TrackedShow trackedShow;
  const _RemoveShowButton({required this.detail, required this.trackedShow});

  @override
  ConsumerState<_RemoveShowButton> createState() => _RemoveShowButtonState();
}

class _RemoveShowButtonState extends ConsumerState<_RemoveShowButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton.icon(
        onPressed: _loading ? null : _remove,
        icon: const Icon(Icons.delete_outline, size: 18),
        label: const Text('Rimuovi dalla libreria'),
        style: TextButton.styleFrom(
          foregroundColor: Colors.redAccent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ),
    );
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
          .removeShow(widget.trackedShow.id);
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
          return GestureDetector(
            onTap: () => ref
                .read(trackedShowsNotifierProvider.notifier)
                .updateStatus(trackedShow.id, s),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? AppColors.divider.withAlpha(120) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: selected ? null : Border.all(color: AppColors.divider.withAlpha(50)),
              ),
              child: Text(
                s.label,
                style: TextStyle(
                  color: selected ? AppColors.accent : AppColors.textSecondary,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
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

// ── Info Box ──────────────────────────────────────────────────────────────────

class _InfoBox extends StatelessWidget {
  final TmdbShowDetail detail;
  const _InfoBox({required this.detail});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    final s = detail.statusLabel.toLowerCase();
    if (s.contains('corso') || s.contains('returning') || s.contains('airing')) {
      statusColor = Colors.greenAccent;
    } else if (s.contains('terminat') || s.contains('ended') || s.contains('completa')) {
      statusColor = Colors.blueAccent;
    } else if (s.contains('cancellat') || s.contains('eliminat') || s.contains('canceled')) {
      statusColor = Colors.redAccent;
    } else {
      statusColor = Colors.orangeAccent;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _InfoItem(
            label: 'Stagioni',
            value: '${detail.numberOfSeasons ?? "-"}',
          ),
          _InfoItem(
            label: 'Episodi',
            value: '${detail.numberOfEpisodes ?? "-"}',
          ),
          Column(
            children: [
              const Text(
                'Stato',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                detail.statusLabel,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  const _InfoItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
