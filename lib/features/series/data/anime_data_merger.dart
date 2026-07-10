import 'models/anilist_media.dart';
import 'models/normalized_anime_season.dart';
import 'models/tmdb_season.dart';

class AnimeDataMerger {
  // Formati primari: trasmissioni TV "classiche".
  static const _primaryFormats = {'TV', 'TV_SHORT'};
  // Fallback: ONA (Original Net Animation), tipico delle produzioni
  // streaming-first (Netflix, Crunchyroll Originals, ecc.). Lo usiamo solo se
  // non esiste nessun entry TV/TV_SHORT, così per gli anime TV "normali"
  // continuiamo a escludere gli ONA correlati (recap, extra, side-stories).
  static const _fallbackFormats = {'ONA'};

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
  }) {
    // 1. Prefer TV/TV_SHORT; fallback su ONA se non c'è nessun entry TV
    //    (anime streaming-only come Witch Hat Atelier hanno format=ONA).
    var filtered = anilistMedia
        .where((m) => _primaryFormats.contains(m.format))
        .toList();
    if (filtered.isEmpty) {
      filtered = anilistMedia
          .where((m) => _fallbackFormats.contains(m.format))
          .toList();
    }

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

    // AniList is authoritative for season count — no clamping to TMDB.
    // TMDB often groups multiple cours into fewer seasons; AniList always
    // splits correctly. tmdbSeasons is used only for positional mapping below.

    // 3. Build normalized seasons with smart TMDB season mapping based on episode counts
    final result = <NormalizedAnimeSeason>[];
    int tmdbIdx = 0;
    int currentGroupSum = 0;
    int maxMappedTmdbSeasonNumber = -1;

    for (var i = 0; i < filtered.length; i++) {
      final media = filtered[i];
      int tmdbSeasonNumber;
      
      if (tmdbIdx < tmdbSeasons.length) {
        final tmdbSeason = tmdbSeasons[tmdbIdx];
        tmdbSeasonNumber = tmdbSeason.seasonNumber;
        maxMappedTmdbSeasonNumber = tmdbSeasonNumber > maxMappedTmdbSeasonNumber 
            ? tmdbSeasonNumber 
            : maxMappedTmdbSeasonNumber;
        
        final eps = media.episodes ?? 0;
        currentGroupSum += eps;
        
        // If TMDB episode count is > 0 and we've reached it (allowing a diff of 2 for OVAs)
        if (tmdbSeason.episodeCount > 0 && 
            (currentGroupSum == tmdbSeason.episodeCount || 
             (currentGroupSum - tmdbSeason.episodeCount).abs() <= 2)) {
          tmdbIdx++;
          currentGroupSum = 0;
        } else if (eps == 0 && tmdbSeason.episodeCount == 0) {
          // Both have 0 episodes (upcoming), assume they match
          tmdbIdx++;
          currentGroupSum = 0;
        }
      } else {
        // Fallback if we run out of TMDB seasons (unlikely since AniList splits more)
        maxMappedTmdbSeasonNumber++;
        tmdbSeasonNumber = maxMappedTmdbSeasonNumber;
      }

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

    // 4. Fallback: append any remaining TMDB seasons that weren't consumed.
    // This perfectly catches upcoming seasons (like Season 3) that are on TMDB
    // but not yet mapped by Yuna / AniList.
    for (var i = tmdbIdx; i < tmdbSeasons.length; i++) {
      final tmdbSeason = tmdbSeasons[i];
      
      if (i == tmdbIdx && currentGroupSum > 0 && currentGroupSum < tmdbSeason.episodeCount) {
        final remainingEps = tmdbSeason.episodeCount - currentGroupSum;
        result.add(NormalizedAnimeSeason(
          seasonNumber: result.length + 1,
          tmdbSeasonNumber: tmdbSeason.seasonNumber,
          anilistId: -1,
          episodeCount: remainingEps,
          status: 'FINISHED', // Fallback status
          streamingEpisodes: const [],
        ));
        continue;
      }
      
      if (tmdbSeason.seasonNumber <= maxMappedTmdbSeasonNumber) continue;
      
      result.add(NormalizedAnimeSeason(
        seasonNumber: result.length + 1,
        tmdbSeasonNumber: tmdbSeason.seasonNumber,
        anilistId: -1, // Fallback ID indicates missing AniList mapping
        episodeCount: tmdbSeason.episodeCount,
        status: 'NOT_YET_RELEASED',
        season: null,
        seasonYear: null,
        titleRomaji: tmdbSeason.name,
        titleEnglish: tmdbSeason.name,
        averageScore: null,
        nextAiringEpisode: null,
        streamingEpisodes: [],
      ));
    }

    return result;
  }
}
