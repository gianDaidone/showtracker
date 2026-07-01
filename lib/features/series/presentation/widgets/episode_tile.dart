import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/tmdb_episode.dart';

class EpisodeTile extends StatelessWidget {
  final TmdbEpisode episode;
  final bool isWatched;

  /// Null = sola lettura (show non ancora tracciato).
  final ValueChanged<bool>? onToggle;

  /// Apre la modale di dettaglio episodio.
  final VoidCallback? onTap;

  /// Se true, indica che l'episodio esce in contemporanea con altri.
  final bool isBatchRelease;

  const EpisodeTile({
    super.key,
    required this.episode,
    required this.isWatched,
    this.onToggle,
    this.onTap,
    this.isBatchRelease = false,
  });

  @override
  Widget build(BuildContext context) {
    final aired = episode.hasAired;
    final textColor = aired ? AppColors.textPrimary : AppColors.textSecondary;

    return Opacity(
      opacity: aired ? 1.0 : 0.55,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: _EpisodeStill(
          stillPath: episode.stillPath,
          episodeNumber: episode.episodeNumber,
        ),
        title: Text(
          episode.name,
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            decoration: isWatched ? TextDecoration.lineThrough : null,
            decorationColor: AppColors.textSecondary,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: _buildSubtitle(),
        trailing: onToggle != null && aired
            ? Checkbox(
                value: isWatched,
                onChanged: (v) => onToggle!(v ?? false),
                activeColor: AppColors.accent,
                checkColor: Colors.black,
                side: const BorderSide(color: AppColors.textSecondary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              )
            : null,
      ),
    );
  }

  Widget? _buildSubtitle() {
    // Precise airingAt from AniList (next episode of an airing anime)
    if (episode.airingAt != null) {
      final dt = episode.airingAt!;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final epDay = DateTime(dt.year, dt.month, dt.day);
      final diff = epDay.difference(today).inDays;
      final timeStr =
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

      final dayLabel = switch (diff) {
        0 => 'Oggi',
        1 => 'Domani',
        _ when diff > 0 => 'Tra $diff giorni',
        _ => _formatDate(dt.toIso8601String().substring(0, 10)),
      };

      return Text(
        '$dayLabel alle $timeStr',
        style: TextStyle(
          color: isBatchRelease ? Colors.orange : AppColors.accent,
          fontSize: 11,
          fontWeight: isBatchRelease ? FontWeight.bold : FontWeight.w500,
        ),
      );
    }

    // Standard date from TMDB
    if (episode.airDate != null) {
      return Text(
        _formatDate(episode.airDate!),
        style: TextStyle(
          color: isBatchRelease ? Colors.orange : AppColors.textSecondary,
          fontSize: 11,
          fontWeight: isBatchRelease ? FontWeight.bold : FontWeight.normal,
        ),
      );
    }

    return null;
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day.toString().padLeft(2, '0')}/'
          '${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}

// ── Still dell'episodio ───────────────────────────────────────────────────────

class _EpisodeStill extends StatelessWidget {
  final String? stillPath;
  final int episodeNumber;

  const _EpisodeStill({required this.stillPath, required this.episodeNumber});

  static const double _w = 90;
  static const double _h = 51; // 16:9

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        width: _w,
        height: _h,
        child: stillPath != null
            ? CachedNetworkImage(
                imageUrl: '$kTmdbImageBase/w185$stillPath',
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    const ColoredBox(color: AppColors.divider),
                errorWidget: (_, __, ___) =>
                    _NumberFallback(number: episodeNumber),
              )
            : _NumberFallback(number: episodeNumber),
      ),
    );
  }
}

class _NumberFallback extends StatelessWidget {
  final int number;
  const _NumberFallback({required this.number});

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: AppColors.divider,
        child: Center(
          child: Text(
            '$number',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
      );
}
