import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/tmdb_episode.dart';
import '../../data/models/tmdb_show_detail.dart';
import '../../providers/series_providers.dart';
import 'episode_detail_sheet.dart';

class UpcomingEpisodeCard extends ConsumerStatefulWidget {
  final TrackedShow show;
  final TmdbNextEpisode episode;
  final DateTime airDate;

  final DateTime? preciseAirTime;
  final bool isFarFuture;
  final String? seasonName;
  final List<TmdbEpisode> additionalEpisodes;

  const UpcomingEpisodeCard({
    super.key,
    required this.show,
    required this.episode,
    required this.airDate,
    this.preciseAirTime,
    this.isFarFuture = false,
    this.seasonName,
    this.additionalEpisodes = const [],
  });

  @override
  ConsumerState<UpcomingEpisodeCard> createState() => _UpcomingEpisodeCardState();
}

class _UpcomingEpisodeCardState extends ConsumerState<UpcomingEpisodeCard> {
  bool _expanded = false;

  String _getImageUrl(String? stillPath) {
    if (stillPath != null) {
      return 'https://image.tmdb.org/t/p/w300$stillPath';
    }
    if (widget.show.posterPath != null) {
      return 'https://image.tmdb.org/t/p/w185${widget.show.posterPath}';
    }
    return '';
  }

  String get _airDateLabel {
    final today = DateTime.now();
    final todayMid = DateTime(today.year, today.month, today.day);
    final airMid = DateTime(widget.airDate.year, widget.airDate.month, widget.airDate.day);
    final diff = airMid.difference(todayMid).inDays;

    // Precise time suffix for anime
    String timeSuffix = '';
    if (widget.preciseAirTime != null) {
      final h = widget.preciseAirTime!.hour.toString().padLeft(2, '0');
      final m = widget.preciseAirTime!.minute.toString().padLeft(2, '0');
      timeSuffix = ' alle $h:$m';
    }

    if (diff == 0) return 'Oggi';
    if (diff == 1) return 'Domani$timeSuffix';
    if (diff <= 7) return 'Tra $diff giorni$timeSuffix';

    const months = [
      'gen', 'feb', 'mar', 'apr', 'mag', 'giu',
      'lug', 'ago', 'set', 'ott', 'nov', 'dic',
    ];
    final suffix = widget.airDate.year != today.year ? ' ${widget.airDate.year}' : '';
    return '${widget.airDate.day} ${months[widget.airDate.month - 1]}$suffix$timeSuffix';
  }

  Color get _badgeColor {
    final today = DateTime.now();
    final todayMid = DateTime(today.year, today.month, today.day);
    final airMid = DateTime(widget.airDate.year, widget.airDate.month, widget.airDate.day);
    final diff = airMid.difference(todayMid).inDays;
    if (diff == 0) return const Color(0xFF4CAF50);
    if (diff <= 2) return AppColors.accent;
    return AppColors.textSecondary;
  }

  // ── Badge dentro l'immagine ───────────────────────────────────────────────

  String get _imageBadgeLabel {
    final today = DateTime.now();
    final todayMid = DateTime(today.year, today.month, today.day);
    final airMid = DateTime(widget.airDate.year, widget.airDate.month, widget.airDate.day);
    final diff = airMid.difference(todayMid).inDays;

    if (diff == 0) {
      final time = widget.preciseAirTime ?? DateTime(widget.airDate.year, widget.airDate.month, widget.airDate.day, 9, 0);
      final h = time.hour.toString().padLeft(2, '0');
      final m = time.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }
    if (diff == 1) return 'Domani';

    const months = [
      'gen', 'feb', 'mar', 'apr', 'mag', 'giu',
      'lug', 'ago', 'set', 'ott', 'nov', 'dic',
    ];
    final suffix = widget.airDate.year != today.year ? ' ${widget.airDate.year}' : '';
    return '${widget.airDate.day} ${months[widget.airDate.month - 1]}$suffix';
  }

  Color get _imageBadgeColor {
    if (widget.isFarFuture) return const Color(0xFF424242);
    final today = DateTime.now();
    final todayMid = DateTime(today.year, today.month, today.day);
    final airMid = DateTime(widget.airDate.year, widget.airDate.month, widget.airDate.day);
    final diff = airMid.difference(todayMid).inDays;
    if (diff == 0) return const Color(0xFF4CAF50);
    return AppColors.accent;
  }

