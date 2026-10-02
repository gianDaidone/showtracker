import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/database/app_database.dart';
import '../../../core/services/app_toast.dart';
import '../../../core/widgets/animated_refresh_button.dart';
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
        // ── Intestazione: pulsanti, titolo, carosello screenshot ─────────
        SliverToBoxAdapter(
          child: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TopBar(rawgId: detail.id),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                  child: _TitleBlock(detail: detail),
                ),
                _ScreenshotCarousel(frames: frames),
              ],
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Generi
                if (detail.genres.isNotEmpty) ...[
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: detail.genres.map((g) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        g,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                      ),
                    )).toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                // Pulsante aggiungi / rimuovi
                _TrackButton(detail: detail, trackedGame: trackedGame),

                const SizedBox(height: 24),
                _InfoBox(detail: detail),
                const SizedBox(height: 24),

                // Descrizione
                if (detail.overview?.isNotEmpty == true) ...[
                  const Text(
                    'Trama',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
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
                
                // RAWG Attribution
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.videogame_asset, color: AppColors.textSecondary, size: 28),
                      const SizedBox(height: 12),
                      const Text(
                        'Video game data and information are sourced from RAWG.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            final slug = detail.slug.isNotEmpty ? detail.slug : detail.id.toString();
                            launchUrl(Uri.parse('https://rawg.io/games/$slug'), mode: LaunchMode.externalApplication);
                          },
                          icon: const Icon(Icons.open_in_new, color: AppColors.textPrimary, size: 18),
                          label: const Text(
                            'Vedi su RAWG',
                            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: AppColors.divider),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Top bar ───────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final int rawgId;
  const _TopBar({required this.rawgId});

  @override
  Widget build(BuildContext context) {
    // Nella stessa Row: restano centrati sulla stessa linea anche quando il
    // pulsante aggiorna si allarga in "Aggiornamento…".
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SizedBox(
        height: 36,
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/games');
                }
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back,
                    color: Colors.white, size: 20),
              ),
            ),
            const Spacer(),
            _RefreshButton(rawgId: rawgId),
          ],
        ),
      ),
    );
  }
}

// ── Titolo + voto/anno ────────────────────────────────────────────────────────

class _TitleBlock extends StatelessWidget {
  final RawgGameDetail detail;
  const _TitleBlock({required this.detail});

