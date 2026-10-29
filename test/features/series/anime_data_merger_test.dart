import 'package:flutter_test/flutter_test.dart';
import 'package:showtracker/features/series/data/anime_data_merger.dart';
import 'package:showtracker/features/series/data/models/anilist_media.dart';
import 'package:showtracker/features/series/data/models/normalized_anime_season.dart';
import 'package:showtracker/features/series/data/models/tmdb_season.dart';

void main() {
  // Black Clover (TMDB 73223) al 2026-10-03: la seconda stagione è appena
  // confluita come Stagione 2, ma Yuna conosce solo la serie del 2017.
  const tmdbSeasons = [
    TmdbSeason(seasonNumber: 1, episodeCount: 170, airDate: '2017-10-03'),
    TmdbSeason(seasonNumber: 2, episodeCount: 2, airDate: '2026-10-03'),
  ];
  const original = AniListMedia(
    id: 97940,
    status: 'FINISHED',
    format: 'TV',
    episodes: 170,
    season: 'FALL',
    seasonYear: 2017,
    streamingEpisodes: [],
  );
  const secondSeason = AniListMedia(
    id: 195604,
    status: 'RELEASING',
    format: 'TV',
    season: 'FALL',
    seasonYear: 2026,
    streamingEpisodes: [],
  );

  AniListMedia media(int id,
          {String format = 'TV',
          int? episodes = 12,
          int year = 2026,
          String season = 'WINTER'}) =>
      AniListMedia(
        id: id,
        status: 'FINISHED',
        format: format,
        episodes: episodes,
        season: season,
        seasonYear: year,
        streamingEpisodes: const [],
      );

  test('preferisce TV e TV_SHORT escludendo ONA, film ed extra correlati', () {
    final seasons = AnimeDataMerger.merge(
      tmdbSeasons: const [TmdbSeason(seasonNumber: 1, episodeCount: 24)],
      anilistMedia: [
        media(9, format: 'ONA'),
        media(8, format: 'MOVIE'),
        media(2, format: 'TV_SHORT', season: 'SPRING'),
        media(1)
      ],
    );
    expect(seasons.map((s) => s.anilistId), [1, 2]);
    expect(seasons.map((s) => s.tmdbSeasonNumber), [1, 1]);
    expect(seasons.map((s) => s.episodeCount), [12, 12]);
  });

  test('ONA è fallback valido solo se nessuna voce TV è disponibile', () {
    final seasons = AnimeDataMerger.merge(
      tmdbSeasons: const [TmdbSeason(seasonNumber: 1, episodeCount: 12)],
      anilistMedia: [media(3, format: 'SPECIAL'), media(2, format: 'ONA')],
    );
    expect(seasons.single.anilistId, 2);
    expect(seasons.single.episodeCount, 12);
    expect(
        AnimeDataMerger.merge(
          tmdbSeasons: tmdbSeasons,
          anilistMedia: [media(3, format: 'MOVIE')],
        ),
        isEmpty);
  });

  test('più cour nella stessa stagione mantengono ordine e numerazione', () {
    final seasons = AnimeDataMerger.merge(
      tmdbSeasons: const [
        TmdbSeason(seasonNumber: 1, episodeCount: 36),
        TmdbSeason(seasonNumber: 2, episodeCount: 12),
      ],
      anilistMedia: [
        media(4, year: 2027),
        media(3, season: 'FALL'),
        media(2, season: 'SPRING'),
        media(1)
      ],
    );
    expect(seasons.map((s) => s.seasonNumber), [1, 2, 3, 4]);
    expect(seasons.map((s) => s.anilistId), [1, 2, 3, 4]);
    expect(seasons.map((s) => s.tmdbSeasonNumber), [1, 1, 1, 2]);
    expect(seasons.fold<int>(0, (total, s) => total + s.episodeCount), 48);
  });

  test('un cour più lungo si ripartisce sulle stagioni TMDB', () {
    final seasons = AnimeDataMerger.merge(
      tmdbSeasons: const [
        TmdbSeason(seasonNumber: 1, episodeCount: 12),
        TmdbSeason(seasonNumber: 2, episodeCount: 12)
      ],
      anilistMedia: [media(1, episodes: 24)],
    );
    expect(seasons.map((s) => s.anilistId), [1, 1]);
    expect(seasons.map((s) => s.episodeCount), [12, 12]);
    expect(seasons.map((s) => s.tmdbSeasonNumber), [1, 2]);
  });

  test('conteggio AniList sconosciuto resta zero e non usa il totale TMDB', () {
    final seasons = AnimeDataMerger.merge(
      tmdbSeasons: const [TmdbSeason(seasonNumber: 1, episodeCount: 5)],
      anilistMedia: [media(1, episodes: null)],
    );
    expect(seasons.single.episodeCount, 0);
    expect(seasons.single.anilistId, 1);
  });

  group('TTL normalizzata', () {
    NormalizedAnimeSeason season(String status, {DateTime? nextAt}) =>
        NormalizedAnimeSeason(
            seasonNumber: 1,
            tmdbSeasonNumber: 1,
            anilistId: 1,
            episodeCount: 12,
            status: status,
            nextAiringEpisode: nextAt == null
                ? null
                : AniListNextAiring(
                    episode: 7,
                    airingAt: nextAt.millisecondsSinceEpoch ~/ 1000,
                    timeUntilAiring: 0),
            streamingEpisodes: const []);

    test('contenuti stabili, pausa e annuncio hanno TTL distinte', () {
      expect(season('FINISHED').cacheTtl, const Duration(days: 30));
      expect(season('CANCELLED').cacheTtl, const Duration(days: 30));
      expect(season('HIATUS').cacheTtl, const Duration(days: 14));
      expect(season('NOT_YET_RELEASED').cacheTtl, const Duration(days: 7));
      expect(season('RELEASING').cacheTtl, const Duration(hours: 6));
      expect(season('RELEASING', nextAt: DateTime(2000)).cacheTtl,
          const Duration(hours: 6));
    });

    test('cour in onda scade alla prossima uscita, non sei ore dopo', () {
      final next = DateTime.now().add(const Duration(days: 2));
      final cour = season('RELEASING', nextAt: next);
      final before = DateTime.now();
      final ttl = cour.cacheTtl;
      final after = DateTime.now();
      final airing = cour.nextAiringEpisode!.airingDateTime;
      expect(
          ttl.inMicroseconds,
          inInclusiveRange(
            airing.difference(after).inMicroseconds,
            airing.difference(before).inMicroseconds,
          ));
    });
  });

  test('stagione TMDB senza voce AniList diventa un segnaposto', () {
    final seasons = AnimeDataMerger.merge(
      tmdbSeasons: tmdbSeasons,
      anilistMedia: [original],
    );
    expect(seasons.map((s) => s.anilistId), [97940, -1]);
    expect(seasons[1].tmdbSeasonNumber, 2);
  });

  test('con la voce trovata per titolo il cour viene agganciato', () {
    final seasons = AnimeDataMerger.merge(
      tmdbSeasons: tmdbSeasons,
      anilistMedia: [original, secondSeason],
    );
    expect(seasons.map((s) => s.anilistId), [97940, 195604]);
    // La numerazione dei cour (su cui sono salvati gli episodi visti) non
    // cambia: il cour 2 resta legato alla Stagione 2 di TMDB.
    expect(seasons.map((s) => s.seasonNumber), [1, 2]);
    expect(seasons[1].tmdbSeasonNumber, 2);
    expect(seasons[1].status, 'RELEASING');
  });
}
