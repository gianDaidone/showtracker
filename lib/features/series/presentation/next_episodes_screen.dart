import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../providers/series_providers.dart';
import 'widgets/next_episode_card.dart';
import 'widgets/upcoming_episode_card.dart';

/// Schermata principale del tab Serie.
/// Due tab: "Da Vedere" (prossimo episodio per serie in visione)
/// e "In Uscita" (episodi futuri delle serie tracciate).
class NextEpisodesScreen extends ConsumerWidget {
  const NextEpisodesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allShowsAsync = ref.watch(trackedShowsNotifierProvider);
    final totalCount = allShowsAsync.valueOrNull?.length ?? 0;

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
                child: _SeriesHeader(totalCount: totalCount),
              ),

              // ── TabBar ────────────────────────────────────────────────
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: _SeriesTabBar(),
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

// ── TabBar ────────────────────────────────────────────────────────────────────

class _SeriesTabBar extends StatelessWidget {
  const _SeriesTabBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        tabs: const [
          Tab(text: 'Da Vedere'),
          Tab(text: 'In Uscita'),
        ],
        labelColor: Colors.black,
        unselectedLabelColor: AppColors.textSecondary,
        indicator: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
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
    final watchingAsync = ref.watch(watchingShowsWithEpisodesProvider);
    final allShowsAsync = ref.watch(trackedShowsNotifierProvider);
    final totalCount = allShowsAsync.valueOrNull?.length ?? 0;

    return watchingAsync.when(
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
      data: (shows) => shows.isEmpty
          ? _EmptyWatching(totalCount: totalCount)
          : ListView.builder(
              padding: const EdgeInsets.only(top: 12, bottom: 24),
              itemCount: shows.length,
              itemBuilder: (_, i) => NextEpisodeCard(showData: shows[i]),
            ),
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
      data: (items) => items.isEmpty
          ? const _EmptyUpcoming()
          : ListView.builder(
              padding: const EdgeInsets.only(top: 12, bottom: 24),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final info = items[i];
                return UpcomingEpisodeCard(
                  show: info.show,
                  episode: info.episode,
                  airDate: info.airDate,
                  preciseAirTime: info.preciseAirTime,
                );
              },
            ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _SeriesHeader extends StatelessWidget {
  final int totalCount;
  const _SeriesHeader({required this.totalCount});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => context.push('/series/list'),
          child: Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.tv_rounded,
              color: Colors.black,
              size: 28,
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
                'Le Mie Serie',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                totalCount == 0
                    ? 'Nessuna serie aggiunta'
                    : '$totalCount '
                        '${totalCount == 1 ? 'serie seguita' : 'serie seguite'}',
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
