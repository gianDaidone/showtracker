import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/app_toast.dart';
import '../../../core/theme/app_theme.dart';
import '../data/models/tmdb_show.dart';
import '../providers/series_providers.dart';

class SearchShowsScreen extends ConsumerStatefulWidget {
  const SearchShowsScreen({super.key});

  @override
  ConsumerState<SearchShowsScreen> createState() => _SearchShowsScreenState();
}

class _SearchShowsScreenState extends ConsumerState<SearchShowsScreen> {
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
    setState(() {}); // aggiorna il pulsante clear
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
      body: SafeArea(
        child: Column(
          children: [
            // ── Logo ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Center(
                child: SvgPicture.asset(
                  'assets/images/tmdb_logo.svg',
                  height: 26,
                ),
              ),
            ),

            // ── Search bar ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: _SearchBar(
                controller: _controller,
                onChanged: _onChanged,
                onSubmitted: (v) {
                  _debounce?.cancel();
                  setState(() => _query = v.trim());
                },
                onClear: _onClear,
                hint: 'Cerca una serie TV...',
              ),
            ),

            // ── Body ─────────────────────────────────────────────────────
            Expanded(
              child: _query.isEmpty
                  ? const _EmptyHint()
                  : _Results(query: _query),
            ),
          ],
        ),
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
  final String hint;

  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
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
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 15),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 15),
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
          const Icon(Icons.search, color: AppColors.accent, size: 26),
        ],
      ),
    );
  }
}

// ── Hint vuoto ────────────────────────────────────────────────────────────────

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
            Text(
              'Inizia la tua ricerca',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Digita almeno 2 caratteri per vedere i risultati',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
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
    final resultsAsync = ref.watch(searchShowsProvider(query));
    final tracked = ref.watch(trackedShowsNotifierProvider).valueOrNull ?? [];
    final trackedIds = tracked.map((s) => s.tmdbId).toSet();

    return resultsAsync.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accent)),
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
        if (shows.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Nessun risultato',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Nessuna serie trovata per "$query"',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 14),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text(
                '${shows.length} '
                '${shows.length == 1 ? 'risultato trovato' : 'risultati trovati'}',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.only(bottom: 24),
                itemCount: shows.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: AppColors.divider),
                itemBuilder: (_, i) => _ResultTile(
                  show: shows[i],
                  isTracked: trackedIds.contains(shows[i].id),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── ResultTile ────────────────────────────────────────────────────────────────

class _ResultTile extends ConsumerWidget {
  final TmdbShow show;
  final bool isTracked;
  const _ResultTile({required this.show, required this.isTracked});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      onTap: () => context.push('/series/detail/${show.id}'),
      leading: _SearchPoster(url: show.posterUrl),
      title: Text(
        show.name,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (show.year != null)
            Text(
              '${show.year}',
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12),
            ),
          if (show.overview?.isNotEmpty == true)
            Text(
              show.overview!,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
      trailing: isTracked
          ? const Icon(Icons.check_circle, color: AppColors.accent)
          : IconButton(
              icon: const Icon(Icons.add_circle_outline,
                  color: AppColors.accent),
              tooltip: 'Aggiungi',
              onPressed: () => _quickAdd(context, ref),
            ),
    );
  }

  Future<void> _quickAdd(BuildContext context, WidgetRef ref) async {
    try {
      final detail = await ref.read(showDetailProvider(show.id).future);
      await ref.read(trackedShowsNotifierProvider.notifier).addShow(detail);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${show.name}" aggiunta!'),
            backgroundColor: AppColors.surface,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      AppToast.show('Impossibile aggiungere la serie');
    }
  }
}

class _SearchPoster extends StatelessWidget {
  final String? url;
  const _SearchPoster({this.url});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        width: 46,
        height: 68,
        child: url != null
            ? CachedNetworkImage(
                imageUrl: url!,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    const ColoredBox(color: AppColors.divider),
                errorWidget: (_, __, ___) => const ColoredBox(
                  color: AppColors.divider,
                  child: Icon(Icons.tv,
                      color: AppColors.textSecondary, size: 20),
                ),
              )
            : const ColoredBox(
                color: AppColors.divider,
                child: Icon(Icons.tv,
                    color: AppColors.textSecondary, size: 20),
              ),
      ),
    );
  }
}
