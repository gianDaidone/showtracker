import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/theme/app_theme.dart';
import '../../providers/series_providers.dart';

class ShowCard extends ConsumerWidget {
  final TrackedShow show;
  const ShowCard({super.key, required this.show});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watchedAsync = ref.watch(watchedCountProvider(show.id));

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => context.push('/series/detail/${show.tmdbId}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _Poster(path: show.posterPath),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      show.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    _StatusChip(status: show.status),
                    const SizedBox(height: 10),
                    watchedAsync.when(
                      data: (watched) => _Progress(
                        watched: watched,
                        total: show.totalEpisodes,
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
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

class _Poster extends StatelessWidget {
  final String? path;
  const _Poster({this.path});

  @override
  Widget build(BuildContext context) {
    const w = 60.0;
    const h = 90.0;
    final url = path != null
        ? 'https://image.tmdb.org/t/p/w185$path'
        : null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: w,
        height: h,
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
          child: Icon(Icons.tv, color: AppColors.textSecondary, size: 28),
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
    final color = _colors[status] ?? AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(120),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.label,
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  final int watched;
  final int? total;
  const _Progress({required this.watched, this.total});

  @override
  Widget build(BuildContext context) {
    if (total == null || total == 0) {
      return Text(
        '$watched visti',
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
      );
    }
    final pct = (watched / total!).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: Colors.white.withAlpha(30),
            valueColor: const AlwaysStoppedAnimation(AppColors.accent),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$watched / $total ep.',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}
