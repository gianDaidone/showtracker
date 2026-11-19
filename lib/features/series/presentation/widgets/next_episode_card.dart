import '../../../../core/widgets/media_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/services/app_toast.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/watch_next_rules.dart';
import '../../providers/series_providers.dart';
import 'episode_code_badge.dart';
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

  bool _resyncRequested = false;

  /// Chiede a [visibleWatchingShowsProvider] di ricalcolare la lista.
  ///
  /// Il provider decide la visibilità sui soli dati locali; qui possiamo avere
  /// dati TMDB più freschi — appena scaricati da `seasonDetail`, che li ha anche
  /// scritti in cache — e concludere che l'episodio non è ancora uscito. Se la
  /// card si nascondesse in silenzio l'intestazione continuerebbe a contarla
  /// ("Da Vedere (1)" senza nessuna card sotto): il ricalcolo, ora che la cache
  /// è aggiornata, arriva alla stessa conclusione e il conteggio si allinea.
  ///
  /// Una sola richiesta per card, così non si innescano cicli di invalidazione.
  void _requestVisibilityResync() {
    if (_resyncRequested) return;
    _resyncRequested = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.invalidate(visibleWatchingShowsProvider);
    });
  }

  Future<void> _markWatched(int season, int episode) async {
    if (_markState != _MarkState.idle) return;
    final dao = ref.read(showsDaoProvider);
    final notifier = ref.read(trackedShowsProvider.notifier);
    final show = widget.showData.show;
    setState(() {
      _markState = _MarkState.marking;
      _lockedShowData = widget.showData; // congela l'intera card
    });

    // Mostriamo un piccolo ritardo fittizio per dare feedback visivo
    await Future.delayed(const Duration(milliseconds: 200));

    if (mounted) {
      setState(() => _markState = _MarkState.success);
    }

    // Diamo il tempo all'animazione del check verde di completarsi
    await Future.delayed(const Duration(milliseconds: 700));

    try {
      final saved = await dao.transaction(() async {
        if (await dao.getById(show.id) == null) return false;
        await dao.markEpisodeWatched(show.id, season, episode);
        return true;
      });
      if (saved) notifier.rescheduleNotificationById(show.tmdbId);

      if (mounted) {
        setState(() {
          _markState = _MarkState.idle;
          _lockedShowData =
              null; // sblocca la card, permettendo l'aggiornamento visivo
        });
      }
    } catch (e) {
      AppToast.show('Operazione non riuscita. Riprova.');
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
        .read(trackedShowsProvider.notifier)
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

    // ── Prossimo episodio ──────────────────────────────────────────────────
    // seasonCounts viene dal DB locale: nessuna chiamata API per
    // determinare il numero di stagione/episodio corretto.
    final dbSeasonCounts =
        ref.watch(seasonEpisodeCountsProvider(show.id)).value ?? {};

    final detailAsync = ref.watch(showDetailProvider(show.tmdbId));
    final detail = detailAsync.value;

    // Per un anime senza dati AniList `detail.seasons` è la suddivisione TMDB
    // grezza, che raggruppa più cours: numeri di stagione e totali incompatibili
    // con quelli con cui sono salvati gli episodi visti. In quel caso restiamo
    // sui conteggi del DB, che sono cour-based.
    final animeDataMissing =
        (detail?.isAnime ?? show.isAnime) && detail?.animeSeasonsData == null;
    final seasonCounts =
        (detail != null && detail.seasons.isNotEmpty && !animeDataMissing)
            ? {for (final s in detail.seasons) s.seasonNumber: s.episodeCount}
            : dbSeasonCounts;

    var (nextSeason, nextEp) = computeNextToWatch(
      watchedBySeason,
      seasonCounts,
      animeSeasonsData: detail?.animeSeasonsData,
    );

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

    var loadedSeason = seasonAsync.value;
    // Senza mappatura cour gli episodi TMDB grezzi hanno coordinate ambigue.
    var loadedEpisodes = animeDataMissing ? null : loadedSeason?.episodes;
    var nextEpisode =
        loadedEpisodes?.where((e) => e.episodeNumber == nextEp).firstOrNull;

    // ── Discrepanza AniList/TMDB ───────────────────────────────────────────
    // AniList può riportare un episodeCount maggiore di quanti episodi TMDB
    // distribuisce effettivamente (per OVA, recap, ecc.).
    // Es: AniList S3 = 13 ep, TMDB distribuisce solo 12 → l'utente ha visto
    // tutti gli ep reali (12) ma il codice cerca l'ep 13 che non esiste.
    // In questo caso: ricalcola con il conteggio reale e avanza la stagione.
    if (seasonAsync.hasValue &&
        loadedSeason?.isLocalSnapshot == false &&
        nextEpisode == null &&
        loadedEpisodes != null &&
        loadedEpisodes.isNotEmpty &&
        nextEp > loadedEpisodes.length) {
      // Correggi il conteggio per questa stagione con il valore reale da TMDB
      final correctedCounts = Map<int, int>.from(seasonCounts);
      correctedCounts[nextSeason] = loadedEpisodes.length;
      final (corrSeason, corrEp) = computeNextToWatch(
        watchedBySeason,
        correctedCounts,
        animeSeasonsData: detail?.animeSeasonsData,
      );
      // Usa la stagione ricalcolata solo se è diversa da quella corrente
      // (altrimenti non avremmo risolto nulla)
      if (corrSeason != nextSeason || corrEp != nextEp) {
        nextSeason = corrSeason;
        nextEp = corrEp;
        // Ricarichiamo gli episodi della nuova stagione dal provider
        final corrSeasonAsync = ref.watch(seasonDetailProvider(
          showId: show.tmdbId,
          seasonNumber: nextSeason,
        ));
        if (!corrSeasonAsync.hasValue && !corrSeasonAsync.hasError) {
          return const NextEpisodeSkeletonCard();
        }
        loadedSeason = corrSeasonAsync.value;
        loadedEpisodes = loadedSeason?.episodes;
        nextEpisode =
            loadedEpisodes?.where((e) => e.episodeNumber == nextEp).firstOrNull;
      }
    }

    // ── L'episodio è già uscito? ───────────────────────────────────────────
    // TMDB fornisce i metadati estetici dell'episodio (titolo, immagine), ma
    // non è la fonte della verità su cosa sia già andato in onda: pubblica i
    // nuovi episodi degli anime con un ritardo che può arrivare a un giorno, e
    // la richiesta può fallire del tutto (404 su un cour che TMDB non conosce,
    // rete assente). Consultiamo quindi tutte le fonti disponibili e mostriamo
    // la card se una di esse conferma l'uscita: senza titolo e immagine, ma
    // pronta per essere segnata come vista.
    final hasAired = resolveHasAired(
      show: show,
      dbSeasonCounts: dbSeasonCounts,
      season: nextSeason,
      episode: nextEp,
      animeSeasonsData: detail?.animeSeasonsData,
      airedPerTmdb: nextEpisode?.hasAired,
    );

    // ── Logica di completamento ────────────────────────────────────────────
    // Per gli anime con dati AniList, non usiamo watchedCount >= total perché
    // total può essere calcolato con episodeCount=0 per stagioni in corso,
    // rendendo il confronto inaffidabile (e potendo triggerare "completato"
    // prematuro). Usiamo la logica stagione/episodio come fonte di verità.
    final isAnimeWithData =
        detail != null && detail.isAnime && detail.animeSeasonsData != null;
    final lastWatchedSeason = watchedBySeason.keys.isEmpty
        ? 0
        : watchedBySeason.keys.reduce((a, b) => a > b ? a : b);
    // Una stagione locale può contenere soltanto parte degli episodi, o
    // nessuno: non è una conferma autorevole che la serie sia finita.
    final isCompleted = loadedSeason?.isLocalSnapshot != true &&
        !animeDataMissing &&
        (isAnimeWithData
            ? (nextEpisode == null &&
                (loadedEpisodes == null || loadedEpisodes.isEmpty) &&
                !hasLaterUpcomingAnimeSeason(
                    detail.animeSeasonsData!, lastWatchedSeason))
            : (total != null && watchedCount >= total));

    // Serie finita e vista tutta: la card riepiloga e offre "Completata".
    // Se però è uscito un nuovo episodio il completamento va ignorato.
    if (isCompleted && !hasAired) {
      final isTerminata =
          show.tmdbStatus == 'Ended' || show.tmdbStatus == 'Canceled';
      if (!isTerminata) {
        _requestVisibilityResync();
        return const SizedBox.shrink();
      }
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

    // L'autorità della lista può mantenere un riepilogo per una serie terminata.
    // Se mancano episodi locali non deduciamo un nuovo completamento, ma non
    // nascondiamo neanche la voce già contata: nessuna azione sui progressi.
    if (loadedSeason?.isLocalSnapshot == true &&
        !hasAired &&
        total != null &&
        total > 0 &&
        watchedCount >= total &&
        (show.tmdbStatus == 'Ended' || show.tmdbStatus == 'Canceled')) {
      return _CardShell(
        show: show,
        loading: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              show.title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Dati episodio non disponibili offline.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    // Episodio non ancora uscito: niente card, apparirà in "In Uscita".
    if (!hasAired) {
      _requestVisibilityResync();
      return const SizedBox.shrink();
    }

    final airedEpisodes = countAiredEpisodesForBacklog(
      show: show,
      seasonCounts: seasonCounts,
      detail: detail,
    );
    final backlog =
        airedEpisodes == null ? 0 : airedEpisodes - watchedCount - 1;
    final detailSeasonTotal = seasonCounts[nextSeason];
    final seasonTotal = detailSeasonTotal != null && detailSeasonTotal > 0
        ? detailSeasonTotal
        : dbSeasonCounts[nextSeason];
    final seasonWatched = seasonTotal == null
        ? 0
        : watchedBySeason[nextSeason]
                ?.where((episode) => episode > 0 && episode <= seasonTotal)
                .length ??
            0;

    final seasonName = detail?.isAnime == true
        ? detail!.seasons
            .where((season) => season.seasonNumber == nextSeason)
            .firstOrNull
            ?.name
        : null;
    final episodeTitle = nextEpisode?.name;
    final imageUrl = nextEpisode?.stillPath != null
        ? 'https://image.tmdb.org/t/p/w185${nextEpisode!.stillPath}'
        : show.posterPath != null
            ? 'https://image.tmdb.org/t/p/w185${show.posterPath}'
            : null;

    const thumbnailWidth = 72.0;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
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
              seasonName: seasonName?.split(' · ').first.trim(),
            );
          } else {
            context.push('/series/detail/${show.tmdbId}');
          }
        },
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 68),
            child: Stack(
              fit: StackFit.passthrough,
              children: [
                // Il testo determina l'altezza della card e della miniatura.
                PositionedDirectional(
                  start: 0,
                  top: 0,
                  bottom: 0,
                  width: thumbnailWidth,
                  child: Align(
                    alignment: AlignmentDirectional.topStart,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 112),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox.expand(
                          child: imageUrl != null
                              ? MediaImage(
                                  source: nextEpisode?.stillPath != null
                                      ? MediaImageSource.tmdbStill
                                      : MediaImageSource.tmdbPoster,
                                  imageUrl: imageUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => const ColoredBox(
                                      color: AppColors.divider),
                                  errorWidget: (_, __, ___) =>
                                      const _ImageFallback(),
                                )
                              : const _ImageFallback(),
                        ),
                      ),
                    ),
                  ),
                ),
                Row(
                  children: [
                    const SizedBox(width: thumbnailWidth + 10),
                    // ── Informazioni episodio ────────────────────────────────
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            show.title,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              EpisodeCodeBadge(
                                season: nextSeason,
                                episode: nextEp,
                                seasonName: seasonName,
                              ),
                              if (backlog > 0)
                                Semantics(
                                  label: backlog == 1
                                      ? 'Un episodio arretrato oltre a questo'
                                      : '$backlog episodi arretrati oltre a questo',
                                  excludeSemantics: true,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: AppColors.accent.withAlpha(35),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      child: Text(
                                        '+$backlog ep',
                                        style: const TextStyle(
                                          color: AppColors.accent,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          if (animeDataMissing) ...[
                            const SizedBox(height: 5),
                            const Text(
                              'Dati anime incompleti: aggiorna online per segnare episodi.',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
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
                          if (seasonTotal != null && seasonTotal >= nextEp) ...[
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: seasonWatched / seasonTotal,
                              minHeight: 3,
                              color: AppColors.accent,
                              backgroundColor:
                                  AppColors.textSecondary.withAlpha(55),
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(2)),
                              trackGap: 0,
                              stopIndicatorRadius: 0,
                              semanticsLabel: seasonWatched == 1
                                  ? 'Un episodio visto su $seasonTotal'
                                  : '$seasonWatched episodi visti su $seasonTotal',
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),

                    // ── Pulsante circolare ───────────────────────────────────
                    _CircularMarkButton(
                      state: _markState,
                      onTap: animeDataMissing
                          ? null
                          : () => _markWatched(nextSeason, nextEp),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Pulsante circolare ────────────────────────────────────────────────────────

class _CircularMarkButton extends StatelessWidget {
  final _MarkState state;
  final VoidCallback? onTap;

  const _CircularMarkButton({required this.state, required this.onTap});

  static const _green = Color(0xFF4CAF50);

  Color get _bgColor => switch (state) {
        _MarkState.idle => Colors.transparent,
        _MarkState.marking => _green,
        _MarkState.success => _green,
      };

  Color get _iconColor => onTap == null
      ? AppColors.textSecondary
      : state == _MarkState.idle
          ? AppColors.accent
          : Colors.white;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: state == _MarkState.idle ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: SizedBox.square(
        dimension: 48,
        child: Center(
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
                            ? MediaImage(
                                source: MediaImageSource.tmdbPoster,
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
