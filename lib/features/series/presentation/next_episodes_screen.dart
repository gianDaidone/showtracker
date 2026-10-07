import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/library_header_link.dart';
import '../providers/series_providers.dart';
import 'widgets/next_episode_card.dart';
import 'widgets/upcoming_episode_card.dart';

/// Schermata principale del tab Serie.
/// Due tab: "Da Vedere" (prossimo episodio per serie in visione)
/// e "In Uscita" (episodi futuri delle serie tracciate).
class NextEpisodesScreen extends ConsumerStatefulWidget {
  final int initialTab;
  const NextEpisodesScreen({super.key, this.initialTab = 0});

  @override
  ConsumerState<NextEpisodesScreen> createState() => _NextEpisodesScreenState();
}

class _NextEpisodesScreenState extends ConsumerState<NextEpisodesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTab);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    // Invalidate "In Uscita" whenever the user switches to it so the episode
    // names are always fresh (they may have been cached by opening a detail page).
    if (_tabController.index == 1 && !_tabController.indexIsChanging) {
      ref.invalidate(upcomingEpisodesProvider);
    }
  }

  @override
  void didUpdateWidget(NextEpisodesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTab != oldWidget.initialTab && widget.initialTab != _tabController.index) {
      _tabController.animateTo(widget.initialTab);
    }
  }

  @override
  Widget build(BuildContext context) {
    final allShowsAsync = ref.watch(trackedShowsNotifierProvider);
    final totalCount = allShowsAsync.valueOrNull?.length ?? 0;
    final isLoading = allShowsAsync.isLoading && !allShowsAsync.hasValue;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
              child: _SeriesHeader(totalCount: totalCount, isLoading: isLoading),
            ),

            // ── TabBar ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: _SeriesTabBar(controller: _tabController),
            ),

            // ── TabBarView ────────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  _DaVedereTab(),
                  _InUscitaTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── TabBar ────────────────────────────────────────────────────────────────────

class _SeriesTabBar extends StatelessWidget {
  final TabController controller;
  const _SeriesTabBar({required this.controller});

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
        controller: controller,
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
    final visibleAsync = ref.watch(visibleWatchingShowsProvider);
    final allShowsAsync = ref.watch(trackedShowsNotifierProvider);
    final totalCount = allShowsAsync.valueOrNull?.length ?? 0;

