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

  /// L'intero ShowData "congelato" durante l'animazione del pulsante.
  /// Impedisce che la card cambi numero episodi (+4 -> +3) o cambi episodio
  /// prima che l'animazione sia completata.
  ShowWithWatchedEpisodes? _lockedShowData;

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
    // Avanza alla stagione successiva solo se conosciamo il totale episodi
    // della stagione corrente (>0) e l'abbiamo superato. Per anime in onda
    // AniList può restituire episodes=null → episodeCount=0: in quel caso
    // 0 significa "totale ignoto", non "stagione vuota", quindi non saltiamo.
    final hasNextSeason = seasonCounts.containsKey(lastSeason + 1);
    if (countInSeason != null &&
        countInSeason > 0 &&
        nextEp > countInSeason &&
        hasNextSeason) {
      return (lastSeason + 1, 1);
    }
    return (lastSeason, nextEp);
  }

  Future<void> _markWatched(int season, int episode) async {
    if (_markState != _MarkState.idle) return;
    setState(() {
      _markState = _MarkState.marking;
      _lockedShowData = widget.showData; // congela l'intera card
    });
    
    final dao = ref.read(showsDaoProvider);
    final notifier = ref.read(trackedShowsNotifierProvider.notifier);
    final tmdbId = widget.showData.show.tmdbId;
    final showId = widget.showData.show.id;

    try {
      await dao.markEpisodeWatched(
            showId, season, episode,
            watched: true,
          );
      
      notifier.rescheduleNotificationById(tmdbId);
      
      if (!mounted) return;
      // Mantieni lo stato di caricamento fino a quando non mostriamo il successo
      setState(() => _markState = _MarkState.success);
      await Future.delayed(const Duration(milliseconds: 700));
      if (mounted) {
        setState(() {
          _markState = _MarkState.idle;
          _lockedShowData = null; // sblocca la card, permettendo l'aggiornamento visivo
        });
      }
    } catch (e) {
      AppToast.show('Errore: $e');
      if (mounted) {
        setState(() {
          _markState = _MarkState.idle;
          _lockedShowData = null;
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
    // Usa i dati congelati se presenti, altrimenti i dati in tempo reale
    final displayData = _lockedShowData ?? widget.showData;
    final show = displayData.show;
    final watchedBySeason = displayData.watchedBySeason;
    final watchedCount = displayData.watchedCount;
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

    final (nextSeason, nextEp) = _computeNext(watchedBySeason, seasonCounts);

    // Carica titolo e still dell'episodio dall'API (solo dati estetici).
    final seasonAsync = ref.watch(seasonDetailProvider(
      showId: show.tmdbId,
      seasonNumber: nextSeason,
    ));

    // Mentre i dati stagione non sono ancora disponibili mostriamo uno scheletro
    // della stessa forma della card finale: l'utente vede subito tutte le card
    // della lista (placeholder) e capisce che il caricamento è in corso.
    if (!seasonAsync.hasValue && !seasonAsync.hasError) {
      return const NextEpisodeSkeletonCard();
    }

    final loadedEpisodes = seasonAsync.valueOrNull?.episodes;
    final nextEpisode = loadedEpisodes
        ?.where((e) => e.episodeNumber == nextEp)
        .firstOrNull;

    // Se i dati della stagione sono caricati ma l'episodio non è ancora
    // uscito, non mostrare la card (l'episodio apparirà in "In Uscita").
    if (seasonAsync.hasValue && nextEpisode != null && !nextEpisode.hasAired) {
      return const SizedBox.shrink();
    }

    // Utente in pari con una stagione in onda: la stagione ha episodi
    // caricati ma l'episodio richiesto non esiste ancora. Nascondi la card,
    // l'episodio apparirà in "In Uscita" quando verrà rilasciato.
    if (seasonAsync.hasValue &&
        nextEpisode == null &&
        loadedEpisodes != null &&
        loadedEpisodes.isNotEmpty) {
      return const SizedBox.shrink();
    }

    final episodeTitle = nextEpisode?.name;
    final imageUrl = nextEpisode?.stillPath != null
        ? 'https://image.tmdb.org/t/p/w185${nextEpisode!.stillPath}'
        : show.posterPath != null
            ? 'https://image.tmdb.org/t/p/w185${show.posterPath}'
            : null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          padding: const EdgeInsets.all(16),
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
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            show.title,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          total != null ? '(+${total - watchedCount})' : '(+?)',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Consumer(
                      builder: (context, ref, _) {
                        final detail = ref.watch(showDetailProvider(show.tmdbId)).valueOrNull;
                        String? seasonName;
                        if (detail != null && detail.isAnime) {
                          final sSeason = detail.seasons.where((s) => s.seasonNumber == nextSeason).firstOrNull;
                          if (sSeason != null && sSeason.name != null) {
                            seasonName = sSeason.name!.split(' · ').first.trim();
                          }
                        }
                        return _EpisodeBadge(
                          season: nextSeason, 
                          episode: nextEp,
                          seasonName: seasonName,
                        );
                      },
                    ),
                    if (episodeTitle != null) ...[
                      const SizedBox(height: 5),
                      Text(
                        episodeTitle,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
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
        _MarkState.idle => Colors.transparent,
        _MarkState.marking => _green,
        _MarkState.success => _green,
      };

  Color get _iconColor =>
      state == _MarkState.idle ? AppColors.accent : Colors.white;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: state == _MarkState.idle ? onTap : () {},
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _bgColor,
          border: state == _MarkState.idle
              ? Border.all(
                  color: AppColors.accent.withAlpha(120),
                  width: 1.5,
                )
              : null,
        ),
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: Icon(
              Icons.check,
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

// Scheletro mostrato mentre i dati della stagione si caricano. Ricalca il
// layout della card reale (immagine + info + bottone circolare) così la lista
// appare subito completa e le card si "riempiono" sul posto.
class NextEpisodeSkeletonCard extends StatelessWidget {
  const NextEpisodeSkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: const SizedBox(
                width: 96,
                height: 80,
                child: ColoredBox(color: AppColors.divider),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _SkeletonLine(width: 140, height: 16),
                  SizedBox(height: 6),
                  _SkeletonLine(width: 60, height: 18),
                  SizedBox(height: 5),
                  _SkeletonLine(width: 160, height: 13),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.divider,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EpisodeBadge extends StatelessWidget {
  final int season;
  final int episode;
  final String? seasonName;
  const _EpisodeBadge({required this.season, required this.episode, this.seasonName});

  @override
  Widget build(BuildContext context) {
    String label;
    if (seasonName != null) {
      final baseName = seasonName!.split(' · ').first.trim();
      var abbr = baseName.replaceAll(RegExp(r'^(Stagione|Season)\s*', caseSensitive: false), 'S');
      abbr = abbr.replaceAll(RegExp(r'\s*Parte\s*', caseSensitive: false), ' P');
      // Aggiungi padding alla stagione se a una sola cifra (S1 -> S01)
      abbr = abbr.replaceAllMapped(RegExp(r'(S)(\d)(?!\d)'), (match) {
        return '${match.group(1)}0${match.group(2)}';
      });
      label = '$abbr E${episode.toString().padLeft(2, '0')}';
    } else {
      label = 'S${season.toString().padLeft(2, '0')} E${episode.toString().padLeft(2, '0')}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.divider.withAlpha(80),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
          fontSize: 11,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
