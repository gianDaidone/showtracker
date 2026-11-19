import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/media_image.dart';
import '../../data/models/tmdb_episode.dart';
import '../../data/models/tmdb_show_detail.dart';
import '../../data/watch_next_rules.dart';
import '../../providers/series_providers.dart';
import 'episode_code_badge.dart';
import 'episode_detail_sheet.dart';

class UpcomingEpisodeCard extends ConsumerStatefulWidget {
  final TrackedShow show;
  final TmdbNextEpisode episode;
  final DateTime? preciseAirTime;
  final String? seasonName;

  const UpcomingEpisodeCard({
    super.key,
    required this.show,
    required this.episode,
    this.preciseAirTime,
    this.seasonName,
  });

  @override
  ConsumerState<UpcomingEpisodeCard> createState() =>
      _UpcomingEpisodeCardState();
}

class _UpcomingEpisodeCardState extends ConsumerState<UpcomingEpisodeCard> {
  bool _expanded = false;

  void _openEpisode(TmdbEpisode episode, String? seasonName) {
    showEpisodeDetailSheet(
      context,
      showTitle: widget.show.title,
      showTmdbId: widget.show.tmdbId,
      showPosterPath: widget.show.posterPath,
      trackedShow: widget.show,
      season: widget.episode.seasonNumber,
      episodeNum: episode.episodeNumber,
      episode: episode,
      seasonName: seasonName,
    );
  }

  @override
  Widget build(BuildContext context) {
    final seasonNumber = widget.episode.seasonNumber;
    final season = ref
        .watch(seasonDetailProvider(
          showId: widget.show.tmdbId,
          seasonNumber: seasonNumber,
        ))
        .value;
    final seasonName =
        widget.seasonName ?? (widget.show.isAnime ? season?.name : null);
    final additionalEpisodes = simultaneousUpcomingEpisodes(
      next: widget.episode,
      episodes: season?.episodes ?? const [],
      preciseAirTime: widget.preciseAirTime,
    );
    final count = additionalEpisodes.length;
    final anchor = widget.episode.toTmdbEpisode();
    final releaseLabel = widget.preciseAirTime == null
        ? 'nello stesso giorno'
        : 'in contemporanea';

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
            episode: anchor,
            seasonNumber: seasonNumber,
            seasonName: seasonName,
            preciseAirTime: widget.preciseAirTime,
            onTap: () => _openEpisode(anchor, seasonName),
          ),
          if (count > 0) ...[
            const Divider(height: 1, color: AppColors.divider),
            Semantics(
              expanded: _expanded,
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  minimumSize: const Size(0, 48),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: const RoundedRectangleBorder(),
                ),
                onPressed: () => setState(() => _expanded = !_expanded),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(_expanded
                          ? 'Nascondi altri episodi'
                          : '+$count ${count == 1 ? 'episodio' : 'episodi'} $releaseLabel'),
                    ),
                    const SizedBox(width: 8),
                    Icon(_expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded),
                  ],
                ),
              ),
            ),
            if (_expanded)
              for (final episode in additionalEpisodes) ...[
                const Divider(height: 1, color: AppColors.divider),
                InkWell(
                  key: ValueKey(episode.episodeNumber),
                  onTap: () => _openEpisode(episode, seasonName),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                EpisodeCodeBadge(
                                  season: seasonNumber,
                                  episode: episode.episodeNumber,
                                  seasonName: seasonName,
                                ),
                                if (episode.name.isNotEmpty)
                                  Text(
                                    episode.name,
                                    style: const TextStyle(
                                        color: AppColors.textPrimary),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right_rounded,
                              color: AppColors.textSecondary),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
          ],
        ],
      ),
    );
  }
}

class _UpcomingEpisodeRow extends StatelessWidget {
  final TrackedShow show;
  final TmdbEpisode episode;
  final VoidCallback onTap;
  final int seasonNumber;
  final String? seasonName;
  final DateTime? preciseAirTime;

  const _UpcomingEpisodeRow({
    required this.onTap,
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
      onTap: onTap,
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