  @override
  Widget build(BuildContext context) {
    final seasonAsync = ref.watch(seasonDetailProvider(
      showId: widget.show.tmdbId,
      seasonNumber: widget.episode.seasonNumber,
    ));
    final loadedEpisodes = seasonAsync.valueOrNull?.episodes;
    final fullEpisode = loadedEpisodes
        ?.where((e) => e.episodeNumber == widget.episode.episodeNumber)
        .firstOrNull;

    final episodeName = fullEpisode?.name ?? widget.episode.name;
    final displayTitle = episodeName.isNotEmpty ? episodeName : 'Titolo non disponibile';

    final stillPath = fullEpisode?.stillPath ?? widget.episode.stillPath;
    final imageUrl = _getImageUrl(stillPath);
    final hasImage = imageUrl.isNotEmpty;
    
    String pad(int n) => n.toString().padLeft(2, '0');

    final hasAdditional = widget.additionalEpisodes.isNotEmpty;

    const topRadius = Radius.circular(14);
    final bottomRadius = hasAdditional ? Radius.zero : const Radius.circular(14);
    final mainCardRadius = BorderRadius.vertical(top: topRadius, bottom: bottomRadius);

    final mainCard = Card(
      margin: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: hasAdditional ? 0 : 8,
      ),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: mainCardRadius),
      child: InkWell(
        borderRadius: mainCardRadius,
        onTap: () => showEpisodeDetailSheet(
          context,
          showTitle: widget.show.title,
          showTmdbId: widget.show.tmdbId,
          showPosterPath: widget.show.posterPath,
          trackedShow: widget.show,
          season: widget.episode.seasonNumber,
          episodeNum: widget.episode.episodeNumber,
          episode: widget.episode.toTmdbEpisode(),
          seasonName: widget.seasonName,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                              imageUrl: imageUrl,
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
                      widget.show.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
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
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.divider.withAlpha(80),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Builder(
                            builder: (context) {
                              String label;
                              if (widget.seasonName != null) {
                                // Extract base name (remove " · Winter 2024" etc)
                                final baseName = widget.seasonName!.split(' · ').first.trim();
                                var abbr = baseName.replaceAll(RegExp(r'^(Stagione|Season)\s*', caseSensitive: false), 'S');
                                abbr = abbr.replaceAll(RegExp(r'\s*Parte\s*', caseSensitive: false), ' P');
                                // Aggiungi padding alla stagione se a una sola cifra (S1 -> S01)
                                abbr = abbr.replaceAllMapped(RegExp(r'(S)(\d)(?!\d)'), (match) {
                                  return '${match.group(1)}0${match.group(2)}';
                                });
                                label = '$abbr E${pad(widget.episode.episodeNumber)}';
                              } else {
                                label = 'S${pad(widget.episode.seasonNumber)} E${pad(widget.episode.episodeNumber)}';
                              }

                              return Text(
                                label,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                  letterSpacing: 0.3,
                                ),
                              );
                            },
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
                      displayTitle,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
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
    
    if (!hasAdditional) return mainCard;

    return Column(
      children: [
        mainCard,
        if (_expanded)
          ...widget.additionalEpisodes.map((ep) {
            return _SubEpisodeCard(
              show: widget.show,
              episode: ep,
              seasonNumber: widget.episode.seasonNumber,
              seasonName: widget.seasonName,
            );
          }),
        Card(
          margin: const EdgeInsets.only(left: 16, right: 16, bottom: 8, top: 0),
          color: AppColors.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.zero, bottom: Radius.circular(14)),
          ),
          child: InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: const BorderRadius.vertical(top: Radius.zero, bottom: Radius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _expanded
                        ? 'Nascondi altri episodi'
                        : '+${widget.additionalEpisodes.length} episodi in contemporanea',
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: AppColors.accent,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SubEpisodeCard extends ConsumerWidget {
  final TrackedShow show;
  final TmdbEpisode episode;
  final int seasonNumber;
  final String? seasonName;

  const _SubEpisodeCard({
    required this.show,
    required this.episode,
    required this.seasonNumber,
    this.seasonName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String pad(int n) => n.toString().padLeft(2, '0');
    
    final seasonAsync = ref.watch(seasonDetailProvider(
      showId: show.tmdbId,
      seasonNumber: seasonNumber,
    ));
    final loadedEpisodes = seasonAsync.valueOrNull?.episodes;
    final fullEpisode = loadedEpisodes
        ?.where((e) => e.episodeNumber == episode.episodeNumber)
        .firstOrNull;

    final episodeName = fullEpisode?.name ?? episode.name;
    final displayTitle = episodeName.isNotEmpty ? episodeName : 'Titolo non disponibile';

    final stillPath = fullEpisode?.stillPath ?? episode.stillPath;
    final imageUrl = stillPath != null
        ? 'https://image.tmdb.org/t/p/w185$stillPath'
        : show.posterPath != null
            ? 'https://image.tmdb.org/t/p/w185${show.posterPath}'
            : null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      color: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: InkWell(
        borderRadius: BorderRadius.zero,
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
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 96,
                  height: 80,
                  child: imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => const ColoredBox(color: AppColors.divider),
                          errorWidget: (_, __, ___) => const _ImageFallback(),
                        )
                      : const _ImageFallback(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.divider.withAlpha(80),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Builder(
                        builder: (context) {
                          String label;
                          if (seasonName != null) {
                            final baseName = seasonName!.split(' · ').first.trim();
                            var abbr = baseName.replaceAll(RegExp(r'^(Stagione|Season)\s*', caseSensitive: false), 'S');
                            abbr = abbr.replaceAll(RegExp(r'\s*Parte\s*', caseSensitive: false), ' P');
                            abbr = abbr.replaceAllMapped(RegExp(r'(S)(\d)(?!\d)'), (match) {
                              return '${match.group(1)}0${match.group(2)}';
                            });
                            label = '$abbr E${pad(episode.episodeNumber)}';
                          } else {
                            label = 'S${pad(seasonNumber)} E${pad(episode.episodeNumber)}';
                          }
                          return Text(
                            label,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                              letterSpacing: 0.3,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      displayTitle,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right, color: AppColors.accent, size: 22),
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
