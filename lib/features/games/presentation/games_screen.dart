import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/auth/rawg_auth_state.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/games_providers.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

List<String> _decodePlatforms(String? json) {
  if (json == null) return [];
  try {
    return (jsonDecode(json) as List<dynamic>).cast<String>();
  } catch (_) {
    return [];
  }
}

bool _isUpcoming(TrackedGame game) {
  if (game.releaseDate == null) return true; // TBA → in uscita
  return game.releaseDate!.isAfter(DateTime.now());
}

// ── Screen ────────────────────────────────────────────────────────────────────

class GamesScreen extends ConsumerWidget {
  const GamesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rawgStateAsync = ref.watch(rawgAuthControllerProvider);
    final isUnauthenticated = rawgStateAsync.valueOrNull is RawgUnauthenticated;

    if (isUnauthenticated) {
      return const _RawgEmptyShell();
    }

    final gamesAsync = ref.watch(trackedGamesNotifierProvider);
    final totalCount = gamesAsync.valueOrNull?.length ?? 0;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
                child: _GamesHeader(totalCount: totalCount),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: _GamesTabBar(),
              ),
              const Expanded(
                child: TabBarView(
                  children: [
                    _BacklogTab(),
                    _InUscitaTab(),
                    _GiocatiTab(),
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

// ── RAWG Empty Shell ──────────────────────────────────────────────────────────

class _RawgEmptyShell extends ConsumerStatefulWidget {
  const _RawgEmptyShell();

  @override
  ConsumerState<_RawgEmptyShell> createState() => _RawgEmptyShellState();
}

class _RawgEmptyShellState extends ConsumerState<_RawgEmptyShell> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.videogame_asset_outlined,
                size: 80,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 24),
              const Text(
                'Modulo Videogiochi',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Inserisci una RAWG API Key per sbloccare la ricerca e il tracciamento dei videogiochi.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: 'La tua RAWG API Key',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => launchUrl(Uri.parse('https://rawg.io/apidocs'), mode: LaunchMode.externalApplication),
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('Richiedi chiave gratis'),
                ),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () {
                  final key = _controller.text.trim();
                  if (key.isNotEmpty) {
                    ref.read(rawgAuthControllerProvider.notifier).loginWithKey(key);
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Salva e Attiva', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _GamesHeader extends StatelessWidget {
  final int totalCount;
  const _GamesHeader({required this.totalCount});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => context.push('/games/list'),
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border.all(color: AppColors.divider, width: 1.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.videogame_asset_rounded,
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
                'I Miei Giochi',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                totalCount == 0
                    ? 'Nessun gioco aggiunto'
                    : '$totalCount ${totalCount == 1 ? 'gioco nel backlog' : 'giochi nel backlog'}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon:
              const Icon(Icons.search, color: AppColors.accent, size: 30),
          onPressed: () => context.go('/search?filter=game'),
          tooltip: 'Cerca giochi',
        ),
      ],
    );
  }
}

// ── TabBar ────────────────────────────────────────────────────────────────────

class _GamesTabBar extends StatelessWidget {
  const _GamesTabBar();

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
          Tab(text: 'Backlog'),
          Tab(text: 'In Uscita'),
          Tab(text: 'Giocati'),
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

// ── Tab Backlog ───────────────────────────────────────────────────────────────

class _BacklogTab extends ConsumerStatefulWidget {
  const _BacklogTab();

  @override
  ConsumerState<_BacklogTab> createState() => _BacklogTabState();
}

class _BacklogTabState extends ConsumerState<_BacklogTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final gamesAsync = ref.watch(trackedGamesNotifierProvider);

    return gamesAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      ),
      error: (e, _) => _ErrorView(message: e.toString()),
      data: (games) {
        final now = DateTime.now();
        final backlog = games
            .where((g) =>
                g.status == MediaStatus.planToWatch &&
                g.releaseDate != null &&
                !g.releaseDate!.isAfter(now))
            .toList();

        if (backlog.isEmpty) return const _EmptyBacklog();

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
                    'Da Giocare (${backlog.length})',
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
                (context, index) => _GameCard(
                  key: ValueKey(backlog[index].id),
                  game: backlog[index],
                ),
                childCount: backlog.length,
              ),
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
          ],
        );
      },
    );
  }
}

