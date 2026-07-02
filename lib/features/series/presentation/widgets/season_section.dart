import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/tmdb_show_detail.dart';
import '../../data/models/tmdb_season.dart';
import '../../providers/series_providers.dart';
import 'episode_detail_sheet.dart';
import 'episode_tile.dart';

class SeasonSection extends ConsumerStatefulWidget {
  final TmdbShowDetail detail;
  final TmdbSeason season;
  final TrackedShow? trackedShow;

  const SeasonSection({
    super.key,
    required this.detail,
    required this.season,
    required this.trackedShow,
  });

  @override
  ConsumerState<SeasonSection> createState() => _SeasonSectionState();
}

class _SeasonSectionState extends ConsumerState<SeasonSection> {
  bool _expanded = false;

  int get _watchedInSeason {
    if (widget.trackedShow == null) return 0;
    final map = ref
            .watch(watchedEpisodesBySeasonProvider(widget.trackedShow!.id))
            .valueOrNull ??
        {};
    return map[widget.season.seasonNumber]?.length ?? 0;
  }

  String get _episodeCountLabel {
    final total = widget.season.episodeCount;
    final watched = widget.trackedShow != null ? _watchedInSeason : null;

    if (total > 0) {
      return watched != null
          ? '$watched / $total ep. visti'
          : '$total episodi';
    }
    // Unknown total (airing season, AniList hasn't set episodes count yet)
    return watched != null
        ? watched > 0 ? '$watched ep. visti' : 'In corso'
        : 'In corso';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.season.name ?? 'Stagione ${widget.season.seasonNumber}',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _episodeCountLabel,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1, color: AppColors.divider),
        if (_expanded)
          _SeasonEpisodes(
            detail: widget.detail,
            season: widget.season,
            trackedShow: widget.trackedShow,
          ),
      ],
    );
  }
}

class _SeasonEpisodes extends ConsumerWidget {
  final TmdbShowDetail detail;
  final TmdbSeason season;
  final TrackedShow? trackedShow;

  const _SeasonEpisodes({
    required this.detail,
    required this.season,
    required this.trackedShow,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seasonAsync = ref.watch(seasonDetailProvider(
      showId: detail.id,
      seasonNumber: season.seasonNumber,
    ));

    final watchedMap = trackedShow != null
        ? ref
                .watch(watchedEpisodesBySeasonProvider(trackedShow!.id))
                .valueOrNull ??
            {}
        : <int, Set<int>>{};
    final watchedInSeason = watchedMap[season.seasonNumber] ?? {};

    return seasonAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Errore nel caricamento episodi:\n$e',
          style: const TextStyle(color: Colors.redAccent, fontSize: 13),
        ),
      ),
      data: (seasonDetail) {
        final episodes = seasonDetail.episodes ?? [];
        if (episodes.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Nessun episodio disponibile.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
        }

        // Calcola quali date hanno uscite multiple (batch release)
        final batchDates = <String>{};
        final dateCounts = <String, int>{};
        for (final ep in episodes) {
          // Usa solo la data (YYYY-MM-DD) per il conteggio
          final key = ep.airingAt != null
              ? '${ep.airingAt!.year}-${ep.airingAt!.month.toString().padLeft(2, '0')}-${ep.airingAt!.day.toString().padLeft(2, '0')}'
              : ep.airDate;
          if (key != null && key.isNotEmpty) {
            dateCounts[key] = (dateCounts[key] ?? 0) + 1;
          }
        }
        for (final entry in dateCounts.entries) {
          if (entry.value > 1) {
            batchDates.add(entry.key);
          }
        }

        return Column(
          children: episodes.map((ep) {
            final key = ep.airingAt != null
                ? '${ep.airingAt!.year}-${ep.airingAt!.month.toString().padLeft(2, '0')}-${ep.airingAt!.day.toString().padLeft(2, '0')}'
                : ep.airDate;
            final isBatch = key != null && batchDates.contains(key);

            return EpisodeTile(
              episode: ep,
              isBatchRelease: isBatch,
              isWatched: watchedInSeason.contains(ep.episodeNumber),
              onToggle: trackedShow != null
                  ? (watched) {
                      if (watched) {
                        markEpisodeWatchedWithCheck(
                          context,
                          ref,
                          showId: trackedShow!.id,
                          targetSeason: season.seasonNumber,
                          targetEpisode: ep.episodeNumber,
                        );
                      } else {
                        ref.read(showsDaoProvider).markEpisodeWatched(
                          trackedShow!.id,
                          season.seasonNumber,
                          ep.episodeNumber,
                          watched: false,
                        );
                      }
                    }
                  : null,
              onTap: () => showEpisodeDetailSheet(
                context,
                showTitle: detail.name,
                showTmdbId: detail.id,
                showPosterPath: detail.posterPath,
                trackedShow: trackedShow,
                season: season.seasonNumber,
                episodeNum: ep.episodeNumber,
                episode: ep,
                seasonName: season.name,
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