    return visibleAsync.when(
      skipLoadingOnReload: true,
      loading: () => const _SkeletonListView(
        title: 'Da Vedere',
        borderColor: Colors.orange,
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
      data: (shows) {
        // We still need to know if they have ANY shows tracked to show the right empty state
        final watchingRaw = ref.read(watchingShowsWithEpisodesProvider).valueOrNull ?? [];
        if (watchingRaw.isEmpty && shows.isEmpty) {
          return _EmptyWatching(totalCount: totalCount);
        }

        if (shows.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.done_all,
                    size: 64,
                    color: Color(0xFF4CAF50),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Sei in pari!',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Hai visto tutti gli episodi disponibili delle tue serie. '
                    'Controlla la scheda "In Uscita" per i prossimi episodi.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          );
        }

        final now = DateTime.now();
        final threshold = now.subtract(const Duration(days: 30));

        final daVedere = <ShowWithWatchedEpisodes>[];
        final nonVisti = <ShowWithWatchedEpisodes>[];

        for (final showData in shows) {
          final lastWatchedAt = showData.show.lastWatchedAt;
          if (lastWatchedAt != null && lastWatchedAt.isBefore(threshold)) {
            nonVisti.add(showData);
          } else {
            daVedere.add(showData);
          }
        }

        return CustomScrollView(
          slivers: [
            const SliverPadding(padding: EdgeInsets.only(top: 12)),
            if (daVedere.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  child: Container(
                    decoration: const BoxDecoration(
                      border: Border(left: BorderSide(color: Colors.orange, width: 4)),
                    ),
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      'Da Vedere (${daVedere.length})',
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
                  (context, index) => NextEpisodeCard(
                    key: ValueKey(daVedere[index].show.id),
                    showData: daVedere[index],
                  ),
                  childCount: daVedere.length,
                ),
              ),
            ],
            if (nonVisti.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Container(
                    decoration: const BoxDecoration(
                      border: Border(left: BorderSide(color: Colors.grey, width: 4)),
                    ),
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      'Non visti da tempo (${nonVisti.length})',
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
                  (context, index) => NextEpisodeCard(
                    key: ValueKey(nonVisti[index].show.id),
                    showData: nonVisti[index],
                  ),
                  childCount: nonVisti.length,
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
    final upcomingAsync = ref.watch(upcomingEpisodesProvider);

    return upcomingAsync.when(
      skipLoadingOnReload: true,
      loading: () => const _SkeletonListView(
        title: 'Prossimamente',
        borderColor: Colors.orange,
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
      data: (items) {
        if (items.isEmpty) {
          return const _EmptyUpcoming();
        }

        final now = DateTime.now();
        final threshold = now.add(const Duration(days: 30));

        final prossimamente = <UpcomingEpisodeInfo>[];
        final inArrivo = <UpcomingEpisodeInfo>[];

        for (final info in items) {
          if (info.airDate.isAfter(threshold) || info.airDate.isAtSameMomentAs(threshold)) {
            inArrivo.add(info);
          } else {
            prossimamente.add(info);
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
                  (context, index) {
                    final info = prossimamente[index];
                    return UpcomingEpisodeCard(
                      key: ValueKey('${info.show.id}_${info.episode.seasonNumber}_${info.episode.episodeNumber}'),
                      show: info.show,
                      episode: info.episode,
                      airDate: info.airDate,
                      preciseAirTime: info.preciseAirTime,
                      isFarFuture: false,
                      seasonName: info.seasonName,
                      additionalEpisodes: info.additionalEpisodes,
                    );
                  },
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
                  (context, index) {
                    final info = inArrivo[index];
                    return UpcomingEpisodeCard(
                      key: ValueKey('${info.show.id}_${info.episode.seasonNumber}_${info.episode.episodeNumber}'),
                      show: info.show,
                      episode: info.episode,
                      airDate: info.airDate,
                      preciseAirTime: info.preciseAirTime,
                      isFarFuture: true,
                      seasonName: info.seasonName,
                      additionalEpisodes: info.additionalEpisodes,
                    );
                  },
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

// ── Header ────────────────────────────────────────────────────────────────────

class _SeriesHeader extends StatelessWidget {
  final int totalCount;
  final bool isLoading;
  const _SeriesHeader({required this.totalCount, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: LibraryHeaderLink(
            icon: Icons.tv_rounded,
            title: 'Le Mie Serie',
            tooltip: 'Vai alle mie serie',
            onTap: () => context.push('/series/list'),
            subtitle: isLoading
                ? Container(
                    width: 100,
                    height: 14,
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  )
                : Text(
                    totalCount == 0
                        ? 'Nessuna serie aggiunta'
                        : '$totalCount '
                            '${totalCount == 1 ? 'serie seguita' : 'serie seguite'}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.search, color: AppColors.accent, size: 30),
          onPressed: () => context.go('/search?filter=series'),
          tooltip: 'Cerca serie',
        ),
      ],
    );
  }
}

// ── Stato vuoto "Da Vedere" ───────────────────────────────────────────────────

class _EmptyWatching extends StatelessWidget {
  final int totalCount;
  const _EmptyWatching({required this.totalCount});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.play_circle_outline,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            const Text(
              'Nessuna serie in visione',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              totalCount == 0
                  ? 'Cerca una serie con 🔍 e inizia a tracciarla.'
                  : 'Apri una serie e imposta lo status su "In visione".',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            if (totalCount == 0)
              FilledButton.icon(
                onPressed: () => context.go('/search?filter=series'),
                icon: const Icon(Icons.search),
                label: const Text('Cerca una serie'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.black,
                ),
              )
            else
              OutlinedButton.icon(
                onPressed: () => context.push('/series/list'),
                icon: const Icon(Icons.tv_rounded, color: AppColors.accent),
                label: const Text(
                  'Vai alle mie serie',
                  style: TextStyle(color: AppColors.accent),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.accent),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Stato vuoto "In Uscita" ───────────────────────────────────────────────────

class _EmptyUpcoming extends StatelessWidget {
  const _EmptyUpcoming();

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
              'Nessun episodio in uscita',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Quando le serie che segui hanno nuovi episodi in arrivo, li troverai qui.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Skeleton Loader con Header ────────────────────────────────────────────────

class _SkeletonListView extends StatelessWidget {
  final String title;
  final Color borderColor;

  const _SkeletonListView({
    required this.title,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const SliverPadding(padding: EdgeInsets.only(top: 12)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: Container(
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: borderColor, width: 4)),
              ),
              padding: const EdgeInsets.only(left: 8),
              child: Row(
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 36,
                    height: 18,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => const NextEpisodeSkeletonCard(),
            childCount: 4,
          ),
        ),
      ],
    );
  }
}
