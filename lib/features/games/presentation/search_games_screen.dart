import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/app_toast.dart';
import '../../../core/theme/app_theme.dart';
import '../data/models/rawg_game.dart';
import '../providers/games_providers.dart';

// ── Screen ────────────────────────────────────────────────────────────────────

class SearchGamesScreen extends StatefulWidget {
  const SearchGamesScreen({super.key});

  @override
  State<SearchGamesScreen> createState() => _SearchGamesScreenState();
}

class _SearchGamesScreenState extends State<SearchGamesScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() {});
    _debounce?.cancel();
    final trimmed = value.trim();
    if (trimmed.length < 2) {
      setState(() => _query = '');
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _query = trimmed);
    });
  }

  void _onClear() {
    _controller.clear();
    _debounce?.cancel();
    setState(() => _query = '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Cerca Giochi',
          style: TextStyle(
              color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: Column(
        children: [
          // Barra di ricerca
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: _SearchBar(
              controller: _controller,
              onChanged: _onChanged,
              onSubmitted: (v) {
                _debounce?.cancel();
                setState(() => _query = v.trim());
              },
              onClear: _onClear,
            ),
          ),
          Expanded(
            child: _query.isEmpty
                ? const _EmptyHint()
                : _Results(query: _query),
          ),
        ],
      ),
    );
  }
}

// ── Search bar ────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider, width: 1.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: true,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              style:
                  const TextStyle(color: AppColors.textPrimary, fontSize: 15),
              decoration: const InputDecoration(
                hintText: 'Cerca un gioco...',
                hintStyle:
                    TextStyle(color: AppColors.textSecondary, fontSize: 15),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          if (controller.text.isNotEmpty) ...[
            GestureDetector(
              onTap: onClear,
              child: const Icon(Icons.cancel,
                  color: AppColors.textSecondary, size: 20),
            ),
            const SizedBox(width: 8),
          ],
          const Icon(Icons.search, color: AppColors.accent, size: 24),
        ],
      ),
    );
  }
}

// ── Results ───────────────────────────────────────────────────────────────────

class _Results extends ConsumerWidget {
  final String query;
  const _Results({required this.query});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(searchGamesProvider(query));
    final trackedAsync = ref.watch(trackedGamesNotifierProvider);
    final trackedIds = trackedAsync.valueOrNull
            ?.map((g) => g.rawgId)
            .toSet() ??
        {};

    return resultsAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: AppColors.accent)),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  color: Colors.redAccent, size: 48),
              const SizedBox(height: 12),
              Text(
                e.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.redAccent, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
      data: (games) {
        if (games.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.search_off,
                      size: 56, color: AppColors.textSecondary),
                  const SizedBox(height: 12),
                  const Text(
                    'Nessun risultato',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Nessun gioco trovato per "$query"',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.only(bottom: 24),
          itemCount: games.length,
          separatorBuilder: (_, __) =>
              const Divider(height: 1, color: AppColors.divider),
          itemBuilder: (_, i) => _GameTile(
            game: games[i],
            isTracked: trackedIds.contains(games[i].id),
          ),
        );
      },
    );
  }
}

// ── Game Tile ─────────────────────────────────────────────────────────────────

class _GameTile extends ConsumerStatefulWidget {
  final RawgGame game;
  final bool isTracked;
  const _GameTile({required this.game, required this.isTracked});

  @override
  ConsumerState<_GameTile> createState() => _GameTileState();
}

class _GameTileState extends ConsumerState<_GameTile> {
  bool _adding = false;

  Future<void> _addToBacklog() async {
    if (_adding || widget.isTracked) return;
    setState(() => _adding = true);
    try {
      // Fetch dettaglio completo prima di salvare
      final detail = await ref
          .read(rawgServiceProvider)
          .getGameDetails(widget.game.id);
      await ref.read(trackedGamesNotifierProvider.notifier).addGame(detail);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.game.name} aggiunto al backlog'),
            backgroundColor: AppColors.accent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      AppToast.show('Impossibile aggiungere il gioco');
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final isTracked = widget.isTracked;
    final platformLabel = game.platforms.take(2).join(' · ');

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      onTap: () => context.push('/games/detail/${game.id}'),
      leading: _Thumbnail(url: game.coverUrl),
      title: Text(
        game.name,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 3),
          Row(
            children: [
              if (game.year != null) ...[
                Text(
                  '${game.year}',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
                if (platformLabel.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  const Text('·',
                      style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(width: 6),
                ],
              ],
              if (platformLabel.isNotEmpty)
                Expanded(
                  child: Text(
                    platformLabel,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
          if (game.voteAverage > 0) ...[
            const SizedBox(height: 3),
            Row(
              children: [
                const Icon(Icons.star, color: AppColors.accent, size: 12),
                const SizedBox(width: 3),
                Text(
                  '${game.voteAverage.toStringAsFixed(1)}/10',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
                if (game.playtime != null && game.playtime! > 0) ...[
                  const SizedBox(width: 10),
                  const Icon(Icons.timer_outlined,
                      color: AppColors.textSecondary, size: 12),
                  const SizedBox(width: 3),
                  Text(
                    '~${game.playtime}h',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
      trailing: _AddButton(
        isTracked: isTracked,
        isAdding: _adding,
        onTap: _addToBacklog,
      ),
    );
  }
}

// ── Add button ────────────────────────────────────────────────────────────────

class _AddButton extends StatelessWidget {
  final bool isTracked;
  final bool isAdding;
  final VoidCallback onTap;

  const _AddButton({
    required this.isTracked,
    required this.isAdding,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isAdding) {
      return const SizedBox(
        width: 36,
        height: 36,
        child: CircularProgressIndicator(
            strokeWidth: 2.5, color: AppColors.accent),
      );
    }
    if (isTracked) {
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.accent.withAlpha(30),
          border: Border.all(color: AppColors.accent),
        ),
        child: const Icon(Icons.check, color: AppColors.accent, size: 18),
      );
    }
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surface,
          border: Border.all(color: AppColors.divider),
        ),
        child: const Icon(Icons.add, color: AppColors.textSecondary, size: 20),
      ),
    );
  }
}

// ── Thumbnail ─────────────────────────────────────────────────────────────────

class _Thumbnail extends StatelessWidget {
  final String? url;
  const _Thumbnail({this.url});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        width: 64,
        height: 44,
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
                        color: AppColors.textSecondary, size: 20),
                  ),
                ),
              )
            : const ColoredBox(
                color: AppColors.divider,
                child: Center(
                  child: Icon(Icons.videogame_asset,
                      color: AppColors.textSecondary, size: 20),
                ),
              ),
      ),
    );
  }
}

// ── Empty hint ────────────────────────────────────────────────────────────────

class _EmptyHint extends StatelessWidget {
  const _EmptyHint();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.videogame_asset_outlined,
                size: 56, color: AppColors.textSecondary),
            SizedBox(height: 16),
            Text(
              'Cerca un gioco',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Digita il nome di un gioco\nper cercarlo su RAWG',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
