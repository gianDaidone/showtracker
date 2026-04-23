import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/services/app_toast.dart';
import '../../../core/theme/app_theme.dart';
import '../data/models/rawg_game_detail.dart';
import '../providers/games_providers.dart';

// ── Screen ────────────────────────────────────────────────────────────────────

class GameDetailScreen extends ConsumerWidget {
  final int rawgId;
  const GameDetailScreen({super.key, required this.rawgId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(gameDetailProvider(rawgId));
    final screenshotsAsync = ref.watch(gameScreenshotsProvider(rawgId));
    final trackedGame = ref
        .watch(trackedGamesNotifierProvider)
        .valueOrNull
        ?.where((g) => g.rawgId == rawgId)
        .firstOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: detailAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
        error: (e, _) => _ErrorBody(message: e.toString()),
        data: (detail) {
          // Costruisce l'array di frame: coverUrl come primo + screenshot aggiuntivi,
          // deduplicati (stessa logica della vecchia app)
          final shots = screenshotsAsync.valueOrNull ?? [];
          final seen = <String>{};
          final frames = <String>[
            if (detail.coverUrl != null) detail.coverUrl!,
            ...shots,
          ].where((url) => seen.add(url)).toList();

          return _DetailBody(
            detail: detail,
            frames: frames,
            trackedGame: trackedGame,
          );
        },
      ),
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _DetailBody extends ConsumerWidget {
  final RawgGameDetail detail;
  final List<String> frames;
  final TrackedGame? trackedGame;

  const _DetailBody({
    required this.detail,
    required this.frames,
    required this.trackedGame,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScrollView(
      slivers: [
        // ── Carosello screenshot ─────────────────────────────────────────
        SliverToBoxAdapter(
          child: _ScreenshotCarousel(frames: frames),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titolo
                Text(
                  detail.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                // Info chips (anno, rating, playtime)
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    if (detail.year != null)
                      _InfoChip(
                          icon: Icons.calendar_today,
                          label: '${detail.year}'),
                    if (detail.voteAverage > 0)
                      _InfoChip(
                          icon: Icons.star,
                          label:
                              '${detail.voteAverage.toStringAsFixed(1)}/10'),
                    if (detail.playtime != null && detail.playtime! > 0)
                      _InfoChip(
                          icon: Icons.timer_outlined,
                          label: '~${detail.playtime}h'),
                  ],
                ),

                const SizedBox(height: 16),

                // Pulsante aggiungi / rimuovi
                _TrackButton(detail: detail, trackedGame: trackedGame),

                // Piattaforme
                if (detail.platforms.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _Section(
                    title: 'Piattaforme',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: detail.platforms
                          .map((p) => _Tag(label: p))
                          .toList(),
                    ),
                  ),
                ],

                // Generi
                if (detail.genres.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _Section(
                    title: 'Generi',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: detail.genres
                          .map((g) => _Tag(label: g))
                          .toList(),
                    ),
                  ),
                ],

                // Sviluppatori
                if (detail.developers.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _Section(
                    title: 'Sviluppatori',
                    child: Text(
                      detail.developers.join(', '),
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 14),
                    ),
                  ),
                ],

                // Publisher
                if (detail.publishers.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _Section(
                    title: 'Publisher',
                    child: Text(
                      detail.publishers.join(', '),
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 14),
                    ),
                  ),
                ],

                // Descrizione
                if (detail.overview?.isNotEmpty == true) ...[
                  const SizedBox(height: 20),
                  const Text(
                    'Descrizione',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _ExpandableText(text: detail.overview!),
                ],

                // Tag
                if (detail.tags.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _Section(
                    title: 'Tag',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: detail.tags
                          .take(10)
                          .map((t) => _Tag(label: t))
                          .toList(),
                    ),
                  ),
                ],

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Screenshot carousel ───────────────────────────────────────────────────────

class _ScreenshotCarousel extends StatefulWidget {
  final List<String> frames;
  const _ScreenshotCarousel({required this.frames});

  @override
  State<_ScreenshotCarousel> createState() => _ScreenshotCarouselState();
}

class _ScreenshotCarouselState extends State<_ScreenshotCarousel> {
  final _controller = PageController();
  int _currentIndex = 0;

  static const double _height = 220;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final frames = widget.frames;

    return Stack(
      children: [
        // ── Immagini ─────────────────────────────────────────────────────
        SizedBox(
          height: _height,
          child: frames.isEmpty
              ? const ColoredBox(
                  color: AppColors.divider,
                  child: Center(
                    child: Icon(Icons.videogame_asset,
                        size: 64, color: AppColors.textSecondary),
                  ),
                )
              : PageView.builder(
                  controller: _controller,
                  itemCount: frames.length,
                  onPageChanged: (i) => setState(() => _currentIndex = i),
                  itemBuilder: (_, i) => CachedNetworkImage(
                    imageUrl: frames[i],
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        const ColoredBox(color: AppColors.divider),
                    errorWidget: (_, __, ___) => const ColoredBox(
                      color: AppColors.divider,
                      child: Center(
                        child: Icon(Icons.videogame_asset,
                            size: 48, color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                ),
        ),

        // ── Gradiente in basso (per leggibilità dot) ─────────────────────
        if (frames.length > 1)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 48,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withAlpha(160),
                  ],
                ),
              ),
            ),
          ),

        // ── Dot indicators ────────────────────────────────────────────────
        if (frames.length > 1)
          Positioned(
            left: 0,
            right: 0,
            bottom: 10,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(frames.length, (i) {
                final isActive = i == _currentIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: isActive ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: isActive
                        ? AppColors.accent
                        : Colors.white.withAlpha(90),
                  ),
                );
              }),
            ),
          ),

        // ── Back button ───────────────────────────────────────────────────
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 12,
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(140),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back,
                  color: Colors.white, size: 20),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Track button ──────────────────────────────────────────────────────────────

class _TrackButton extends ConsumerStatefulWidget {
  final RawgGameDetail detail;
  final TrackedGame? trackedGame;
  const _TrackButton({required this.detail, required this.trackedGame});

