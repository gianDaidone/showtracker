import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/services/app_toast.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/tmdb_episode.dart';
import '../../providers/series_providers.dart';

// ── Funzione pubblica: segna visto con controllo precedenti ──────────────────

/// Segna [targetEpisode]/[targetSeason] come visto.
/// Se ci sono episodi precedenti non visti mostra una modale che chiede
/// se segnare solo questo o anche tutti i precedenti.
Future<void> markEpisodeWatchedWithCheck(
  BuildContext context,
  WidgetRef ref, {
  required int showId,
  required int targetSeason,
  required int targetEpisode,
}) async {
  final dao = ref.read(showsDaoProvider);
  final hasMissing = await dao.hasMissingPreviousEpisodes(
    showId, targetSeason, targetEpisode,
  );
  if (!context.mounted) return;

  bool markAll = false;
  if (hasMissing) {
    final choice = await showDialog<bool>(
      context: context,
      builder: (_) => const _PreviousEpisodesDialog(),
    );
    if (choice == null || !context.mounted) return;
    markAll = choice;
  }

  if (markAll) {
    await dao.markAllPreviousEpisodesWatched(showId, targetSeason, targetEpisode);
  }
  await dao.markEpisodeWatched(showId, targetSeason, targetEpisode, watched: true);
}

// ── Funzione pubblica per aprire il sheet ─────────────────────────────────────

void showEpisodeDetailSheet(
  BuildContext context, {
  required String showTitle,
  required int showTmdbId,
  required String? showPosterPath,
  required int season,
  required int episodeNum,
  required TmdbEpisode episode,
  String? seasonName,
  // Null se la serie non è ancora tracciata (il pulsante segna non compare)
  TrackedShow? trackedShow,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _EpisodeDetailSheet(
      showTitle: showTitle,
      showTmdbId: showTmdbId,
      showPosterPath: showPosterPath,
      trackedShow: trackedShow,
      season: season,
      episodeNum: episodeNum,
      episode: episode,
      seasonName: seasonName,
    ),
  );
}

// ── Sheet principale ──────────────────────────────────────────────────────────

class _EpisodeDetailSheet extends ConsumerStatefulWidget {
  final String showTitle;
  final int showTmdbId;
  final String? showPosterPath;
  final TrackedShow? trackedShow;
  final int season;
  final int episodeNum;
  final TmdbEpisode episode;
  final String? seasonName;

  const _EpisodeDetailSheet({
    required this.showTitle,
    required this.showTmdbId,
    required this.showPosterPath,
    required this.trackedShow,
    required this.season,
    required this.episodeNum,
    required this.episode,
    this.seasonName,
  });

  @override
  ConsumerState<_EpisodeDetailSheet> createState() =>
      _EpisodeDetailSheetState();
}

class _EpisodeDetailSheetState extends ConsumerState<_EpisodeDetailSheet> {
  bool _isLoading = false;

  /// Valore ottimistico locale: non-null mentre un write è in volo e finché
  /// lo stream non conferma il nuovo valore. Previene il flicker tra il
  /// completamento della scrittura DB e l'emissione dello stream Drift.
  bool? _localWatched;

  /// Restituisce lo stato effettivo: usa il valore locale se disponibile,
  /// altrimenti legge dallo stream.
  bool _isWatched(Map<int, Set<int>> watchedMap) =>
      _localWatched ?? (watchedMap[widget.season]?.contains(widget.episodeNum) ?? false);

