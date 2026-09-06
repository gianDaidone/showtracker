import '../../../core/database/app_database.dart';
import 'models/normalized_anime_season.dart';

/// Regole condivise per decidere **quale** episodio l'utente deve guardare e
/// **se quell'episodio è già andato in onda**.
///
/// Sono usate da due punti che devono per forza dare la stessa risposta:
///
/// * `visibleWatchingShowsProvider` — costruisce la lista "Da Vedere" e quindi
///   il numero mostrato nell'intestazione ("Da Vedere (n)");
/// * `NextEpisodeCard` — decide se disegnarsi o nascondersi.
///
/// Prima esistevano due copie divergenti della stessa logica: la lista contava
/// una serie che la card poi nascondeva, producendo intestazioni tipo
/// "Da Vedere (1)" senza nessuna card sotto. Qualsiasi modifica va fatta qui,
/// mai duplicata nei due chiamanti.

/// Prossimo episodio da guardare, dato l'insieme degli episodi visti.
///
/// [seasonCounts] è la mappa stagione→numero di episodi (dal DB locale o dal
/// detail TMDB): consente di rilevare l'overflow di stagione senza chiamate API.
/// [animeSeasonsData] serve agli anime per trovare cours successivi con
/// `episodeCount == 0` ma ancora in produzione.
(int season, int episode) computeNextToWatch(
  Map<int, Set<int>> watchedBySeason,
  Map<int, int> seasonCounts, {
  List<NormalizedAnimeSeason>? animeSeasonsData,
}) {
  if (watchedBySeason.isEmpty) return (1, 1);

  final lastSeason = watchedBySeason.keys.reduce((a, b) => a > b ? a : b);
  final lastEp = watchedBySeason[lastSeason]!.reduce((a, b) => a > b ? a : b);
  final nextEp = lastEp + 1;
  final countInSeason = seasonCounts[lastSeason];

  // Avanza alla stagione successiva solo se conosciamo il totale episodi della
  // stagione corrente (>0) e l'abbiamo superato. Per anime in onda AniList può
  // restituire episodes=null → episodeCount=0: in quel caso 0 significa
  // "totale ignoto", non "stagione vuota", quindi non saltiamo.
  if (countInSeason != null && countInSeason > 0 && nextEp > countInSeason) {
    final sortedSeasons = seasonCounts.keys.toList()..sort();
    int? nextAvailableSeason = sortedSeasons
        .where((s) => s > lastSeason && (seasonCounts[s] ?? 0) > 0)
        .firstOrNull;

    // Per gli anime: fallback su cours con episodeCount=0 ma ancora in
    // produzione (AniList non conosce ancora il totale episodi).
    if (nextAvailableSeason == null && animeSeasonsData != null) {
      nextAvailableSeason = sortedSeasons.where((s) {
        if (s <= lastSeason) return false;
        final animeSeason =
            animeSeasonsData.where((as_) => as_.seasonNumber == s).firstOrNull;
        if (animeSeason == null) return false;
        return animeSeason.status == 'RELEASING' ||
            animeSeason.status == 'NOT_YET_RELEASED';
      }).firstOrNull;
    }

    if (nextAvailableSeason != null) return (nextAvailableSeason, 1);
  }

  return (lastSeason, nextEp);
}

/// Verdetto di AniList sulla messa in onda di [episode] nella stagione
/// (cour) [season]: true = già uscito, false = non ancora, null = non lo sappiamo.
///
/// AniList è la fonte autorevole sul calendario degli anime e conosce i nuovi
/// episodi prima di TMDB, che può ritardare di un giorno nel pubblicarli.
bool? anilistHasAired(
  List<NormalizedAnimeSeason>? animeSeasonsData,
  int season,
  int episode,
) {
  final s = animeSeasonsData?.where((x) => x.seasonNumber == season).firstOrNull;
  if (s == null) return null;

  final next = s.nextAiringEpisode;
  if (next != null) {
    // `nextAiringEpisode.episode` è relativo al cour, come i nostri numeri.
    if (episode == next.episode) {
      return !next.airingDateTime.isAfter(DateTime.now());
    }
    if (episode < next.episode) return true;
    // Oltre il prossimo episodio in programma: se i dati in cache sono stantii
    // potrebbe essere uscito comunque, quindi ci asteniamo.
    return null;
  }

  // Nessuna prossima messa in onda: se il cour è finito, tutti i suoi episodi
  // sono usciti.
  if (s.status == 'FINISHED' || s.status == 'CANCELLED') {
    return s.episodeCount > 0 ? episode <= s.episodeCount : null;
  }
  return null;
}

/// Verdetto basato solo sui dati salvati in locale, usato quando né AniList né
/// TMDB sanno dirci nulla (offline, richiesta fallita, cour che TMDB non ha).
bool existsPerDatabase(
  TrackedShow show,
  Map<int, int> dbSeasonCounts,
  int season,
  int episode,
) {
  final count = dbSeasonCounts[season] ?? 0;
  if (count <= 0 || episode > count) return false;
  if (show.nextEpisodeSeason == season && show.nextEpisodeNumber == episode) {
    final airDate = show.nextEpisodeAirDate;
    return airDate != null && !airDate.isAfter(DateTime.now());
  }
  return true;
}

/// L'episodio [season]x[episode] è già uscito?
///
/// Consultiamo tutte le fonti disponibili nell'ordine di affidabilità e
/// accettiamo il primo verdetto certo: AniList (calendario anime), TMDB
/// ([airedPerTmdb], `null` quando non abbiamo l'episodio) e, come ultima
/// spiaggia, i soli dati locali.
bool resolveHasAired({
  required TrackedShow show,
  required Map<int, int> dbSeasonCounts,
  required int season,
  required int episode,
  List<NormalizedAnimeSeason>? animeSeasonsData,
  bool? airedPerTmdb,
}) {
  final airedPerAniList = anilistHasAired(animeSeasonsData, season, episode);
  if (airedPerAniList == true || airedPerTmdb == true) return true;
  if (airedPerAniList == false || airedPerTmdb == false) return false;
  return existsPerDatabase(show, dbSeasonCounts, season, episode);
}

/// Verdetto di TMDB ricavato dagli episodi in cache: true = già uscito,
/// false = non ancora, null = episodio assente dalla cache o senza data.
///
/// Replica la semantica di `TmdbEpisode.hasAired`, che è ciò che usa la card
/// quando gli episodi arrivano dal provider `seasonDetail` (di norma servito
/// dalla stessa cache).
bool? airedPerCachedEpisodes(List<CachedEpisode> cached, int episodeNumber) {
  final ep =
      cached.where((e) => e.episodeNumber == episodeNumber).firstOrNull;
  if (ep == null) return null;
  final at = ep.airingAt ?? DateTime.tryParse(ep.airDate ?? '');
  if (at == null) return null;
  return at.isBefore(DateTime.now());
}

/// Esiste un cour successivo a [lastWatchedSeason] ancora in produzione?
/// Usato per non dichiarare "completato" un anime in attesa del cour seguente.
bool hasLaterUpcomingAnimeSeason(
  List<NormalizedAnimeSeason> animeSeasonsData,
  int lastWatchedSeason,
) =>
    animeSeasonsData.any((as_) =>
        as_.seasonNumber > lastWatchedSeason &&
        (as_.status == 'RELEASING' || as_.status == 'NOT_YET_RELEASED'));
