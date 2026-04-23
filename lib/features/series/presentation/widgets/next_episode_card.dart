import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/services/app_toast.dart';
import '../../../../core/theme/app_theme.dart';
import '../../providers/series_providers.dart';
import 'episode_detail_sheet.dart';

// ── Stati del pulsante ────────────────────────────────────────────────────────

enum _MarkState { idle, marking, success }

// ── Card principale ───────────────────────────────────────────────────────────

class NextEpisodeCard extends ConsumerStatefulWidget {
  final ShowWithWatchedEpisodes showData;
  const NextEpisodeCard({super.key, required this.showData});

  @override
  ConsumerState<NextEpisodeCard> createState() => _NextEpisodeCardState();
}

class _NextEpisodeCardState extends ConsumerState<NextEpisodeCard> {
  _MarkState _markState = _MarkState.idle;

  /// Episodio "congelato" durante l'animazione del pulsante.
  /// Non-null finché il pulsante non torna a idle, impedisce che la card
  /// salti all'episodio successivo prima che l'animazione sia completata.
  (int season, int episode)? _lockedEpisode;

  /// Calcola il prossimo episodio da guardare.
  /// [seasonCounts] è la mappa stagione→episodeCount dal DB locale:
  /// consente di rilevare l'overflow di stagione senza alcuna chiamata API.
  (int season, int episode) _computeNext(
    Map<int, Set<int>> watched,
    Map<int, int> seasonCounts,
  ) {
    if (watched.isEmpty) return (1, 1);
    final lastSeason = watched.keys.reduce((a, b) => a > b ? a : b);
    final lastEp = watched[lastSeason]!.reduce((a, b) => a > b ? a : b);
    final nextEp = lastEp + 1;
    final countInSeason = seasonCounts[lastSeason];
    // Se conosciamo il numero di episodi della stagione e lo abbiamo superato,
    // passiamo alla stagione successiva.
    if (countInSeason != null && nextEp > countInSeason) {
      return (lastSeason + 1, 1);
    }
    return (lastSeason, nextEp);
  }

  Future<void> _markWatched(int season, int episode) async {
    if (_markState != _MarkState.idle) return;
    setState(() {
      _markState = _MarkState.marking;
      _lockedEpisode = (season, episode); // congela la card sull'episodio corrente
    });
    try {
      await ref.read(showsDaoProvider).markEpisodeWatched(
            widget.showData.show.id, season, episode,
            watched: true,
          );
      if (!mounted) return;
      setState(() => _markState = _MarkState.success);
      await Future.delayed(const Duration(milliseconds: 700));
      if (mounted) {
        setState(() {
          _markState = _MarkState.idle;
          _lockedEpisode = null; // sblocca: lo stream aggiorna la card
        });
      }
    } catch (_) {
      AppToast.show('Impossibile aggiornare l\'episodio');
      if (mounted) {
        setState(() {
          _markState = _MarkState.idle;
          _lockedEpisode = null;
        });
      }
    }
  }

  Future<void> _markCompleted() async {
    await ref
        .read(trackedShowsNotifierProvider.notifier)
        .updateStatus(widget.showData.show.id, MediaStatus.completed);
  }

  @override
  Widget build(BuildContext context) {
    final show = widget.showData.show;
    final watchedBySeason = widget.showData.watchedBySeason;
    final watchedCount = widget.showData.watchedCount;
    final total = show.totalEpisodes;

    // ── Tutti gli episodi visti ────────────────────────────────────────────
    if (total != null && watchedCount >= total) {
      return _CardShell(
        show: show,
        loading: false,
        child: _CompletedContent(
          show: show,
          watchedCount: watchedCount,
          onMarkCompleted: _markCompleted,
        ),
      );
    }

    // ── Prossimo episodio ──────────────────────────────────────────────────
    // seasonCounts viene dal DB locale: nessuna chiamata API per
    // determinare il numero di stagione/episodio corretto.
    final seasonCounts =
        ref.watch(seasonEpisodeCountsProvider(show.id)).valueOrNull ?? {};

    final (nextSeason, nextEp) =
        _lockedEpisode ?? _computeNext(watchedBySeason, seasonCounts);

    // Carica titolo e still dell'episodio dall'API (solo dati estetici).
    final seasonAsync = ref.watch(seasonDetailProvider(
      showId: show.tmdbId,
      seasonNumber: nextSeason,
    ));

    // Mentre i dati stagione non sono ancora disponibili non mostriamo nulla:
    // evita che la card appaia come skeleton e poi sparisca se l'episodio
    // non è ancora uscito. Le card "pop in" solo quando sappiamo cosa mostrare.
    if (!seasonAsync.hasValue && !seasonAsync.hasError) {
      return const SizedBox.shrink();
    }

    final nextEpisode = seasonAsync
        .valueOrNull
        ?.episodes
        ?.where((e) => e.episodeNumber == nextEp)
        .firstOrNull;

    // Se i dati della stagione sono caricati ma l'episodio non è ancora
    // uscito, non mostrare la card (l'episodio apparirà in "In Uscita").
    if (seasonAsync.hasValue && nextEpisode != null && !nextEpisode.hasAired) {
      return const SizedBox.shrink();
    }

    final episodeTitle = nextEpisode?.name;
    final imageUrl = nextEpisode?.stillPath != null
        ? 'https://image.tmdb.org/t/p/w185${nextEpisode!.stillPath}'
        : show.posterPath != null
            ? 'https://image.tmdb.org/t/p/w185${show.posterPath}'
            : null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: () {
          if (nextEpisode != null) {
            showEpisodeDetailSheet(
              context,
              showTitle: show.title,
              showTmdbId: show.tmdbId,
              showPosterPath: show.posterPath,
              trackedShow: show,
              season: nextSeason,
              episodeNum: nextEp,
              episode: nextEpisode,
            );
          } else {
            context.push('/series/detail/${show.tmdbId}');
          }
        },
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Immagine episodio / poster ───────────────────────────
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 96,
                  height: 80,
                  child: imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              const ColoredBox(color: AppColors.divider),
                          errorWidget: (_, __, ___) => const _ImageFallback(),
                        )
                      : const _ImageFallback(),
                ),
              ),
              const SizedBox(width: 12),

              // ── Informazioni episodio ────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      show.title,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    _EpisodeBadge(season: nextSeason, episode: nextEp),
                    if (episodeTitle != null) ...[
                      const SizedBox(height: 5),
                      Text(
                        episodeTitle,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // ── Pulsante circolare ───────────────────────────────────
              _CircularMarkButton(
                state: _markState,
                onTap: () => _markWatched(nextSeason, nextEp),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Pulsante circolare ────────────────────────────────────────────────────────

class _CircularMarkButton extends StatelessWidget {
  final _MarkState state;
  final VoidCallback onTap;

  const _CircularMarkButton({required this.state, required this.onTap});

  static const _green = Color(0xFF4CAF50);

  Color get _bgColor => switch (state) {
        _MarkState.idle => AppColors.divider,
        _MarkState.marking => _green,
        _MarkState.success => AppColors.accent,
      };

  Color get _iconColor =>
      state == _MarkState.idle ? AppColors.textSecondary : Colors.white;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: state == _MarkState.idle ? onTap : () {},
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _bgColor,
          border: state == _MarkState.idle
              ? Border.all(
                  color: AppColors.textSecondary.withAlpha(80),
                  width: 1.5,
                )
              : null,
        ),
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: state == _MarkState.marking
                ? const CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  )
                : Icon(
                    state == _MarkState.success
                        ? Icons.check_circle
                        : Icons.check,
                    size: 18,
                    color: _iconColor,
                  ),
          ),
        ),
      ),
    );
  }
}