  /// Toggle: se visto → segna non visto, se non visto → segna visto.
  /// Quando si segna come visto controlla gli episodi precedenti e mostra
  /// la modale se ce ne sono di non visti.
  Future<void> _toggle(bool currentlyWatched) async {
    if (_isLoading || widget.trackedShow == null) return;
    final nextWatched = !currentlyWatched;

    if (!nextWatched) {
      // Deseleziona: nessun controllo, aggiornamento ottimistico immediato.
      setState(() { _isLoading = true; _localWatched = false; });
      try {
        await ref.read(showsDaoProvider).markEpisodeWatched(
          widget.trackedShow!.id, widget.season, widget.episodeNum, watched: false,
        );
      } catch (_) {
        AppToast.show('Impossibile aggiornare l\'episodio');
        if (mounted) setState(() => _localWatched = null);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
      return;
    }

    // Seleziona: aggiornamento ottimistico immediato
    setState(() {
      _isLoading = true;
      _localWatched = true;
    });
    try {
      final dao = ref.read(showsDaoProvider);
      final hasMissing = await dao.hasMissingPreviousEpisodes(
        widget.trackedShow!.id, widget.season, widget.episodeNum,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      bool markAll = false;
      if (hasMissing) {
        final choice = await showDialog<bool>(
          context: context,
          builder: (_) => const _PreviousEpisodesDialog(),
        );
        if (choice == null || !mounted) {
          setState(() => _localWatched = null); // revert
          return;
        }
        markAll = choice;
      }

      setState(() { _isLoading = true; _localWatched = true; });

      if (markAll) {
        await dao.markAllPreviousEpisodesWatched(
          widget.trackedShow!.id, widget.season, widget.episodeNum,
        );
      }
      await dao.markEpisodeWatched(
        widget.trackedShow!.id, widget.season, widget.episodeNum, watched: true,
      );
    } catch (_) {
      AppToast.show('Impossibile aggiornare l\'episodio');
      if (mounted) setState(() => _localWatched = null);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String? get _imageUrl {
    if (widget.episode.stillPath != null) {
      return 'https://image.tmdb.org/t/p/w780${widget.episode.stillPath}';
    }
    if (widget.showPosterPath != null) {
      return 'https://image.tmdb.org/t/p/w500${widget.showPosterPath}';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // Stato visto letto in tempo reale dal DB
    final watchedMap = widget.trackedShow != null
        ? ref
                .watch(watchedEpisodesBySeasonProvider(widget.trackedShow!.id))
                .valueOrNull ??
            {}
        : <int, Set<int>>{};

    // Quando lo stream conferma il valore ottimistico, azzera il locale.
    // Siamo già dentro build(), non serve setState.
    final streamWatched =
        watchedMap[widget.season]?.contains(widget.episodeNum) ?? false;
    if (_localWatched != null && _localWatched == streamWatched) {
      _localWatched = null;
    }

    final isWatched = _isWatched(watchedMap);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.87,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Immagine header ──────────────────────────────────────────────
          _ImageHeader(
            imageUrl: _imageUrl,
            onClose: () => Navigator.pop(context),
          ),

          // ── Contenuto scrollabile ────────────────────────────────────────
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: widget.trackedShow != null ? 16 : MediaQuery.of(context).padding.bottom + 24,
              ),
              child: _ContentArea(
                showTitle: widget.showTitle,
                showTmdbId: widget.showTmdbId,
                season: widget.season,
                episodeNum: widget.episodeNum,
                episode: widget.episode,
                seasonName: widget.seasonName,
                onNavigate: () {
                  Navigator.pop(context);
                  context.push('/series/detail/${widget.showTmdbId}');
                },
              ),
            ),
          ),

          // ── Action Button (Segna/Visto) a fine modale ────────────────────
          if (widget.trackedShow != null)
            Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(context).padding.bottom > 0
                    ? MediaQuery.of(context).padding.bottom + 8
                    : 24,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _toggle(isWatched),
                  style: FilledButton.styleFrom(
                    backgroundColor: isWatched
                        ? AppColors.accent
                        : Colors.white.withValues(alpha: 0.08),
                    foregroundColor:
                        isWatched ? Colors.white : AppColors.textPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: isWatched
                          ? BorderSide.none
                          : BorderSide(
                              color: AppColors.textSecondary.withValues(alpha: 0.3)),
                    ),
                  ),
                  icon: Icon(
                    isWatched ? Icons.check_circle : Icons.check,
                    color: isWatched
                        ? Colors.white
                        : AppColors.textPrimary,
                  ),
                  label: Text(
                    isWatched ? 'Visto' : 'Segna come Visto',
                    style: TextStyle(
                      color: isWatched ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
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

// ── Immagine con pulsanti sovrapposti ─────────────────────────────────────────

class _ImageHeader extends StatelessWidget {
  final String? imageUrl;
  final VoidCallback onClose;

  const _ImageHeader({
    required this.imageUrl,
    required this.onClose,
  });

  static const _imgHeight = 210.0;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: SizedBox(
        height: _imgHeight,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Immagine di sfondo
            if (imageUrl != null)
              CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    const ColoredBox(color: AppColors.background),
                errorWidget: (_, __, ___) => const _ImageFallback(),
              )
            else
              const _ImageFallback(),

            // Gradiente in basso
            const Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 80,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [AppColors.surface, Colors.transparent],
                  ),
                ),
              ),
            ),

            // Pulsante chiudi (alto sinistra)
            Positioned(
              top: 14,
              left: 14,
              child: GestureDetector(
                onTap: onClose,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(178),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close,
                      color: AppColors.accent, size: 22),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Contenuto testuale ────────────────────────────────────────────────────────

class _ContentArea extends StatelessWidget {
  final String showTitle;
  final int showTmdbId;
  final int season;
  final int episodeNum;
  final TmdbEpisode episode;
  final String? seasonName;
  final VoidCallback onNavigate;

  const _ContentArea({
    required this.showTitle,
    required this.showTmdbId,
    required this.season,
    required this.episodeNum,
    required this.episode,
    this.seasonName,
    required this.onNavigate,
  });

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      const months = [
        'gennaio', 'febbraio', 'marzo', 'aprile', 'maggio', 'giugno',
        'luglio', 'agosto', 'settembre', 'ottobre', 'novembre', 'dicembre',
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    String pad(int n) => n.toString().padLeft(2, '0');
    String label;
    if (seasonName != null) {
      final baseName = seasonName!.split(' · ').first.trim();
      var abbr = baseName.replaceAll(RegExp(r'^(Stagione|Season)\s*', caseSensitive: false), 'S');
      abbr = abbr.replaceAll(RegExp(r'\s*Parte\s*', caseSensitive: false), ' P');
      abbr = abbr.replaceAllMapped(RegExp(r'(S)(\d)(?!\d)'), (match) {
        return '${match.group(1)}0${match.group(2)}';
      });
      label = '$abbr E${pad(episodeNum)}';
    } else {
      label = 'S${pad(season)} E${pad(episodeNum)}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titolo serie → navigazione
        GestureDetector(
          onTap: onNavigate,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  showTitle,
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 2),
              const Icon(Icons.chevron_right,
                  color: AppColors.accent, size: 18),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Badge S##E##
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.accent.withAlpha(30),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.accent,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Titolo episodio
        Text(
          episode.name,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 14),

        // Info row: data | rating
        Row(
          children: [
            if (episode.airDate != null) ...[
              const Icon(Icons.calendar_today_outlined,
                  size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                _formatDate(episode.airDate!),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
            if (episode.airDate != null && (episode.voteAverage ?? 0) > 0)
              const SizedBox(width: 16),
            if ((episode.voteAverage ?? 0) > 0) ...[
              const Icon(Icons.star_rounded,
                  size: 16, color: AppColors.accent),
              const SizedBox(width: 4),
              Text(
                episode.voteAverage!.toStringAsFixed(1),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const Text(
                '/10',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ],
        ),
        const SizedBox(height: 24),

        const Divider(color: AppColors.divider, height: 1),
        const SizedBox(height: 24),

        // Trama
        const Text(
          'Trama',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _Overview(
          text: (episode.overview?.isNotEmpty ?? false)
              ? episode.overview!
              : 'Nessuna descrizione disponibile per questo episodio.',
        ),
      ],
    );
  }
}

// ── Trama Espandibile ─────────────────────────────────────────────────────────

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
              height: 1.8,
            ),
            maxLines: _expanded ? null : 4,
            overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            _expanded ? 'Mostra meno' : 'Mostra tutto',
            style: const TextStyle(
              color: AppColors.accent,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Dialog: episodi precedenti non visti ─────────────────────────────────────

class _PreviousEpisodesDialog extends StatelessWidget {
  const _PreviousEpisodesDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text(
        'Episodi precedenti',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: const Text(
        'Ci sono episodi precedenti non ancora segnati come visti. Vuoi segnare anche loro?',
        style: TextStyle(color: AppColors.textSecondary, height: 1.5),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text(
            'Solo questo',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.black,
          ),
          child: const Text(
            'Segna tutti i precedenti',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

// ── Fallback immagine ─────────────────────────────────────────────────────────

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) => const ColoredBox(
        color: AppColors.background,
        child: Center(
          child: Icon(Icons.tv, color: AppColors.textSecondary, size: 48),
        ),
      );
}
