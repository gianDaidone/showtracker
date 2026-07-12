import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/services/app_toast.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/movies_providers.dart';

// ── Stati del pulsante "segna come visto" ─────────────────────────────────────

enum _MarkState { idle, marking, success }

class MoviesScreen extends ConsumerWidget {
  const MoviesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moviesAsync = ref.watch(trackedMoviesNotifierProvider);
    final totalCount = moviesAsync.valueOrNull?.length ?? 0;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              // ── Header ────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
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
        GestureDetector(
          onTap: () => context.push('/movies/list'),
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border.all(color: AppColors.divider, width: 1.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.movie_rounded,
              color: AppColors.accent,
              size: 24,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'I Miei Film',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                totalCount == 0
                    ? 'Nessun film aggiunto'
                    : '$totalCount '
                        '${totalCount == 1 ? 'film nel catalogo' : 'film nel catalogo'}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.search, color: AppColors.accent, size: 30),
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
    final moviesAsync = ref.watch(trackedMoviesNotifierProvider);

    return moviesAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      ),
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
        final now = DateTime.now();
        final toWatch = movies
            .where((m) =>
                m.status == MediaStatus.planToWatch &&
                (m.releaseDate == null || !m.releaseDate!.isAfter(now)))
            .toList();
        if (toWatch.isEmpty) return const _EmptyDaVedere();
        return CustomScrollView(
          slivers: [
            const SliverPadding(padding: EdgeInsets.only(top: 12)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: Container(
                  decoration: const BoxDecoration(
                    border: Border(left: BorderSide(color: Colors.orange, width: 4)),
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
        if (movies.isEmpty) return const _EmptyInUscita();

        final now = DateTime.now();
        final threshold = now.add(const Duration(days: 30));

        final prossimamente = <TrackedMovy>[];
        final inArrivo = <TrackedMovy>[];

        for (final movie in movies) {
          if (movie.releaseDate != null && (movie.releaseDate!.isAfter(threshold) || movie.releaseDate!.isAtSameMomentAs(threshold))) {
            inArrivo.add(movie);
          } else {
            prossimamente.add(movie);
          }
        }

        return CustomScrollView(
          slivers: [
            const SliverPadding(padding: EdgeInsets.only(top: 12)),
            if (prossimamente.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  child: Container(
                    decoration: const BoxDecoration(
                      border: Border(left: BorderSide(color: Colors.orange, width: 4)),
                    ),
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      'Prossimamente (${prossimamente.length})',
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
                  (context, index) => _UpcomingMovieCard(
                    key: ValueKey(prossimamente[index].id),
                    movie: prossimamente[index],
                    isFarFuture: false,
                  ),
                  childCount: prossimamente.length,
                ),
              ),
            ],
            if (inArrivo.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Container(
                    decoration: const BoxDecoration(
                      border: Border(left: BorderSide(color: Colors.grey, width: 4)),
                    ),
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      'In Arrivo (${inArrivo.length})',
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
                  (context, index) => _UpcomingMovieCard(
                    key: ValueKey(inArrivo[index].id),
                    movie: inArrivo[index],
                    isFarFuture: true,
                  ),
                  childCount: inArrivo.length,
                ),
              ),
            ],
            const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
          ],
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

  Future<void> _markWatched() async {
    if (_markState != _MarkState.idle) return;
    setState(() => _markState = _MarkState.marking);
    try {
      await ref
          .read(trackedMoviesNotifierProvider.notifier)
          .updateStatus(widget.movie.id, MediaStatus.completed);
      if (!mounted) return;
      setState(() => _markState = _MarkState.success);
      await Future.delayed(const Duration(milliseconds: 700));
      if (mounted) setState(() => _markState = _MarkState.idle);
    } catch (_) {
      if (mounted) setState(() => _markState = _MarkState.idle);
      AppToast.show('Impossibile aggiornare lo stato del film');
    }
  }

  @override
  Widget build(BuildContext context) {
    final movie = widget.movie;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: () => context.push('/movies/detail/${movie.tmdbId}'),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _Poster(path: movie.posterPath),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                    if (movie.releaseYear != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        '${movie.releaseYear}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _CircularMarkButton(
                state: _markState,
                onTap: _markWatched,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Upcoming Movie Card ───────────────────────────────────────────────────────

class _UpcomingMovieCard extends StatelessWidget {
  final TrackedMovy movie;
  final bool isFarFuture;
  const _UpcomingMovieCard({super.key, required this.movie, this.isFarFuture = false});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: () => context.push('/movies/detail/${movie.tmdbId}'),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _Poster(path: movie.posterPath),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                    if (movie.releaseDate != null)
                      _ReleaseDateBadge(date: movie.releaseDate!, isFarFuture: isFarFuture),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Release date badge ────────────────────────────────────────────────────────

class _ReleaseDateBadge extends StatelessWidget {
  final DateTime date;
  final bool isFarFuture;
  const _ReleaseDateBadge({required this.date, this.isFarFuture = false});

  static const _months = [
    'gen', 'feb', 'mar', 'apr', 'mag', 'giu',
    'lug', 'ago', 'set', 'ott', 'nov', 'dic',
  ];

  String get _formatted =>
      '${date.day} ${_months[date.month - 1]} ${date.year}';

  String get _countdown {
    final diff = date.difference(DateTime.now()).inDays;
    if (diff == 0) return 'Oggi!';
    if (diff == 1) return 'Domani';
    if (diff < 30) return 'tra $diff giorni';
    if (diff < 365) {
      final months = (diff / 30).round();
      return 'tra $months ${months == 1 ? 'mese' : 'mesi'}';
    }
    return _formatted;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.divider.withAlpha(80),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$_formatted · $_countdown',
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

// ── Pulsante circolare ────────────────────────────────────────────────────────

class _CircularMarkButton extends StatelessWidget {
  final _MarkState state;
  final VoidCallback onTap;

  const _CircularMarkButton({required this.state, required this.onTap});

  static const _green = Color(0xFF4CAF50);

  Color get _bgColor => switch (state) {
        _MarkState.idle => Colors.transparent,
        _MarkState.marking => _green,
        _MarkState.success => AppColors.accent,
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
            child: state == _MarkState.marking
                ? const CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  )
                : Icon(
                    state == _MarkState.success
                        ? Icons.check
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

// ── Widget di supporto ────────────────────────────────────────────────────────

class _Poster extends StatelessWidget {
  final String? path;
  const _Poster({this.path});

  @override
  Widget build(BuildContext context) {
    final url =
        path != null ? 'https://image.tmdb.org/t/p/w185$path' : null;
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
                errorWidget: (_, __, ___) => const _PosterFallback(),
              )
            : const _PosterFallback(),
      ),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.divider.withAlpha(80),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.label,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ── Stato vuoto "Da Vedere" ───────────────────────────────────────────────────

class _EmptyDaVedere extends StatelessWidget {
  const _EmptyDaVedere();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
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
      child: Padding(
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
