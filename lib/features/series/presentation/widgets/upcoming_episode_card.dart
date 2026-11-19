import 'package:flutter/material.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/media_image.dart';
import '../../data/models/tmdb_episode.dart';
import '../../data/models/tmdb_show_detail.dart';
import 'episode_code_badge.dart';
import 'episode_detail_sheet.dart';

class UpcomingEpisodeCard extends StatefulWidget {
  final TrackedShow show;
  final TmdbNextEpisode episode;
  final DateTime? preciseAirTime;
  final String? seasonName;
  final List<TmdbEpisode> additionalEpisodes;

  const UpcomingEpisodeCard({
    super.key,
    required this.show,
    required this.episode,
    this.preciseAirTime,
    this.seasonName,
    this.additionalEpisodes = const [],
  });

  @override
  State<UpcomingEpisodeCard> createState() => _UpcomingEpisodeCardState();
}

class _UpcomingEpisodeCardState extends State<UpcomingEpisodeCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _UpcomingEpisodeRow(
            show: widget.show,
            episode: widget.episode.toTmdbEpisode(),
            seasonNumber: widget.episode.seasonNumber,
            seasonName: widget.seasonName,
            preciseAirTime: widget.preciseAirTime,
          ),
          if (_expanded)
            for (final episode in widget.additionalEpisodes)
              _UpcomingEpisodeRow(
                key: ValueKey(episode.episodeNumber),
                show: widget.show,
                episode: episode,
                seasonNumber: widget.episode.seasonNumber,
                seasonName: widget.seasonName,
              ),
          if (widget.additionalEpisodes.isNotEmpty)
            TextButton(
              onPressed: () => setState(() => _expanded = !_expanded),
              child: Text(
                _expanded
                    ? 'Nascondi altri episodi'
                    : '+${widget.additionalEpisodes.length} episodi in contemporanea',
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}

class _UpcomingEpisodeRow extends StatelessWidget {
  final TrackedShow show;
  final TmdbEpisode episode;
  final int seasonNumber;
  final String? seasonName;
  final DateTime? preciseAirTime;

  const _UpcomingEpisodeRow({
    super.key,
    required this.show,
    required this.episode,
    required this.seasonNumber,
    this.seasonName,
    this.preciseAirTime,
  });

  @override
  Widget build(BuildContext context) {
    final localTime = preciseAirTime?.toLocal();
    final timeLabel = localTime == null
        ? null
        : MaterialLocalizations.of(context).formatTimeOfDay(
            TimeOfDay.fromDateTime(localTime),
            alwaysUse24HourFormat: true,
          );
    final posterPath = show.posterPath;

    return InkWell(
      onTap: () => showEpisodeDetailSheet(
        context,
        showTitle: show.title,
        showTmdbId: show.tmdbId,
        showPosterPath: show.posterPath,
        trackedShow: show,
        season: seasonNumber,
        episodeNum: episode.episodeNumber,
        episode: episode,
        seasonName: seasonName,
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                width: 42,
                height: 60,
                child: posterPath == null
                    ? const _ImageFallback()
                    : MediaImage(
                        source: MediaImageSource.tmdbPoster,
                        imageUrl: 'https://image.tmdb.org/t/p/w185$posterPath',
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            const ColoredBox(color: AppColors.divider),
                        errorWidget: (_, __, ___) => const _ImageFallback(),
                      ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    show.title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  EpisodeCodeBadge(
                    season: seasonNumber,
                    episode: episode.episodeNumber,
                    seasonName: seasonName,
                  ),
                ],
              ),
            ),
            if (timeLabel != null)
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Text(
                  timeLabel,
                  semanticsLabel: 'Orario di uscita $timeLabel',
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
          ],
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
          child: Icon(Icons.tv, color: AppColors.textSecondary, size: 19),
        ),
      );
}