// ── Stato "tutti gli episodi visti" ──────────────────────────────────────────

class _CompletedContent extends StatelessWidget {
  final TrackedShow show;
  final int watchedCount;
  final VoidCallback onMarkCompleted;

  const _CompletedContent({
    required this.show,
    required this.watchedCount,
    required this.onMarkCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          show.title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 15),
            const SizedBox(width: 6),
            Text(
              'Tutti i ${show.totalEpisodes} episodi visti',
              style: const TextStyle(
                color: Color(0xFF4CAF50),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 36,
          child: OutlinedButton.icon(
            onPressed: onMarkCompleted,
            icon: const Icon(Icons.done_all, size: 16),
            label: const Text(
              'Segna come Completata',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF4CAF50),
              side: const BorderSide(color: Color(0xFF4CAF50)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Shell (loading / completed) ───────────────────────────────────────────────

class _CardShell extends StatelessWidget {
  final TrackedShow show;
  final bool loading;
  final Widget? child;

  const _CardShell({required this.show, required this.loading, this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: () => context.push('/series/detail/${show.tmdbId}'),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: loading
                    // Skeleton: stesso formato dell'immagine episodio (96×80)
                    ? const SizedBox(
                        width: 96,
                        height: 80,
                        child: ColoredBox(color: AppColors.divider),
                      )
                    // Stato completato: poster serie (54×80)
                    : SizedBox(
                        width: 54,
                        height: 80,
                        child: show.posterPath != null
                            ? CachedNetworkImage(
                                imageUrl:
                                    'https://image.tmdb.org/t/p/w185${show.posterPath}',
                                fit: BoxFit.cover,
                                placeholder: (_, __) =>
                                    const ColoredBox(color: AppColors.divider),
                                errorWidget: (_, __, ___) =>
                                    const _ImageFallback(),
                              )
                            : const _ImageFallback(),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: loading
                    ? const _LoadingPlaceholder()
                    : (child ?? const SizedBox.shrink()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Widget di supporto ────────────────────────────────────────────────────────

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();
  @override
  Widget build(BuildContext context) => const ColoredBox(
        color: AppColors.divider,
        child: Center(
          child: Icon(Icons.tv, color: AppColors.textSecondary, size: 24),
        ),
      );
}

class _LoadingPlaceholder extends StatelessWidget {
  const _LoadingPlaceholder();
  @override
  Widget build(BuildContext context) => const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 8),
          _SkeletonLine(width: 140),
          SizedBox(height: 8),
          _SkeletonLine(width: 80),
          SizedBox(height: 10),
          _SkeletonLine(width: double.infinity, height: 36),
        ],
      );
}

class _SkeletonLine extends StatelessWidget {
  final double width;
  final double height;
  const _SkeletonLine({required this.width, this.height = 14});
  @override
  Widget build(BuildContext context) => Container(
        width: width == double.infinity ? null : width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.divider,
          borderRadius: BorderRadius.circular(6),
        ),
      );
}

class _EpisodeBadge extends StatelessWidget {
  final int season;
  final int episode;
  const _EpisodeBadge({required this.season, required this.episode});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.accent.withAlpha(30),
        border: Border.all(color: AppColors.accent.withAlpha(120)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'S${season.toString().padLeft(2, '0')}'
        'E${episode.toString().padLeft(2, '0')}',
        style: const TextStyle(
          color: AppColors.accent,
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