  @override
  ConsumerState<_TrackButton> createState() => _TrackButtonState();
}

class _TrackButtonState extends ConsumerState<_TrackButton> {
  bool _loading = false;

  Future<void> _toggle() async {
    setState(() => _loading = true);
    try {
      final notifier = ref.read(trackedGamesNotifierProvider.notifier);
      if (widget.trackedGame != null) {
        await notifier.removeGame(widget.trackedGame!.id);
      } else {
        await notifier.addGame(widget.detail);
      }
    } catch (_) {
      final name = widget.detail.name;
      AppToast.show(
        widget.trackedGame != null
            ? 'Impossibile rimuovere "$name"'
            : 'Impossibile aggiungere "$name"',
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTracked = widget.trackedGame != null;
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _loading ? null : _toggle,
        icon: _loading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.black),
              )
            : Icon(isTracked ? Icons.check : Icons.add),
        label: Text(isTracked ? 'Nel backlog' : 'Aggiungi al backlog'),
        style: FilledButton.styleFrom(
          backgroundColor:
              isTracked ? AppColors.accent.withAlpha(180) : AppColors.accent,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

// ── UI helpers ────────────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.accent, size: 13),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  const _Tag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Text(
        label,
        style:
            const TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _ExpandableText extends StatefulWidget {
  final String text;
  const _ExpandableText({required this.text});

  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.text,
          style: const TextStyle(
              color: AppColors.textSecondary, fontSize: 14, height: 1.5),
          maxLines: _expanded ? null : 5,
          overflow:
              _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Text(
            _expanded ? 'Mostra meno' : 'Mostra tutto',
            style: const TextStyle(
              color: AppColors.accent,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorBody extends StatelessWidget {
  final String message;
  const _ErrorBody({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ],
        ),
      ),
    );
  }
}
