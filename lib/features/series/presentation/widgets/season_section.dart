import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/local_show_snapshot.dart';
import '../../data/models/tmdb_episode.dart';
import '../../data/models/tmdb_show_detail.dart';
import '../../data/models/tmdb_season.dart';
import '../../providers/series_providers.dart';
import 'episode_detail_sheet.dart';
import 'episode_tile.dart';

/// A native sliver section: headers keep their expansion state while episode
/// rows are mounted only within the outer scroll view's viewport/cache extent.
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

  String _episodeCountLabel(int? watched) {
    final total = widget.season.episodeCount;
    if (total > 0) {
      return watched != null ? '$watched / $total ep. visti' : '$total episodi';
    }
    // Unknown total (airing season, AniList hasn't set episodes count yet)
    return watched != null && watched > 0 ? '$watched ep. visti' : 'In corso';
  }

  @override
  Widget build(BuildContext context) {
    final trackedShow = widget.trackedShow;
    final watched = trackedShow == null
        ? null
        : ref.watch(
            watchedEpisodesBySeasonProvider(trackedShow.id).select(
              (value) => value.value?[widget.season.seasonNumber]?.length ?? 0,
            ),
          );

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.season.name ??
                                  'Stagione ${widget.season.seasonNumber}',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _episodeCountLabel(watched),
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
            ],
          ),
        ),
        if (_expanded)
          _SeasonEpisodes(
            detail: widget.detail,
            season: widget.season,
            trackedShow: trackedShow,
          ),
      ],
    );
  }
}

class _SeasonEpisodes extends ConsumerStatefulWidget {
  final TmdbShowDetail detail;
  final TmdbSeason season;
  final TrackedShow? trackedShow;

  const _SeasonEpisodes({
    required this.detail,
    required this.season,
    required this.trackedShow,
  });

  @override
  ConsumerState<_SeasonEpisodes> createState() => _SeasonEpisodesState();
}

class _SeasonEpisodesState extends ConsumerState<_SeasonEpisodes> {
  List<TmdbEpisode>? _episodes;
  List<bool> _batchReleases = const [];

  String? _releaseDate(TmdbEpisode episode) {
    final airingAt = episode.airingAt;
    return airingAt != null
        ? '${airingAt.year}-${airingAt.month.toString().padLeft(2, '0')}-${airingAt.day.toString().padLeft(2, '0')}'
        : episode.airDate;
  }

  void _updateBatchReleases(List<TmdbEpisode> episodes) {
    // Metadata is immutable. Watched-map emissions must not regroup hundreds
    // of episodes; only a new metadata list needs the full scan.
    if (identical(_episodes, episodes)) return;
    _episodes = episodes;
    final dateCounts = <String, int>{};
    for (final episode in episodes) {
      final date = _releaseDate(episode);
      if (date != null && date.isNotEmpty) {
        dateCounts[date] = (dateCounts[date] ?? 0) + 1;
      }
    }
    _batchReleases = [
      for (final episode in episodes)
        (dateCounts[_releaseDate(episode)] ?? 0) > 1,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final detail = widget.detail;
    final season = widget.season;
    final trackedShow = widget.trackedShow;
    final canMarkEpisodes = !detail.isAnime || detail.animeSeasonsData != null;
    final seasonAsync = ref.watch(seasonDetailProvider(
      showId: detail.id,
      seasonNumber: season.seasonNumber,
    ));

    final watchedInSeason = trackedShow != null
        ? ref.watch(
              watchedEpisodesBySeasonProvider(trackedShow.id).select(
                (value) => value.value?[season.seasonNumber],
              ),
            ) ??
            const <int>{}
        : const <int>{};

    return seasonAsync.when(
      loading: () => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, _) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            isRecoverableSeriesError(e)
                ? 'Impossibile caricare gli episodi. Controlla la connessione e riprova.'
                : 'Errore nel caricamento episodi:\n$e',
            style: const TextStyle(color: Colors.redAccent, fontSize: 13),
          ),
        ),
      ),
      data: (seasonDetail) {
        final episodes = seasonDetail.episodes ?? const <TmdbEpisode>[];
        if (episodes.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                seasonDetail.isLocalSnapshot
                    ? 'Episodi non salvati sul dispositivo. Aggiorna i dati quando sei online.'
                    : 'Nessun episodio disponibile.',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
          );
        }
        _updateBatchReleases(episodes);

        return SliverList.builder(
          itemCount: episodes.length,
          itemBuilder: (context, index) {
            final ep = episodes[index];
            return EpisodeTile(
              key: ValueKey((detail.id, season.seasonNumber, ep.episodeNumber)),
              episode: ep,
              isBatchRelease: _batchReleases[index],
              isWatched: watchedInSeason.contains(ep.episodeNumber),
              onToggle: trackedShow != null && canMarkEpisodes
                  ? (watched) {
                      if (watched) {
                        markEpisodeWatchedWithCheck(
                          context,
                          ref,
                          showId: trackedShow.id,
                          targetSeason: season.seasonNumber,
                          targetEpisode: ep.episodeNumber,
                        );
                      } else {
                        ref.read(showsDaoProvider).markEpisodeWatched(
                              trackedShow.id,
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
                trackedShow: canMarkEpisodes ? trackedShow : null,
                season: season.seasonNumber,
                episodeNum: ep.episodeNumber,
                episode: ep,
                seasonName: season.name,
              ),
            );
          },
        );
      },
    );
  }
}