// ── Tab In Uscita ─────────────────────────────────────────────────────────────

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
    final gamesAsync = ref.watch(trackedGamesNotifierProvider);

    return gamesAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      ),
      error: (e, _) => _ErrorView(message: e.toString()),
      data: (games) {
        // In Uscita: planToWatch con data futura o TBA
        final upcoming = games
            .where(
                (g) => g.status == MediaStatus.planToWatch && _isUpcoming(g))
            .toList()
          ..sort((a, b) {
            if (a.releaseDate == null && b.releaseDate == null) return 0;
            if (a.releaseDate == null) return 1; // TBA in fondo
            if (b.releaseDate == null) return -1;
            return a.releaseDate!.compareTo(b.releaseDate!);
          });

        if (upcoming.isEmpty) return const _EmptyInUscita();

        final now = DateTime.now();
        final threshold = now.add(const Duration(days: 30));

        final prossimamente = <TrackedGame>[];
        final inArrivo = <TrackedGame>[];

        for (final game in upcoming) {
          if (game.releaseDate == null || game.releaseDate!.isAfter(threshold) || game.releaseDate!.isAtSameMomentAs(threshold)) {
            inArrivo.add(game);
          } else {
            prossimamente.add(game);
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
                  (context, index) => _UpcomingGameCard(
                    key: ValueKey(prossimamente[index].id),
                    game: prossimamente[index],
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
                  (context, index) => _UpcomingGameCard(
                    key: ValueKey(inArrivo[index].id),
                    game: inArrivo[index],
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

// ── Tab Giocati ───────────────────────────────────────────────────────────────

class _GiocatiTab extends ConsumerStatefulWidget {
  const _GiocatiTab();

  @override
  ConsumerState<_GiocatiTab> createState() => _GiocatiTabState();
}

class _GiocatiTabState extends ConsumerState<_GiocatiTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final gamesAsync = ref.watch(trackedGamesNotifierProvider);

    return gamesAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      ),
      error: (e, _) => _ErrorView(message: e.toString()),
      data: (games) {
        final played =
            games.where((g) => g.status == MediaStatus.completed).toList();
        final dropped =
            games.where((g) => g.status == MediaStatus.dropped).toList();

        if (played.isEmpty && dropped.isEmpty) {
          return const _EmptyGiocati();
        }

        // Costruiamo una lista mista con section headers
        final items = <_ListItem>[];
        if (played.isNotEmpty) {
          items.add(_SectionItem('Completati (${played.length})'));
          items.addAll(played.map(_GameItem.new));
        }
        if (dropped.isNotEmpty) {
          items.add(_SectionItem(
            'Abbandonati (${dropped.length})',
            topMargin: played.isNotEmpty,
          ));
          items.addAll(dropped.map(_GameItem.new));
        }

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 12, bottom: 24),
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final item = items[i];
                  if (item is _SectionItem) {
                    final isCompletati = item.title.startsWith('Completati');
                    final color = isCompletati ? Colors.green : Colors.red;
                    return Padding(
                      padding: EdgeInsets.fromLTRB(
                          20, item.topMargin ? 16 : 12, 20, 8),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(left: BorderSide(color: color, width: 4)),
                        ),
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          item.title,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }
                  return _GameCard(
                    key: ValueKey((item as _GameItem).game.id),
                    game: item.game,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Lista items (sealed union) ────────────────────────────────────────────────

abstract class _ListItem {}

class _SectionItem extends _ListItem {
  final String title;
  final bool topMargin;
  _SectionItem(this.title, {this.topMargin = false});
}

class _GameItem extends _ListItem {
  final TrackedGame game;
  _GameItem(this.game);
}

// ── GameCard (Backlog e Giocati) ──────────────────────────────────────────────

class _GameCard extends ConsumerStatefulWidget {
  final TrackedGame game;
  const _GameCard({super.key, required this.game});

  @override
  ConsumerState<_GameCard> createState() => _GameCardState();
}

class _GameCardState extends ConsumerState<_GameCard> {
  bool _loading = false;

  Future<void> _onActionTap() async {
    final game = widget.game;
    if (game.status == MediaStatus.completed ||
        game.status == MediaStatus.dropped) {
      // Reset al backlog
      setState(() => _loading = true);
      try {
        await ref
            .read(trackedGamesNotifierProvider.notifier)
            .resetToBacklog(game.id);
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    } else {
      // Apri modal voto
      if (!mounted) return;
      await _showRatingSheet(context, game);
    }
  }

  Future<void> _showRatingSheet(BuildContext context, TrackedGame game) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RatingSheet(
        gameName: game.title,
        onConfirm: (rating) async {
          Navigator.of(context).pop();
          setState(() => _loading = true);
          try {
            await ref
                .read(trackedGamesNotifierProvider.notifier)
                .markPlayed(game.id, rating);
          } finally {
            if (mounted) setState(() => _loading = false);
          }
        },
        onFold: () async {
          Navigator.of(context).pop();
          setState(() => _loading = true);
          try {
            await ref
                .read(trackedGamesNotifierProvider.notifier)
                .markFolded(game.id);
          } finally {
            if (mounted) setState(() => _loading = false);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final platforms = _decodePlatforms(game.platforms);
    final platformLabel =
        platforms.take(2).join(' · ');
    final releaseYear = game.releaseDate?.year;
    final isPlayed = game.status == MediaStatus.completed;
    final isDropped = game.status == MediaStatus.dropped;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: () => context.push('/games/detail/${game.rawgId}'),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Cover
              _Cover(url: game.coverUrl),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (releaseYear != null || platformLabel.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        [
                          if (releaseYear != null) '$releaseYear',
                          if (platformLabel.isNotEmpty) platformLabel,
                        ].join(' · '),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    // Rating row
                    _RatingRow(game: game),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Action button
              _ActionButton(
                isLoading: _loading,
                isPlayed: isPlayed,
                isDropped: isDropped,
                onTap: _onActionTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Upcoming Game Card ────────────────────────────────────────────────────────

class _UpcomingGameCard extends StatelessWidget {
  final TrackedGame game;
  final bool isFarFuture;
  const _UpcomingGameCard({super.key, required this.game, this.isFarFuture = false});

  @override
  Widget build(BuildContext context) {
    final platforms = _decodePlatforms(game.platforms);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: () => context.push('/games/detail/${game.rawgId}'),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _Cover(url: game.coverUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    if (game.releaseDate != null)
                      _ReleaseDateBadge(date: game.releaseDate!, isFarFuture: isFarFuture)
                    else
                      const _TbaBadge(),
                    if (platforms.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        platforms.take(2).join(' · '),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
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
    if (diff <= 0) return 'Oggi!';
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

class _TbaBadge extends StatelessWidget {
  const _TbaBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.divider.withAlpha(80),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'Data da annunciare',
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ── Rating row ────────────────────────────────────────────────────────────────

class _RatingRow extends StatelessWidget {
  final TrackedGame game;
  const _RatingRow({required this.game});

  @override
  Widget build(BuildContext context) {
    final isPlayed = game.status == MediaStatus.completed;
    final isDropped = game.status == MediaStatus.dropped;

    if (isPlayed && game.userRating != null) {
      return Row(
        children: [
          const Icon(Icons.star, color: AppColors.accent, size: 13),
          const SizedBox(width: 3),
          Text(
            '${game.userRating!.toStringAsFixed(1)}/10',
            style: const TextStyle(
              color: AppColors.accent,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (game.voteAverage != null) ...[
            const SizedBox(width: 10),
            const Icon(Icons.star_border, color: AppColors.textSecondary,
                size: 13),
            const SizedBox(width: 3),
            Text(
              '${game.voteAverage!.toStringAsFixed(1)}/10',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ],
      );
    }

    if (isDropped) {
      return Row(
        children: [
          const Icon(Icons.flag, color: Color(0xFFF44336), size: 13),
          const SizedBox(width: 3),
          const Text(
            'Abbandonato',
            style: TextStyle(
              color: Color(0xFFF44336),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (game.voteAverage != null) ...[
            const SizedBox(width: 10),
            const Icon(Icons.star_border, color: AppColors.textSecondary,
                size: 13),
            const SizedBox(width: 3),
            Text(
              '${game.voteAverage!.toStringAsFixed(1)}/10',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ],
      );
    }

    // Backlog
    return Row(
      children: [
        if (game.voteAverage != null && game.voteAverage! > 0) ...[
          const Icon(Icons.star_border, color: AppColors.textSecondary,
              size: 13),
          const SizedBox(width: 3),
          Text(
            '${game.voteAverage!.toStringAsFixed(1)}/10',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
        if (game.playtime != null && game.playtime! > 0) ...[
          if (game.voteAverage != null && game.voteAverage! > 0)
            const SizedBox(width: 10),
          const Icon(Icons.timer_outlined, color: AppColors.textSecondary,
              size: 13),
          const SizedBox(width: 3),
          Text(
            '~${game.playtime}h',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}

// ── Action button ─────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final bool isLoading;
  final bool isPlayed;
  final bool isDropped;
  final VoidCallback onTap;
  const _ActionButton({
    required this.isLoading,
    required this.isPlayed,
    required this.isDropped,
    required this.onTap,
  });

  Color get _bgColor {
    if (isLoading) return Colors.transparent;
    if (isPlayed) return AppColors.accent;
    if (isDropped) return const Color(0xFFF44336);
    return Colors.transparent;
  }

  Widget get _icon {
    if (isLoading) {
      return const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
            strokeWidth: 2, color: AppColors.textSecondary),
      );
    }
    if (isPlayed) {
      return const Icon(Icons.check, color: Colors.white, size: 18);
    }
    if (isDropped) {
      return const Icon(Icons.flag, color: Colors.white, size: 18);
    }
    return const Icon(Icons.check, color: AppColors.accent, size: 18);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _bgColor,
          border: (!isPlayed && !isDropped && !isLoading)
              ? Border.all(color: AppColors.accent.withAlpha(120),
                  width: 1.5)
              : null,
        ),
        child: Center(child: _icon),
      ),
    );
  }
}

// ── Cover ─────────────────────────────────────────────────────────────────────

class _Cover extends StatelessWidget {
  final String? url;
  const _Cover({this.url});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 96,
        height: 80,
        child: url != null
            ? CachedNetworkImage(
                imageUrl: url!,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    const ColoredBox(color: AppColors.divider),
                errorWidget: (_, __, ___) => const _CoverFallback(),
              )
            : const _CoverFallback(),
      ),
    );
  }
}

class _CoverFallback extends StatelessWidget {
  const _CoverFallback();

  @override
  Widget build(BuildContext context) => const ColoredBox(
        color: AppColors.divider,
        child: Center(
          child: Icon(Icons.videogame_asset,
              color: AppColors.textSecondary, size: 24),
        ),
      );
}

// ── Rating Bottom Sheet ───────────────────────────────────────────────────────

class _RatingSheet extends StatefulWidget {
  final String gameName;
  final void Function(double rating) onConfirm;
  final VoidCallback onFold;

  const _RatingSheet({
    required this.gameName,
    required this.onConfirm,
    required this.onFold,
  });

  @override
  State<_RatingSheet> createState() => _RatingSheetState();
}

class _RatingSheetState extends State<_RatingSheet> {
  int? _base;
  bool _half = false;

  double? get _effectiveRating {
    if (_base == null) return null;
    if (_half && _base! < 10) return _base! + 0.5;
    return _base!.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad =
        MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E2D),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottomPad + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Titolo
          const Text(
            'Quanto ti è piaciuto?',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.gameName,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Griglia 1–10
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: List.generate(10, (i) {
              final n = i + 1;
              final selected = _base == n;
              return GestureDetector(
                onTap: () => setState(() {
                  _base = n;
                  _half = false;
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.accent : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected ? AppColors.accent : AppColors.divider,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$n',
                      style: TextStyle(
                        color: selected ? Colors.black : AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),

          // Toggle mezzo punto
          if (_base != null) ...[
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _HalfToggle(
                  label: '$_base',
                  active: !_half,
                  onTap: () => setState(() => _half = false),
                ),
                if (_base! < 10) ...[
                  const SizedBox(width: 12),
                  _HalfToggle(
                    label: '${_base! + 0.5}',
                    active: _half,
                    onTap: () => setState(() => _half = true),
                  ),
                ],
              ],
            ),
          ] else
            const SizedBox(height: 14),

          const SizedBox(height: 16),

          // Fold button
          GestureDetector(
            onTap: widget.onFold,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF44336).withAlpha(100)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.flag_outlined, color: Color(0xFFF44336), size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Fold — ho abbandonato questo gioco',
                    style: TextStyle(
                      color: Color(0xFFF44336),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Annulla / Conferma
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.divider),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Annulla'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _effectiveRating != null
                      ? () => widget.onConfirm(_effectiveRating!)
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    disabledBackgroundColor: AppColors.accent.withAlpha(80),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Conferma',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HalfToggle extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _HalfToggle(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.accent : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: active ? AppColors.accent : AppColors.divider),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.black : AppColors.textSecondary,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

// ── Empty states ──────────────────────────────────────────────────────────────

class _EmptyBacklog extends StatelessWidget {
  const _EmptyBacklog();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videogame_asset_outlined,
                size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            const Text(
              'Backlog vuoto',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Cerca un gioco e aggiungilo\nal tuo backlog.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.go('/search?filter=game'),
              icon: const Icon(Icons.search),
              label: const Text('Cerca Giochi'),
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
            Icon(Icons.event_outlined,
                size: 64, color: AppColors.textSecondary),
            SizedBox(height: 16),
            Text(
              'Nessun gioco in uscita',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'I giochi non ancora usciti che\naggiungi al backlog appariranno qui.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyGiocati extends StatelessWidget {
  const _EmptyGiocati();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline,
                size: 64, color: AppColors.textSecondary),
            SizedBox(height: 16),
            Text(
              'Nessun gioco completato',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Segna un gioco come completato\no abbandonato per vederlo qui.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Errore:\n$message',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
      );
}
