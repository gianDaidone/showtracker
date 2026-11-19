import '../../sync/presentation/sync_status_action.dart';
import '../../../core/widgets/media_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/services/app_toast.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/library_header_link.dart';
import '../../../core/widgets/library_media_card.dart';
import '../../../core/widgets/release_timeline.dart';
import '../providers/movies_providers.dart';

// ── Stati del pulsante "segna come visto" ─────────────────────────────────────

enum _MarkState { idle, marking, success }

class MoviesScreen extends ConsumerWidget {
  const MoviesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moviesAsync = ref.watch(trackedMoviesProvider);
    final totalCount = moviesAsync.value?.length ?? 0;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              // ── Header ────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _MoviesHeader(totalCount: totalCount),
              ),

              // ── TabBar ────────────────────────────────────────────────
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: _MoviesTabBar(),
              ),

              // ── TabBarView ────────────────────────────────────────────
              const Expanded(
                child: TabBarView(
                  children: [
                    _DaVedereTab(),
                    _InUscitaTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _MoviesHeader extends StatelessWidget {
  final int totalCount;
  const _MoviesHeader({required this.totalCount});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: LibraryHeaderLink(
            icon: Icons.movie_rounded,
            title: 'I Miei Film',
            tooltip: 'Vai ai miei film',
            onTap: () => context.push('/movies/list'),
            subtitle: Text(
              totalCount == 0
                  ? 'Nessun film aggiunto'
                  : '$totalCount film nel catalogo',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
              ),
            ),
          ),
        ),
        const SyncStatusAction(),
        LibrarySearchButton(
          onPressed: () => context.go('/search?filter=movie'),
          tooltip: 'Cerca film',
        ),
      ],
    );
  }
}

// ── TabBar ────────────────────────────────────────────────────────────────────

class _MoviesTabBar extends StatelessWidget {
  const _MoviesTabBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: TabBar(
        tabs: const [
          Tab(text: 'Da Vedere'),
          Tab(text: 'In Uscita'),
        ],
        labelColor: AppColors.textPrimary,
        unselectedLabelColor: AppColors.textSecondary.withAlpha(120),
        indicator: BoxDecoration(
          color: Colors.white.withAlpha(24),
          borderRadius: BorderRadius.circular(22),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        splashFactory: NoSplash.splashFactory,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          letterSpacing: 0.3,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
          letterSpacing: 0.3,
        ),
        padding: const EdgeInsets.all(4),
      ),
    );
  }
}

// ── Tab "Da Vedere" ───────────────────────────────────────────────────────────

class _DaVedereTab extends ConsumerStatefulWidget {
  const _DaVedereTab();

  @override
  ConsumerState<_DaVedereTab> createState() => _DaVedereTabState();
}

class _DaVedereTabState extends ConsumerState<_DaVedereTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final moviesAsync = ref.watch(trackedMoviesProvider);

    return moviesAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      ),
      error: (e, _) => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Caricamento non riuscito. Controlla la connessione e riprova.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.redAccent),
          ),
        ),
      ),
      data: (movies) {
        final now = DateTime.now();
        final toWatch = movies
            .where((m) =>
                m.status == MediaStatus.planToWatch &&
                (m.releaseDate == null || !m.releaseDate!.isAfter(now)))
            .toList();
        if (toWatch.isEmpty) return const _EmptyDaVedere();
        final indices = {
          for (final (index, item) in toWatch.indexed) ValueKey(item.id): index,
        };
        return CustomScrollView(
          slivers: [
            const SliverPadding(padding: EdgeInsets.only(top: 12)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: Container(
                  decoration: const BoxDecoration(
                    border: Border(
                        left: BorderSide(color: Colors.orange, width: 4)),
                  ),
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    'Da Vedere (${toWatch.length})',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _WatchlistMovieCard(
                  key: ValueKey(toWatch[index].id),
                  movie: toWatch[index],
                ),
                childCount: toWatch.length,
                findChildIndexCallback: (key) => indices[key],
              ),
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
          ],
        );
      },
    );
  }
}

// ── Tab "In Uscita" ───────────────────────────────────────────────────────────

class _InUscitaTab extends ConsumerStatefulWidget {
  const _InUscitaTab();

  @override
  ConsumerState<_InUscitaTab> createState() => _InUscitaTabState();
}

