import '../../../core/widgets/media_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/riverpod_utils.dart';
import '../../../core/services/app_toast.dart';
import '../../../core/widgets/animated_refresh_button.dart';
import '../../../core/theme/app_theme.dart';
import '../data/local_show_snapshot.dart';
import '../data/models/tmdb_show_detail.dart';
import '../data/tmdb_service.dart';
import '../providers/series_providers.dart';
import 'widgets/season_section.dart';

/// Torna alla schermata precedente, o alla lista serie se il dettaglio è
/// stato aperto direttamente (deep link, widget) e non c'è niente sotto.
void _leaveDetail(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go('/series');
  }
}

class ShowDetailScreen extends ConsumerWidget {
  final int tmdbId;
  const ShowDetailScreen({super.key, required this.tmdbId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(showDetailProvider(tmdbId));

    // Mantieni i dati precedenti durante un refresh (es. quando l'utente
    // tocca l'icona "Aggiorna dati anime"): la pagina resta visibile e
    // l'icona stessa mostra lo spinner finché non arrivano i dati nuovi.
    final detail = detailAsync.value;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: detail != null
          ? _DetailBody(detail: detail)
          : detailAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.accent),
              ),
              error: (e, _) => _ErrorBody(tmdbId: tmdbId, error: e),
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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || widget.detail.isLocalSnapshot) return;
      final trackedList = ref.read(trackedShowsProvider).value ?? [];
      final trackedShow =
          trackedList.where((s) => s.tmdbId == widget.detail.id).firstOrNull;
      if (trackedShow != null) {
        // Reschedule anime notification once when the detail page opens so that
        // stale cached nextAiringEpisode data doesn't block scheduling.
        if (widget.detail.isAnime && widget.detail.animeSeasonsData != null) {
          ref
              .read(trackedShowsProvider.notifier)
              .rescheduleNotification(widget.detail);
        }
        await ref
            .read(trackedShowsProvider.notifier)
            .syncMetadata(widget.detail, trackedShow.id);
      }
    });
  }

  @override
  void didUpdateWidget(_DetailBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.detail.isLocalSnapshot) return;
    final wasMissing = oldWidget.detail.animeSeasonsData == null;
    final isPresent = widget.detail.animeSeasonsData != null;
    final shouldReschedule = widget.detail.isAnime && wasMissing && isPresent;

    if (shouldReschedule || oldWidget.detail != widget.detail) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted || widget.detail.isLocalSnapshot) return;
        final trackedList = ref.read(trackedShowsProvider).value ?? [];
        final trackedShow =
            trackedList.where((s) => s.tmdbId == widget.detail.id).firstOrNull;
        if (trackedShow != null) {
          if (shouldReschedule) {
            // Quando i dati anime arrivano per la prima volta dopo un refresh
            // (animeSeasonsData passa da null a popolato), riprogramma la notifica
            // con l'orario preciso AniList: initState non si rinnova sui rebuild.
            ref
                .read(trackedShowsProvider.notifier)
                .rescheduleNotification(widget.detail);
          }
          if (oldWidget.detail != widget.detail) {
            await ref
                .read(trackedShowsProvider.notifier)
                .syncMetadata(widget.detail, trackedShow.id);
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = widget.detail;
    final trackedList = ref.watch(trackedShowsProvider).value ?? [];
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
                if (detail.isLocalSnapshot) ...[
                  const _DetailWarningBanner(
                    message: 'Modalità offline: dati salvati sul dispositivo. '
                        'Alcune informazioni potrebbero essere incomplete.',
                  ),
                  const SizedBox(height: 24),
                ],
                if (detail.isAnime && detail.animeSeasonsData == null) ...[
                  _AnimeDataUnavailableBanner(
                    isLocalSnapshot: detail.isLocalSnapshot,
                  ),
                  const SizedBox(height: 24),
                ],
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
          for (final season in detail.seasons)
            SeasonSection(
              // Synthetic anime seasons share a TMDB season: retain each
              // cour's expansion independently, never by list position.
              key: ValueKey((
                detail.id,
                season.seasonNumber,
                detail.animeSeasonsData
                    ?.where((cour) => cour.seasonNumber == season.seasonNumber)
                    .firstOrNull
                    ?.anilistId,
              )),
              detail: detail,
              season: season,
              trackedShow: trackedShow,
            ),
        if (trackedShow != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: _RemoveShowButton(
                  title: detail.name, trackedShow: trackedShow),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }
}

// ── Avviso: dati AniList non disponibili ──────────────────────────────────────

/// Senza la mappatura cour le coordinate TMDB non sono sicure per i progressi.
class _AnimeDataUnavailableBanner extends StatelessWidget {
  final bool isLocalSnapshot;
  const _AnimeDataUnavailableBanner({required this.isLocalSnapshot});

  @override
  Widget build(BuildContext context) {
    return _DetailWarningBanner(
      message: isLocalSnapshot
          ? 'Dati anime incompleti: la suddivisione in parti non è salvata sul '
              'dispositivo. Non è possibile segnare episodi finché i dati '
              'non vengono aggiornati online.'
          : 'Dati AniList non disponibili. Le stagioni qui sotto sono quelle '
              'grezze di TMDB: nomi, suddivisione in parti e conteggi possono '
              'non corrispondere. Non è possibile segnare episodi finché i '
              'dati anime non tornano disponibili.',
    );
  }
}

class _DetailWarningBanner extends StatelessWidget {
  final String message;
  const _DetailWarningBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.accent.withAlpha(20),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.accent.withAlpha(90)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.cloud_off_rounded,
              color: AppColors.accent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
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
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => _leaveDetail(context),
      ),
      actions: [
        _RefreshButton(tmdbId: detail.id, isAnime: detail.isAnime),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: detail.backdropUrl != null
            ? MediaImage(
                source: MediaImageSource.tmdbBackdrop,
                imageUrl: detail.backdropUrl!,
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
    final container = ProviderScope.containerOf(context, listen: false);

    var ok = true;
    try {
      // Un refresh fallito non deve cancellare l'unica copia disponibile offline.
      await container.read(cacheDaoProvider).expireCacheForShow(widget.tmdbId);

      if (widget.isAnime) {
        await container
            .read(animeCacheDaoProvider)
            .expireAnimeCacheForShow(widget.tmdbId);
        container.invalidate(animeDataProvider(widget.tmdbId));
      }
      container.invalidate(rawShowDetailProvider(widget.tmdbId));
      container.invalidate(showDetailProvider(widget.tmdbId));

      // Il listener temporaneo mantiene vivo il provider anche se si esce
      // dalla pagina prima che termini la richiesta (Riverpod 3).
      final detail = await container.readFuture(
        showDetailProvider(widget.tmdbId).future,
      );
      await Future.delayed(const Duration(milliseconds: 1200));

      if (detail.isLocalSnapshot) {
        ok = false;
        AppToast.show(
          'Aggiornamento non riuscito: sono mostrati i dati salvati sul dispositivo. Riprova quando la connessione è disponibile.',
        );
      } else if (detail.isAnime && detail.animeSeasonsData == null) {
        ok = false;
        AppToast.show(
          'AniList non raggiungibile: stagioni e conteggi anime non aggiornati.',
        );
      } else if (detail.isAnime &&
          await container
                  .read(animeCacheDaoProvider)
                  .getFreshAnimeSeasons(widget.tmdbId) ==
              null) {
        // Ci sono dati anime, ma la cache è ancora quella fatta scadere qui
        // sopra: il download (o il salvataggio) è fallito e `animeData` ha
        // ripiegato sulla copia vecchia. Mostrare la spunta verde farebbe
        // credere all'utente di vedere dati aggiornati.
        ok = false;
        AppToast.show(
          'Aggiornamento da AniList non riuscito: stagioni e conteggi sono quelli salvati in precedenza.',
        );
      }
    } catch (error) {
      ok = false;
      AppToast.show(
        isRecoverableSeriesError(error)
            ? 'Connessione non disponibile: aggiornamento non riuscito. Riprova più tardi.'
            : 'Impossibile aggiornare i dati della serie. Riprova più tardi.',
      );
    }

    if (!mounted) return;
    setState(() => _state = ok ? RefreshState.success : RefreshState.error);
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) setState(() => _state = RefreshState.idle);
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
                ? MediaImage(
                    source: MediaImageSource.tmdbPoster,
                    imageUrl: detail.posterUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        const ColoredBox(color: AppColors.divider),
                  )
                : const ColoredBox(
                    color: AppColors.divider,
                    child: Icon(Icons.tv,
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
                        const Icon(Icons.star,
                            color: AppColors.accent, size: 16),
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
                        border:
                            Border.all(color: AppColors.accent.withAlpha(150)),
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
                  children: detail.genres
                      .map((g) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
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
                          ))
                      .toList(),
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
      await ref.read(trackedShowsProvider.notifier).addShow(widget.detail);
    } catch (e) {
      AppToast.show('Impossibile aggiungere "${widget.detail.name}"');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

// ── Remove button (Secondary Action) ──────────────────────────────────────────

class _RemoveShowButton extends ConsumerStatefulWidget {
  final String title;
  final TrackedShow trackedShow;

  /// Chiamato dopo una rimozione riuscita.
  final VoidCallback? onRemoved;

  const _RemoveShowButton({
    required this.title,
    required this.trackedShow,
    this.onRemoved,
  });

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
          'Rimuoverai "${widget.title}" e tutti i progressi episodi salvati.',
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
          .read(trackedShowsProvider.notifier)
          .removeShow(widget.trackedShow.id);
      widget.onRemoved?.call();
    } catch (_) {
      AppToast.show('Impossibile rimuovere "${widget.title}"');
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
                .read(trackedShowsProvider.notifier)
                .updateStatus(trackedShow.id, s),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.divider.withAlpha(120)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: selected
                    ? null
                    : Border.all(color: AppColors.divider.withAlpha(50)),
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

/// Mostrato quando il dettaglio TMDB non si carica. Deve restare sempre
/// possibile uscire e, se la serie è in libreria, rimuoverla: una voce
/// eliminata da TMDB (404) non tornerà più e senza questi comandi resterebbe
/// bloccata nella lista serie.
class _ErrorBody extends ConsumerWidget {
  final int tmdbId;
  final Object error;
  const _ErrorBody({required this.tmdbId, required this.error});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackedList = ref.watch(trackedShowsProvider).value ?? [];
    final TrackedShow? trackedShow =
        trackedList.where((s) => s.tmdbId == tmdbId).firstOrNull;
    final error = this.error;
    final isNotFound = error is TmdbException && error.isNotFound;

    final String message;
    if (isNotFound) {
      message = trackedShow != null
          ? 'Questa serie non esiste più su TMDB: potrebbe essere stata '
              "eliminata o unita a un'altra voce. Puoi rimuoverla dalla "
              "libreria e, se è confluita in un'altra serie, cercare e "
              'seguire quella.'
          : 'Questa serie non esiste più su TMDB: potrebbe essere stata '
              "eliminata o unita a un'altra voce.";
    } else if (isRecoverableSeriesError(error)) {
      message =
          'Impossibile collegarsi al servizio. Controlla la connessione e '
          'riprova: non ci sono dati salvati sufficienti per mostrare questa serie.';
    } else {
      message = error.toString();
    }

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => _leaveDetail(context),
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isNotFound
                          ? Icons.search_off_rounded
                          : Icons.error_outline,
                      size: 48,
                      color: Colors.redAccent,
                    ),
                    if (trackedShow != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        trackedShow.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Anche un 404 può essere transitorio (cache TMDB in
                    // aggiornamento), quindi il tentativo resta sempre possibile.
                    TextButton.icon(
                      onPressed: () {
                        ref.invalidate(rawShowDetailProvider(tmdbId));
                        ref.invalidate(showDetailProvider(tmdbId));
                      },
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Riprova'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.accent,
                      ),
                    ),
                    if (trackedShow != null) ...[
                      const SizedBox(height: 8),
                      _RemoveShowButton(
                        title: trackedShow.title,
                        trackedShow: trackedShow,
                        onRemoved: () {
                          if (context.mounted) _leaveDetail(context);
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
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
    if (s.contains('corso') ||
        s.contains('returning') ||
        s.contains('airing')) {
      statusColor = Colors.greenAccent;
    } else if (s.contains('terminat') ||
        s.contains('ended') ||
        s.contains('completa')) {
      statusColor = Colors.blueAccent;
    } else if (s.contains('cancellat') ||
        s.contains('eliminat') ||
        s.contains('canceled')) {
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
