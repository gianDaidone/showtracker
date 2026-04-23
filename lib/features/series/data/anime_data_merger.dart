import 'models/anilist_media.dart';
import 'models/normalized_anime_season.dart';
import 'models/tmdb_season.dart';

class AnimeDataMerger {
  static const _mainFormats = {'TV', 'TV_SHORT'};
  static const _seasonOrder = {
    'WINTER': 0,
    'SPRING': 1,
    'SUMMER': 2,
    'FALL': 3,
  };

  /// Merges TMDB seasons with AniList media into normalized anime seasons.
  ///
  /// [tmdbSeasons] are the non-special seasons from TmdbShowDetail.
  /// [anilistMedia] are the raw AniList media entries for this show.
  /// [maxSeasons] is TmdbShowDetail.numberOfSeasons (clamps the result).
  static List<NormalizedAnimeSeason> merge({
    required List<TmdbSeason> tmdbSeasons,
    required List<AniListMedia> anilistMedia,
    int? maxSeasons,
  }) {
    // 1. Filter to main formats only (no OVA, Movie, Special, ONA)
    var filtered = anilistMedia
        .where((m) => _mainFormats.contains(m.format))
        .toList();

    if (filtered.isEmpty) return [];

    // 2. Sort deterministically: year ASC, season order ASC, id ASC
    filtered.sort((a, b) {
      final yearCmp = (a.seasonYear ?? 0).compareTo(b.seasonYear ?? 0);
      if (yearCmp != 0) return yearCmp;
      final orderA = _seasonOrder[a.season] ?? 99;
      final orderB = _seasonOrder[b.season] ?? 99;
      final orderCmp = orderA.compareTo(orderB);
      if (orderCmp != 0) return orderCmp;
      return a.id.compareTo(b.id);
    });

    // 3. Clamp to TMDB season count
    if (maxSeasons != null && filtered.length > maxSeasons) {
      filtered = filtered.take(maxSeasons).toList();
    }

    // 4. Build normalized seasons with positional TMDB season mapping
    final result = <NormalizedAnimeSeason>[];
    for (var i = 0; i < filtered.length; i++) {
      final media = filtered[i];
      // Positional mapping: AniList season i → TMDB seasons[i]
      final tmdbSeasonNumber =
          i < tmdbSeasons.length ? tmdbSeasons[i].seasonNumber : (i + 1);

      result.add(NormalizedAnimeSeason(
        seasonNumber: i + 1,
        tmdbSeasonNumber: tmdbSeasonNumber,
        anilistId: media.id,
        episodeCount: media.episodes ?? 0,
        status: media.status,
        season: media.season,
        seasonYear: media.seasonYear,
        titleRomaji: media.titleRomaji,
        titleEnglish: media.titleEnglish,
        averageScore: media.averageScore,
        nextAiringEpisode: media.nextAiringEpisode,
        streamingEpisodes: media.streamingEpisodes,
      ));
    }

    return result;
  }
}
