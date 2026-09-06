import 'package:flutter_test/flutter_test.dart';
import 'package:showtracker/core/database/app_database.dart';
import 'package:showtracker/features/series/data/models/anilist_media.dart';
import 'package:showtracker/features/series/data/models/normalized_anime_season.dart';
import 'package:showtracker/features/series/data/watch_next_rules.dart';

TrackedShow _show({
  int? nextEpisodeSeason,
  int? nextEpisodeNumber,
  DateTime? nextEpisodeAirDate,
  bool isAnime = false,
}) =>
    TrackedShow(
      id: 1,
      tmdbId: 100,
      title: 'Serie',
      status: MediaStatus.watching,
      isAnime: isAnime,
      addedAt: DateTime(2026, 1, 1),
      totalEpisodes: 10,
      tmdbStatus: 'Returning Series',
      nextEpisodeSeason: nextEpisodeSeason,
      nextEpisodeNumber: nextEpisodeNumber,
      nextEpisodeAirDate: nextEpisodeAirDate,
    );

CachedEpisode _cached(int season, int episode, String? airDate) => CachedEpisode(
      id: season * 1000 + episode,
      tmdbShowId: 100,
      seasonNumber: season,
      episodeNumber: episode,
      name: 'Ep $episode',
      airDate: airDate,
      cachedAt: DateTime.now(),
    );

void main() {
  final now = DateTime.now();
  final yesterday = now.subtract(const Duration(days: 1));
  final nextWeek = now.add(const Duration(days: 7));
  String d(DateTime t) =>
      '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';

  group('computeNextToWatch', () {
    test('parte dal primo episodio se non ha visto nulla', () {
      expect(computeNextToWatch({}, {1: 10}), (1, 1));
    });

    test('avanza nella stessa stagione', () {
      expect(computeNextToWatch({1: {1, 2, 3}}, {1: 10}), (1, 4));
    });

    test('passa alla stagione successiva a fine stagione', () {
      expect(
        computeNextToWatch({1: {1, 2}}, {1: 2, 2: 12}),
        (2, 1),
      );
    });

    test('non salta la stagione quando il totale è ignoto (anime in onda)', () {
      // episodeCount 0 = "non lo sappiamo", non "stagione vuota".
      expect(computeNextToWatch({1: {1, 2}}, {1: 0}), (1, 3));
    });
  });

  group('resolveHasAired', () {
    test('TMDB dice che il prossimo episodio non è ancora uscito', () {
      // Il caso del bug: il puntatore in DB è rimasto sull'episodio appena
      // visto (5), quindi da solo il DB direbbe "esiste, mostralo". La data di
      // messa in onda dell'episodio 6 chiude la questione.
      final show = _show(
        nextEpisodeSeason: 1,
        nextEpisodeNumber: 5,
        nextEpisodeAirDate: yesterday,
      );
      final cached = [_cached(1, 6, d(nextWeek))];

      expect(
        resolveHasAired(
          show: show,
          dbSeasonCounts: {1: 10},
          season: 1,
          episode: 6,
          airedPerTmdb: airedPerCachedEpisodes(cached, 6),
        ),
        isFalse,
      );
    });

    test('episodio già uscito secondo TMDB', () {
      expect(
        resolveHasAired(
          show: _show(),
          dbSeasonCounts: {1: 10},
          season: 1,
          episode: 6,
          airedPerTmdb: airedPerCachedEpisodes([_cached(1, 6, d(yesterday))], 6),
        ),
        isTrue,
      );
    });

    test('AniList vince su TMDB quando TMDB è in ritardo', () {
      final anime = [
        NormalizedAnimeSeason(
          seasonNumber: 1,
          tmdbSeasonNumber: 1,
          anilistId: 1,
          episodeCount: 12,
          status: 'RELEASING',
          nextAiringEpisode: AniListNextAiring(
            episode: 7,
            airingAt: nextWeek.millisecondsSinceEpoch ~/ 1000,
            timeUntilAiring: 0,
          ),
          streamingEpisodes: const [],
        ),
      ];

      // AniList sa che il 6 è uscito, anche se TMDB non lo ha ancora pubblicato.
      expect(
        resolveHasAired(
          show: _show(isAnime: true),
          dbSeasonCounts: {1: 12},
          season: 1,
          episode: 6,
          animeSeasonsData: anime,
          airedPerTmdb: null,
        ),
        isTrue,
      );

      // E che il 7 no.
      expect(
        resolveHasAired(
          show: _show(isAnime: true),
          dbSeasonCounts: {1: 12},
          season: 1,
          episode: 7,
          animeSeasonsData: anime,
          airedPerTmdb: null,
        ),
        isFalse,
      );
    });

    test('senza dati remoti si affida al puntatore salvato in locale', () {
      // Nessuna cache episodi: l'episodio successivo coincide col puntatore in
      // DB, la cui data è nel futuro → non ancora uscito.
      expect(
        resolveHasAired(
          show: _show(
            nextEpisodeSeason: 1,
            nextEpisodeNumber: 6,
            nextEpisodeAirDate: nextWeek,
          ),
          dbSeasonCounts: {1: 10},
          season: 1,
          episode: 6,
        ),
        isFalse,
      );

      // Oltre il numero di episodi noti la stagione non ha altro da offrire.
      expect(
        resolveHasAired(
          show: _show(),
          dbSeasonCounts: {1: 10},
          season: 1,
          episode: 11,
        ),
        isFalse,
      );
    });
  });

  test('hasLaterUpcomingAnimeSeason', () {
    final seasons = [
      const NormalizedAnimeSeason(
        seasonNumber: 1,
        tmdbSeasonNumber: 1,
        anilistId: 1,
        episodeCount: 12,
        status: 'FINISHED',
        streamingEpisodes: [],
      ),
      const NormalizedAnimeSeason(
        seasonNumber: 2,
        tmdbSeasonNumber: 1,
        anilistId: 2,
        episodeCount: 0,
        status: 'NOT_YET_RELEASED',
        streamingEpisodes: [],
      ),
    ];
    expect(hasLaterUpcomingAnimeSeason(seasons, 1), isTrue);
    expect(hasLaterUpcomingAnimeSeason(seasons, 2), isFalse);
  });
}
