import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/tmdb_show_detail.dart';
import 'episode_detail_sheet.dart';

class UpcomingEpisodeCard extends StatelessWidget {
  final TrackedShow show;
  final TmdbNextEpisode episode;
  final DateTime airDate;

  /// Precise airing time from AniList (non-null for anime with exact schedule).
  final DateTime? preciseAirTime;

  const UpcomingEpisodeCard({
    super.key,
    required this.show,
    required this.episode,
    required this.airDate,
    this.preciseAirTime,
  });

  String get _imageUrl {
    if (episode.stillPath != null) {
      return 'https://image.tmdb.org/t/p/w300${episode.stillPath}';
    }
    if (show.posterPath != null) {
      return 'https://image.tmdb.org/t/p/w185${show.posterPath}';
    }
    return '';
  }

  String get _airDateLabel {
    final today = DateTime.now();
    final todayMid = DateTime(today.year, today.month, today.day);
    final airMid = DateTime(airDate.year, airDate.month, airDate.day);
    final diff = airMid.difference(todayMid).inDays;

    // Precise time suffix for anime
    String timeSuffix = '';
    if (preciseAirTime != null) {
      final h = preciseAirTime!.hour.toString().padLeft(2, '0');
      final m = preciseAirTime!.minute.toString().padLeft(2, '0');
      timeSuffix = ' alle $h:$m';
    }

    if (diff == 0) return 'Oggi$timeSuffix';
    if (diff == 1) return 'Domani$timeSuffix';
    if (diff <= 7) return 'Tra $diff giorni$timeSuffix';

    const months = [
      'gen', 'feb', 'mar', 'apr', 'mag', 'giu',
      'lug', 'ago', 'set', 'ott', 'nov', 'dic',
    ];
    final suffix = airDate.year != today.year ? ' ${airDate.year}' : '';
    return '${airDate.day} ${months[airDate.month - 1]}$suffix$timeSuffix';
  }

  Color get _badgeColor {
    final today = DateTime.now();
    final todayMid = DateTime(today.year, today.month, today.day);
    final airMid = DateTime(airDate.year, airDate.month, airDate.day);
    final diff = airMid.difference(todayMid).inDays;
    if (diff == 0) return const Color(0xFF4CAF50);
    if (diff <= 2) return AppColors.accent;
    return AppColors.textSecondary;
  }

  // ── Badge dentro l'immagine ───────────────────────────────────────────────

  String get _imageBadgeLabel {
    final today = DateTime.now();
    final todayMid = DateTime(today.year, today.month, today.day);
    final airMid = DateTime(airDate.year, airDate.month, airDate.day);
    final diff = airMid.difference(todayMid).inDays;

    if (diff == 0) {
      if (preciseAirTime != null) {
        final h = preciseAirTime!.hour.toString().padLeft(2, '0');
        final m = preciseAirTime!.minute.toString().padLeft(2, '0');
        return '$h:$m';
      }
      return 'Oggi';
    }
    if (diff == 1) return 'Domani';

    const months = [
      'gen', 'feb', 'mar', 'apr', 'mag', 'giu',
      'lug', 'ago', 'set', 'ott', 'nov', 'dic',
    ];
    final suffix = airDate.year != today.year ? ' ${airDate.year}' : '';
    return '${airDate.day} ${months[airDate.month - 1]}$suffix';
  }

  Color get _imageBadgeColor {
    final today = DateTime.now();
    final todayMid = DateTime(today.year, today.month, today.day);
    final airMid = DateTime(airDate.year, airDate.month, airDate.day);
    final diff = airMid.difference(todayMid).inDays;
    if (diff == 0) return const Color(0xFF4CAF50);
    return AppColors.accent;
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = _imageUrl.isNotEmpty;
    String pad(int n) => n.toString().padLeft(2, '0');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => showEpisodeDetailSheet(
          context,
          showTitle: show.title,
          showTmdbId: show.tmdbId,
          showPosterPath: show.posterPath,
          trackedShow: show,
          season: episode.seasonNumber,
          episodeNum: episode.episodeNumber,
          episode: episode.toTmdbEpisode(),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Immagine + badge data ──────────────────────────────────
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 96,
                  height: 80,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      hasImage
                          ? CachedNetworkImage(
                              imageUrl: _imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (_, __) =>
                                  const ColoredBox(color: AppColors.divider),
                              errorWidget: (_, __, ___) =>
                                  const _ImageFallback(),
                            )
                          : const _ImageFallback(),
                      // Badge data in basso a destra
                      Positioned(
                        right: 4,
                        bottom: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: _imageBadgeColor,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            _imageBadgeLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // ── Info ───────────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Titolo serie
                    Text(
                      show.title,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    // Badge S##E## + data
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withAlpha(30),
                            border:
                                Border.all(color: AppColors.accent.withAlpha(120)),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            'S${pad(episode.seasonNumber)}E${pad(episode.episodeNumber)}',
                            style: const TextStyle(
                              color: AppColors.accent,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.calendar_today_outlined,
                            size: 12, color: _badgeColor),
                        const SizedBox(width: 4),
                        Text(
                          _airDateLabel,
                          style: TextStyle(
                            color: _badgeColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),

                    // Titolo episodio
                    Text(
                      episode.name.isNotEmpty
                          ? episode.name
                          : 'Titolo non disponibile',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // ── Freccia ────────────────────────────────────────────────
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right,
                  color: AppColors.accent, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) => const ColoredBox(
        color: AppColors.divider,
        child: Center(
          child: Icon(Icons.tv, color: AppColors.textSecondary, size: 24),
        ),
      );
}
