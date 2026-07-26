import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/games_providers.dart';

List<String> _decodePlatforms(String? json) {
  if (json == null) return [];
  try {
    return (jsonDecode(json) as List<dynamic>).cast<String>();
  } catch (_) {
    return [];
  }
}

class GamesListScreen extends ConsumerStatefulWidget {
  const GamesListScreen({super.key});

  @override
  ConsumerState<GamesListScreen> createState() => _GamesListScreenState();
}

class _GamesListScreenState extends ConsumerState<GamesListScreen> {
  bool _isSearching = false;
  final _controller = TextEditingController();
  String _query = '';
  MediaStatus? _selectedStatus;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startSearch() => setState(() => _isSearching = true);

  void _stopSearch() => setState(() {
        _isSearching = false;
        _query = '';
        _controller.clear();
      });

  @override
  Widget build(BuildContext context) {
    final gamesAsync = ref.watch(trackedGamesNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: _isSearching
            ? TextField(
                controller: _controller,
                autofocus: true,
                style: const TextStyle(color: AppColors.textPrimary),
                cursorColor: AppColors.accent,
                decoration: const InputDecoration(
                  hintText: 'Filtra i tuoi giochi…',
                  hintStyle: TextStyle(color: AppColors.textSecondary),
                  border: InputBorder.none,
                ),
                onChanged: (v) => setState(() => _query = v.trim()),
              )
            : const Text(
                'I miei giochi',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
        actions: [
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.close, color: AppColors.textPrimary),
              tooltip: 'Annulla',
              onPressed: _stopSearch,
            )
          else
            IconButton(
              icon: const Icon(Icons.search, color: AppColors.textPrimary),
              tooltip: 'Filtra giochi',
              onPressed: _startSearch,
            ),
        ],
      ),
      body: gamesAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.accent)),
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
        data: (games) {
          if (games.isEmpty) return const _EmptyState();

          var filtered = games;
          if (_selectedStatus != null) {
            filtered = filtered.where((g) => g.status == _selectedStatus).toList();
          }
          if (_query.isNotEmpty) {
            filtered = filtered
                .where((g) =>
                    g.title.toLowerCase().contains(_query.toLowerCase()))
                .toList();
          }

          final list = filtered.isEmpty
              ? _NoResults(query: _query)
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 24),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => _GameCard(
                    key: ValueKey(filtered[i].id),
                    game: filtered[i],
                  ),
                );

          return Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'Tutti',
                      isSelected: _selectedStatus == null,
                      onTap: () => setState(() => _selectedStatus = null),
                    ),
                    ...[
                      MediaStatus.planToWatch,
                      MediaStatus.completed,
                      MediaStatus.dropped,
                    ].map((status) => Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: _FilterChip(
                            label: status.gameLabel,
                            isSelected: _selectedStatus == status,
                            onTap: () => setState(() => _selectedStatus = status),
                          ),
                        )),
                  ],
                ),
              ),
              Expanded(child: list),
            ],
          );
        },
      ),
    );
  }
}

// ── Nessun risultato ──────────────────────────────────────────────────────────

class _NoResults extends StatelessWidget {
  final String query;
  const _NoResults({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, size: 56, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              query.isNotEmpty ? 'Nessun gioco trovato\nper "$query"' : 'Nessun gioco in questo stato',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Card ──────────────────────────────────────────────────────────────────────

class _GameCard extends StatelessWidget {
  final TrackedGame game;
  const _GameCard({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final platforms = _decodePlatforms(game.platforms);
    final platformLabel = platforms.take(2).join(' · ');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => context.push('/games/detail/${game.rawgId}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _Cover(url: game.coverUrl),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
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
                    const SizedBox(height: 8),
                    _StatusChip(game: game),
                    if (platformLabel.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        platformLabel,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Status chip con valutazione integrata ─────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final TrackedGame game;
  const _StatusChip({required this.game});

  static const _statusColors = {
    MediaStatus.completed: Color(0xFF4CAF50),
    MediaStatus.dropped: Color(0xFFF44336),
    MediaStatus.planToWatch: Color(0xFF2196F3),
  };

  @override
  Widget build(BuildContext context) {
    final isPlayed = game.status == MediaStatus.completed;
    final isDropped = game.status == MediaStatus.dropped;
    final isUpcoming = game.releaseDate != null &&
        game.releaseDate!.isAfter(DateTime.now());

    final Color color;
    final String label;
    final IconData icon;

    if (isPlayed) {
      color = _statusColors[MediaStatus.completed]!;
      label = game.userRating != null
          ? 'Giocato · ★ ${game.userRating!.toStringAsFixed(1)}'
          : 'Giocato';
      icon = Icons.check_circle_outline;
    } else if (isDropped) {
      color = _statusColors[MediaStatus.dropped]!;
      label = 'Abbandonato';
      icon = Icons.flag_outlined;
    } else if (isUpcoming) {
      color = AppColors.accent;
      label = 'In Uscita';
      icon = Icons.event_outlined;
    } else {
      color = _statusColors[MediaStatus.planToWatch]!;
      label = 'Backlog';
      icon = Icons.bookmark_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(120),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
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
        width: 60,
        height: 90,
        child: url != null
            ? CachedNetworkImage(
                imageUrl: url!,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    const ColoredBox(color: AppColors.divider),
                errorWidget: (_, __, ___) => const ColoredBox(
                  color: AppColors.divider,
                  child: Center(
                    child: Icon(Icons.videogame_asset,
                        color: AppColors.textSecondary, size: 24),
                  ),
                ),
              )
            : const ColoredBox(
                color: AppColors.divider,
                child: Center(
                  child: Icon(Icons.videogame_asset,
                      color: AppColors.textSecondary, size: 24),
                ),
              ),
      ),
    );
  }
}

// ── Stato vuoto ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

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
              'Nessun gioco aggiunto',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Usa il tab Cerca per trovare\nun gioco e aggiungerlo.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.go('/search?filter=game'),
              icon: const Icon(Icons.search),
              label: const Text('Cerca un gioco'),
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.divider,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