  @override
  Widget build(BuildContext context) {
    final hasRating = detail.voteAverage > 0;
    final hasYear = detail.year != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          detail.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
        ),
        if (hasRating || hasYear) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              if (hasRating) ...[
                const Icon(Icons.star, color: AppColors.accent, size: 16),
                const SizedBox(width: 4),
                Text(
                  detail.voteAverage.toStringAsFixed(1),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
              if (hasRating && hasYear)
                const Text(
                  '  ·  ',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
              if (hasYear)
                Text(
                  '${detail.year}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
            ],
          ),
        ],
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

  static const double _hPadding = 16;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openViewer(int index) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => _ScreenshotViewer(
          frames: widget.frames,
          initialIndex: index,
          // Al ritorno il carosello mostra l'ultima immagine vista
          onPageChanged: (i) {
            if (_controller.hasClients) _controller.jumpToPage(i);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final frames = widget.frames;
    // Gli screenshot RAWG sono 16:9: l'area immagine ha lo stesso rapporto,
    // quindi si vedono interi invece di essere ritagliati.
    final imageHeight =
        (MediaQuery.sizeOf(context).width - 2 * _hPadding) * 9 / 16;

    return Column(
      children: [
        // ── Immagini ─────────────────────────────────────────────────────
        SizedBox(
          height: imageHeight,
          child: frames.isEmpty
              ? const _FrameCard(
                  child: Center(
                    child: Icon(Icons.videogame_asset,
                        size: 64, color: AppColors.textSecondary),
                  ),
                )
              : PageView.builder(
                  controller: _controller,
                  itemCount: frames.length,
                  onPageChanged: (i) => setState(() => _currentIndex = i),
                  itemBuilder: (_, i) => GestureDetector(
                    onTap: () => _openViewer(i),
                    child: _FrameCard(
                      child: CachedNetworkImage(
                        imageUrl: frames[i],
                        fit: BoxFit.contain,
                        placeholder: (_, __) => const SizedBox.shrink(),
                        errorWidget: (_, __, ___) => const Center(
                          child: Icon(Icons.videogame_asset,
                              size: 48, color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                  ),
                ),
        ),

        // ── Dot indicators ────────────────────────────────────────────────
        if (frames.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 10),
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
      ],
    );
  }
}

/// Riquadro arrotondato di una pagina del carosello, allineato ai margini del
/// testo. Gli screenshot non 16:9 restano interi su sfondo `surface`.
class _FrameCard extends StatelessWidget {
  final Widget child;
  const _FrameCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: _ScreenshotCarouselState._hPadding),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ColoredBox(
          color: AppColors.surface,
          child: SizedBox.expand(child: child),
        ),
      ),
    );
  }
}

// ── Screenshot viewer (schermo intero) ────────────────────────────────────────

class _ScreenshotViewer extends StatefulWidget {
  final List<String> frames;
  final int initialIndex;
  final ValueChanged<int> onPageChanged;
  const _ScreenshotViewer({
    required this.frames,
    required this.initialIndex,
    required this.onPageChanged,
  });

  @override
  State<_ScreenshotViewer> createState() => _ScreenshotViewerState();
}

class _ScreenshotViewerState extends State<_ScreenshotViewer> {
  late final _controller = PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;
  // Con l'immagine ingrandita lo swipe orizzontale serve a spostarsi
  // nell'immagine, non a cambiare pagina
  bool _zoomed = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final frames = widget.frames;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            physics: _zoomed ? const NeverScrollableScrollPhysics() : null,
            itemCount: frames.length,
            onPageChanged: (i) {
              setState(() => _index = i);
              widget.onPageChanged(i);
            },
            itemBuilder: (_, i) => _ZoomableImage(
              url: frames[i],
              onZoomChanged: (z) => setState(() => _zoomed = z),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(140),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close,
                          color: Colors.white, size: 20),
                    ),
                  ),
                  const Spacer(),
                  if (frames.length > 1)
                    Text(
                      '${_index + 1} / ${frames.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ZoomableImage extends StatefulWidget {
  final String url;
  final ValueChanged<bool> onZoomChanged;
  const _ZoomableImage({required this.url, required this.onZoomChanged});

  @override
  State<_ZoomableImage> createState() => _ZoomableImageState();
}

class _ZoomableImageState extends State<_ZoomableImage> {
  final _transform = TransformationController();
  bool _zoomed = false;

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  void _onInteractionEnd(ScaleEndDetails _) {
    final zoomed = _transform.value.getMaxScaleOnAxis() > 1.01;
    if (zoomed == _zoomed) return;
    setState(() => _zoomed = zoomed);
    widget.onZoomChanged(zoomed);
  }

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      transformationController: _transform,
      maxScale: 4,
      // A scala 1 il pan resta disattivato, così lo swipe arriva al PageView
      panEnabled: _zoomed,
      onInteractionEnd: _onInteractionEnd,
      child: Center(
        child: CachedNetworkImage(
          imageUrl: widget.url,
          fit: BoxFit.contain,
          placeholder: (_, __) => const Center(
            child: CircularProgressIndicator(color: AppColors.accent),
          ),
          errorWidget: (_, __, ___) => const Icon(Icons.videogame_asset,
              size: 64, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

// ── Refresh button ────────────────────────────────────────────────────────────

class _RefreshButton extends ConsumerStatefulWidget {
  final int rawgId;
  const _RefreshButton({required this.rawgId});

  @override
  ConsumerState<_RefreshButton> createState() => _RefreshButtonState();
}

class _RefreshButtonState extends ConsumerState<_RefreshButton> {
  RefreshState _state = RefreshState.idle;

  Future<void> _refresh() async {
    if (_state != RefreshState.idle) return;
    setState(() => _state = RefreshState.refreshing);

    try {
      await Future.wait([
        Future(() async {
          ref.invalidate(gameDetailProvider(widget.rawgId));
          ref.invalidate(gameScreenshotsProvider(widget.rawgId));
        }),
        Future.delayed(const Duration(milliseconds: 1500)),
      ]);

      if (mounted) {
        setState(() => _state = RefreshState.success);
        await Future.delayed(const Duration(milliseconds: 1500));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _state = RefreshState.error);
        await Future.delayed(const Duration(milliseconds: 1500));
      }
    } finally {
      if (mounted) setState(() => _state = RefreshState.idle);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedRefreshButton(
      state: _state,
      onPressed: _refresh,
      idleBackgroundColor: AppColors.surface,
      // Lo posiziona già la Row dell'header, allineato al pulsante indietro
      margin: EdgeInsets.zero,
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
      child: isTracked
          ? OutlinedButton.icon(
              onPressed: _loading ? null : _toggle,
              icon: const Icon(Icons.check, color: AppColors.textSecondary),
              label: const Text(
                'Nel backlog',
                style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.divider),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            )
          : FilledButton.icon(
              onPressed: _loading ? null : _toggle,
              icon: _loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
                    )
                  : const Icon(Icons.add, color: AppColors.accent),
              label: const Text(
                'Aggiungi al backlog',
                style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white.withAlpha(24),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
    );
  }
}

// ── UI helpers ────────────────────────────────────────────────────────────────


class _Tag extends StatelessWidget {
  final String label;
  const _Tag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.divider.withAlpha(80),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
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

// ── Info Box ──────────────────────────────────────────────────────────────────

class _InfoBox extends StatelessWidget {
  final RawgGameDetail detail;
  const _InfoBox({required this.detail});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _InfoItem(
                  label: 'Sviluppatore',
                  value: detail.developers.isNotEmpty 
                      ? detail.developers.join(', ')
                      : '-',
                  align: TextAlign.start,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _InfoItem(
                  label: 'Publisher',
                  value: detail.publishers.isNotEmpty 
                      ? detail.publishers.join(', ')
                      : '-',
                  align: TextAlign.start,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _InfoItem(
            label: 'Piattaforme',
            value: detail.platforms.isNotEmpty 
                ? detail.platforms.join(', ')
                : '-',
            align: TextAlign.start,
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  final TextAlign align;
  const _InfoItem({required this.label, required this.value, this.align = TextAlign.center});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: align == TextAlign.start ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          textAlign: align,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 13,
            height: 1.4,
          ),
          textAlign: align,
        ),
      ],
    );
  }
}