class _InUscitaTabState extends ConsumerState<_InUscitaTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final upcomingAsync = ref.watch(upcomingMoviesProvider);

    return upcomingAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      ),
      error: (e, _) => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Caricamento non riuscito. Controlla la connessione e riprova.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.redAccent),
          ),
        ),
      ),
      data: (movies) {
        if (movies.isEmpty) return const _EmptyInUscita();

        return ReleaseTimeline(
          items: movies,
          now: DateTime.now(),
          dateFor: (movie) => movie.releaseDate,
          keyFor: (movie) => ValueKey(movie.id),
          cardBuilder: (context, movie) {
            return LibraryMediaCard(
              title: movie.title,
              thumbnail: _Poster(path: movie.posterPath),
              thumbnailSize: const Size(42, 63),
              margin: EdgeInsets.zero,
              onTap: () => context.push('/movies/detail/${movie.tmdbId}'),
            );
          },
        );
      },
    );
  }
}

// ── Watchlist Movie Card (con bottone "segna come visto") ─────────────────────

class _WatchlistMovieCard extends ConsumerStatefulWidget {
  final TrackedMovy movie;
  const _WatchlistMovieCard({super.key, required this.movie});

  @override
  ConsumerState<_WatchlistMovieCard> createState() =>
      _WatchlistMovieCardState();
}

class _WatchlistMovieCardState extends ConsumerState<_WatchlistMovieCard> {
  _MarkState _markState = _MarkState.idle;

  /// Stessa sequenza del pulsante episodio delle serie: prima l'animazione,
  /// poi la scrittura. Il film diventa "Completato" ed esce dalla lista appena
  /// il DB emette, quindi scrivere subito farebbe sparire la card prima della
  /// spunta verde.
  Future<void> _markWatched() async {
    if (_markState != _MarkState.idle) return;
    final notifier = ref.read(trackedMoviesProvider.notifier);
    final movieId = widget.movie.id;
    setState(() => _markState = _MarkState.marking);

    await Future.delayed(const Duration(milliseconds: 200));
    if (mounted) setState(() => _markState = _MarkState.success);

    await Future.delayed(const Duration(milliseconds: 700));

    try {
      await notifier.updateStatus(movieId, MediaStatus.completed);
      if (mounted) setState(() => _markState = _MarkState.idle);
    } catch (_) {
      if (mounted) setState(() => _markState = _MarkState.idle);
      AppToast.show('Impossibile aggiornare lo stato del film');
    }
  }

  @override
  Widget build(BuildContext context) {
    final movie = widget.movie;
    return LibraryMediaCard(
      title: movie.title,
      thumbnail: _Poster(path: movie.posterPath),
      thumbnailSize: const Size(52, 78),
      onTap: () => context.push('/movies/detail/${movie.tmdbId}'),
      details: movie.releaseYear == null
          ? null
          : Text(
              '${movie.releaseYear}',
              style:
                  const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
      action: _CircularMarkButton(state: _markState, onTap: _markWatched),
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

// ── Widget di supporto ────────────────────────────────────────────────────────

class _Poster extends StatelessWidget {
  final String? path;
  const _Poster({this.path});

  @override
  Widget build(BuildContext context) {
    final url = path != null ? 'https://image.tmdb.org/t/p/w185$path' : null;
    return url == null
        ? const _PosterFallback()
        : MediaImage(
            source: MediaImageSource.tmdbPoster,
            imageUrl: url,
            fit: BoxFit.cover,
            placeholder: (_, __) => const ColoredBox(color: AppColors.divider),
            errorWidget: (_, __, ___) => const _PosterFallback(),
          );
  }
}

class _PosterFallback extends StatelessWidget {
  const _PosterFallback();
  @override
  Widget build(BuildContext context) => const ColoredBox(
        color: AppColors.divider,
        child: Center(
          child: Icon(Icons.movie, color: AppColors.textSecondary, size: 28),
        ),
      );
}

// ── Stato vuoto "Da Vedere" ───────────────────────────────────────────────────

class _EmptyDaVedere extends StatelessWidget {
  const _EmptyDaVedere();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.movie_filter_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            const Text(
              'Lista desideri vuota',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Cerca un film e aggiungilo\nalla tua lista da vedere.',
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

// ── Stato vuoto "In Uscita" ───────────────────────────────────────────────────

class _EmptyInUscita extends StatelessWidget {
  const _EmptyInUscita();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: 16),
            Text(
              'Nessun film in uscita',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Quando aggiungi film non ancora usciti,\nli troverai qui con la data di uscita.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
