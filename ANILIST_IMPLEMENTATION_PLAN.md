# Piano: Integrazione AniList + Yuna per il Supporto Anime

## Contesto

La vecchia app React Native aveva un sistema sofisticato per il tracciamento delle serie anime,
usando **Yuna.moe** per mappare gli ID TMDB → AniList, e **AniList GraphQL** per ottenere
dati precisi su episodi, stagioni e orari di messa in onda. Questo documento pianifica la
stessa implementazione per la nuova app Flutter.

### Obiettivi dell'integrazione AniList

Da AniList vogliamo ottenere **esclusivamente**:
1. **Suddivisione corretta delle stagioni** — AniList conosce i confini reali delle stagioni (es. 3 cour da 24 ep che TMDB raggruppa in un unico S1 da 72)
2. **Titoli reali degli episodi** — TMDB a volte mette placeholder ("Episodio 4"); AniList via Crunchyroll ha i titoli originali
3. **Orario di uscita preciso** — per programmare le notifiche al secondo giusto invece di mezzanotte o 13:00

Come bonus utile, AniList fornisce anche:
- **Titolo romaji/inglese** della stagione (spesso diverso/migliore di TMDB per gli anime)
- **Score community** (0-100), referenza più affidabile di TMDB per gli anime
- Questi dati non richiedono chiamate extra: vengono dalla stessa query

---

## Panoramica del Flusso Target

```
Utente apre dettaglio serie
    ↓
TmdbShowDetail.isAnime? (genre Animation + paese asiatico)
    ↓ sì
Yuna.moe: TMDB ID → [ AniList ID, ... ]  (cache 7gg)
    ↓
AniList GraphQL: fetch per ogni ID        (cache TTL dinamico)
    ↓
AnimeDataMerger: filtra TV/TV_SHORT, ordina cronologicamente, assegna stagioni
    ↓
TmdbService.getAnimeEpisodesBySeason(): raccoglie ep TMDB, redistribuisce per stagione AniList
    ↓
Enrichment titoli: placeholder TMDB → titolo AniList (se disponibile)
    ↓
Inject airingAt nell'episodio in uscita → notifiche precise
```

---

## Fase 1 — Rilevamento Anime

### 1.1 Logica di rilevamento

Aggiungere in `TmdbShowDetail` un getter `isAnime`:

```dart
bool get isAnime {
  final isAnimation = genres.any((g) => g.id == 16 || g.name == 'Animation');
  final asianCountries = {'JP', 'KR', 'CN', 'TW', 'HK'};
  final isAsian = originCountries.any((c) => asianCountries.contains(c));
  return isAnimation && isAsian;
}
```

Questo esclude correttamente serie animate occidentali come Arcane, Invincible, Avatar.

### 1.2 Modifiche modello `TmdbShowDetail`

Aggiungere campi mancanti che attualmente non vengono parsati dalla risposta TMDB:
- `originCountries: List<String>` (campo `origin_country` dalla risposta)
- `genres: List<TmdbGenre>` (con `id` e `name`)
- `animeSeasonsData: List<NormalizedAnimeSeason>?` (null se non e' anime)

### 1.3 File impattati

- `lib/features/series/data/models/tmdb_show_detail.dart`
- `lib/features/series/data/tmdb_service.dart` (verificare che i campi vengano parsati)

---

## Fase 2 — Yuna.moe: Mapping TMDB → AniList

### 2.1 Servizio Yuna

Creare `lib/features/series/data/yuna_service.dart`:

**Endpoint:** `GET https://relations.yuna.moe/api/v2/themoviedb/?id={tmdbId}`

**Risposta:** array di oggetti `{ anilist: int, ... }` (uno per stagione su AniList)

**Logica:**
- Ritorna `List<int>` di AniList IDs (spesso uno solo, a volte piu' per anime multi-cour)
- Ritorna lista vuota se la serie non e' presente (404 o array vuoto)
- Cache locale SQLite: 7 giorni (i mapping cambiano raramente)

### 2.2 Cache mapping in SQLite

Tabella Drift `YunaCache`:
```
tmdbId      INTEGER PRIMARY KEY
anilistIds  TEXT (JSON-encoded list<int>)
cachedAt    DATETIME
```

### 2.3 Fallback se Yuna non trova il mapping

Tentare ricerca per titolo direttamente su AniList con `ANIME_SEARCH_QUERY` (vedi Fase 3.2).
Se non trovato → la serie resta TMDB-only (nessun errore visibile all'utente).

---

## Fase 3 — AniList GraphQL API

### 3.1 Servizio AniList

Creare `lib/features/series/data/anilist_service.dart`:

**Endpoint:** `POST https://graphql.anilist.co` (no autenticazione richiesta)

**Query principale (`ANIME_DETAILS_QUERY`)** — per ogni AniList ID:
```graphql
query($id: Int) {
  Media(id: $id, type: ANIME) {
    id
    title { romaji english }
    status       # RELEASING | FINISHED | HIATUS | NOT_YET_RELEASED | CANCELLED
    format       # TV | TV_SHORT | OVA | ONA | MOVIE | SPECIAL
    episodes     # numero episodi totali della stagione (autoritativo)
    season       # WINTER | SPRING | SUMMER | FALL
    seasonYear
    averageScore # 0-100, score community AniList
    nextAiringEpisode { episode airingAt timeUntilAiring }
    streamingEpisodes { title thumbnail }
  }
}
```

**Fetch batch:** per ogni TMDB ID con mapping Yuna, fare una richiesta per ogni AniList ID
con parallelismo limitato a 3 (vedi rate limiting).

### 3.2 Query di ricerca fallback (`ANIME_SEARCH_QUERY`)

Usata quando Yuna non trova il mapping per TMDB ID:
```graphql
query($search: String) {
  Media(search: $search, type: ANIME, format_in: [TV, TV_SHORT]) {
    id
    title { romaji english }
    status
    format
    episodes
    season
    seasonYear
    averageScore
    nextAiringEpisode { episode airingAt timeUntilAiring }
    streamingEpisodes { title thumbnail }
  }
}
```

Se la ricerca restituisce un risultato con titolo sufficientemente simile → usa quell'ID.
Se non trovato → fallback TMDB-only.

### 3.3 Rate Limiting

Creare `lib/features/series/data/anilist_queue.dart`:
- **Token bucket:** 12 token / 10 secondi (~36 req/min effettive, ben sotto il limite AniList di 90/min)
- **Max concurrent:** 3 richieste in-flight
- Retry automatico su 429 con `Retry-After` header (max 2 retry)

---

## Fase 4 — Modelli Dati Anime

### 4.1 Nuovo modello `AniListMedia`

Creare `lib/features/series/data/models/anilist_media.dart`:

```dart
class AniListMedia {
  final int id;
  final String? titleRomaji;
  final String? titleEnglish;
  final String status;        // RELEASING, FINISHED, HIATUS, NOT_YET_RELEASED, CANCELLED
  final String format;        // TV, TV_SHORT, OVA, ...
  final int? episodes;        // null se in corso e ancora sconosciuto
  final String? season;       // WINTER, SPRING, SUMMER, FALL
  final int? seasonYear;
  final int? averageScore;    // 0-100
  final AniListNextAiring? nextAiringEpisode;
  final List<AniListStreamingEpisode> streamingEpisodes;
}

class AniListNextAiring {
  final int episode;           // numero episodio assoluto nell'anime
  final int airingAt;          // Unix timestamp in secondi
  final int timeUntilAiring;   // secondi rimanenti
}

class AniListStreamingEpisode {
  final String? title;         // formato "Episode N - Titolo Reale" o "EN - Titolo"
  final String? thumbnail;
}
```

### 4.2 Nuovo modello `NormalizedAnimeSeason`

Rappresenta una stagione dopo il merge TMDB + AniList:

```dart
class NormalizedAnimeSeason {
  final int seasonNumber;      // 1-based dopo filtro (indice logico AniList)
  final int tmdbSeasonNumber;  // numero stagione TMDB originale (per fetch episodi)
  final int anilistId;
  final int episodeCount;      // da AniList (autoritativo sul conteggio reale)
  final String status;         // RELEASING, FINISHED, HIATUS, NOT_YET_RELEASED, CANCELLED
  final String? season;        // WINTER, SPRING, SUMMER, FALL
  final int? seasonYear;
  final String? titleRomaji;   // titolo romaji da AniList (es. "Shingeki no Kyojin")
  final String? titleEnglish;  // titolo inglese da AniList
  final int? averageScore;     // score AniList 0-100
  final AniListNextAiring? nextAiringEpisode;
  final List<AniListStreamingEpisode> streamingEpisodes;
}
```

### 4.3 Aggiornamento `TmdbEpisode`

Aggiungere campi anime:
```dart
final int? absoluteEpisodeNumber; // numero episodio nel pool flat pre-redistribuzione
final DateTime? airingAt;          // timestamp preciso da AniList (solo prossimo ep)
```

---

## Fase 5 — Merge e Normalizzazione Stagioni

### 5.1 Servizio `AnimeDataMerger`

Creare `lib/features/series/data/anime_data_merger.dart`:

**Input:** `TmdbShowDetail` + `List<AniListMedia>` (dati grezzi da AniList)

**Output:** `List<NormalizedAnimeSeason>`

**Algoritmo:**
1. **Filtra** per formato principale: tieni solo `TV` e `TV_SHORT` (scarta OVA, Movie, Special, ONA)
2. **Ordina** deterministicamente per `(seasonYear ASC, SEASON_ORDER ASC, anilistId ASC)`
   - `SEASON_ORDER`: WINTER=0, SPRING=1, SUMMER=2, FALL=3
   - Tie-break sull'ID AniList (piu' basso = piu' vecchio)
3. **Assegna** `seasonNumber` = indice 1-based dopo filtro
4. **Assegna** `tmdbSeasonNumber` = posizione corrispondente nell'array stagioni TMDB
   (mapping posizionale: prima stagione AniList → prima stagione TMDB non speciale, ecc.)
5. **Costruisci** oggetti `NormalizedAnimeSeason`

**Edge cases:**
- AniList ha piu' stagioni di TMDB → usa solo le prime N (N = `numberOfSeasons` TMDB)
- AniList ha meno stagioni di TMDB → usa solo quelle AniList trovate
- Nessun AniList ID trovato → fallback a dati TMDB puri (serie rimane non-anime)

---

## Fase 6 — Redistribuzione Episodi per Stagione

### 6.1 Il problema

TMDB puo' raggruppare gli episodi in modo diverso da AniList:
- **Caso A:** TMDB ha tutto in S1 (es. 72 ep), AniList ha 3 stagioni da 24 ciascuna
- **Caso B:** TMDB ha S1=24, S2=24, S3=24 e AniList coincide (caso fortunato)
- **Caso C:** TMDB ha S1=13, S2=11 ma AniList li conta come 24 ep di stagione unica

### 6.2 Algoritmo di redistribuzione

In `TmdbService.getAnimeEpisodesBySeason()`:

```
1. Calcola totalExpected = sum(animeSeason.episodeCount per tutte le stagioni)
2. Fetch TMDB S1 (usando tmdbSeasonNumber della prima stagione AniList)
3. Se S1.length >= totalExpected:
   → pool = S1 (tutti gli ep sono gia' in S1 TMDB)
Altrimenti:
   → itera stagioni TMDB successive finche' pool.length >= totalExpected
   → costruisci pool flat concatenando gli ep in ordine

4. Redistribuisci il pool per stagione AniList:
   offset = 0
   Per ogni animeSeason in normalizedSeasons:
     slice = pool[offset ... offset + animeSeason.episodeCount]
     Per ogni ep in slice:
       ep.episodeNumber = (indice 1-based nella stagione AniList)
       ep.absoluteEpisodeNumber = offset + indice + 1
     offset += animeSeason.episodeCount

5. Inietta airingAt nell'episodio che corrisponde a nextAiringEpisode.episode

6. Return: Map<int, List<TmdbEpisode>> { seasonNumber → episodes }
```

**Fallback redistribuzione:** se il pool TMDB ha meno episodi di `totalExpected` (dati TMDB incompleti),
usa la struttura stagioni TMDB originale senza redistribuzione e logga un warning.

### 6.3 Enrichment titoli episodio

Logica a tre livelli per ogni episodio dopo la redistribuzione:

```
STEP 1: Il titolo TMDB e' un placeholder?
  Regex: /^Episod(?:io|e)\s+\d+$/i
  Esempi placeholder: "Episodio 4", "Episode 12", "Episodio 1"
  Esempi NON placeholder: "La battaglia finale", "One Last Kiss", "Chapter 4: Dawn"

STEP 2: Se NON e' placeholder → mantieni il titolo TMDB (e' gia' corretto)

STEP 3: Se e' placeholder → cerca in streamingEpisodes di questa stagione AniList:
  - Costruisci map { absoluteEpisodeNumber → realTitle } da streamingEpisodes
  - Parse formato "Episode N - Real Title" → episodeNumber=N, realTitle="Real Title"
  - Parse formato "EN - Title" → episodeNumber=N
  - Se realTitle trovato e non vuoto → usa realTitle
  - Se NON trovato (AniList non ce l'ha) → lascia il placeholder TMDB originale
```

**Nota:** Il numero dell'episodio estratto dal titolo AniList si riferisce al numero assoluto
nell'anime, non a quello per-stagione. Usare `absoluteEpisodeNumber` per il lookup nella map.

---

## Fase 7 — Aggiornamento Database SQLite

### 7.1 Nuove tabelle Drift (schema v9)

**`YunaCache`** — mapping TMDB → AniList IDs:
```dart
class YunaCache extends Table {
  IntColumn get tmdbId => integer()();
  TextColumn get anilistIdsJson => text()();  // JSON array di int
  DateTimeColumn get cachedAt => dateTime()();

  @override Set<Column> get primaryKey => {tmdbId};
}
```

**`AnimeSeasonCache`** — dati AniList per stagione, un record per (show, stagione):
```dart
class AnimeSeasonCache extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get tmdbShowId => integer()();
  IntColumn get seasonNumber => integer()();    // stagione logica AniList (1-based)
  IntColumn get anilistId => integer()();
  IntColumn get episodeCount => integer()();
  TextColumn get status => text()();
  TextColumn get animeSeasonJson => text()();   // JSON completo NormalizedAnimeSeason
  DateTimeColumn get cachedAt => dateTime()();
  DateTimeColumn get validUntil => dateTime()();

  // Un solo record per (show, stagione)
  @override List<Set<Column>> get uniqueKeys => [{tmdbShowId, seasonNumber}];
}
```

### 7.2 Aggiornamento `TrackedShows`

```dart
BoolColumn get isAnime => boolean().withDefault(const Constant(false))();
```

### 7.3 Aggiornamento `CachedEpisodes`

```dart
IntColumn get absoluteEpisodeNumber => integer().nullable()();
DateTimeColumn get airingAt => dateTime().nullable()();
```

### 7.4 Migrazione schema v8 → v9

```dart
from8To9: (m, schema) async {
  await m.addColumn(schema.trackedShows, schema.trackedShows.isAnime);
  await m.addColumn(schema.cachedEpisodes, schema.cachedEpisodes.absoluteEpisodeNumber);
  await m.addColumn(schema.cachedEpisodes, schema.cachedEpisodes.airingAt);
  await m.createTable(schema.yunaCache);
  await m.createTable(schema.animeSeasonCache);
},
```

---

## Fase 8 — TTL Cache Dinamico per Anime

### 8.1 Logica TTL completa in `CacheDao`

```
Status AniList RELEASING + nextAiringEpisode.airingAt presente:
  → validUntil = DateTime.fromMillisecondsSinceEpoch(airingAt * 1000)
  (la cache scade esattamente quando l'episodio va in onda → refresh automatico)

Status AniList RELEASING senza airingAt (data sconosciuta):
  → validUntil = now + 6 ore

Status AniList HIATUS:
  → validUntil = now + 14 giorni

Status AniList NOT_YET_RELEASED:
  → validUntil = now + 7 giorni

Status AniList FINISHED o CANCELLED:
  → validUntil = now + 30 giorni

Yuna mapping cache:
  → validUntil = now + 7 giorni (i mapping cambiano raramente)
```

### 8.2 Stale-while-revalidate

Per evitare loading spinner su dati gia' visti: se la cache e' valida ma ha consumato
**piu' dell'80% del suo TTL**, servire il dato in cache immediatamente e avviare un refresh
in background. L'utente vede dati istantanei, aggiornati silenziosamente.

Implementare nel provider `animeDataProvider`:
```dart
if (cached != null && !cached.isExpired) {
  if (cached.isNearExpiry) {  // >80% TTL consumato
    unawaited(_refreshInBackground(tmdbId));
  }
  return cached.data;
}
```

---

## Fase 9 — Aggiornamento Provider Riverpod

### 9.1 Nuovo provider `animeDataProvider(tmdbId)`

In `lib/features/series/providers/series_providers.dart`:

```dart
@riverpod
Future<List<NormalizedAnimeSeason>?> animeData(
  AnimeDataRef ref,
  int tmdbId,
) async {
  // 1. Check AnimeSeasonCache in SQLite
  // 2. Cache hit valida → return (con stale-while-revalidate se vicino a scadenza)
  // 3. Cache miss/scaduta:
  //    a. YunaService.getAniListIds(tmdbId)
  //    b. Se vuota → ANIME_SEARCH_QUERY con titolo TMDB come fallback
  //    c. AniListService.fetchBatch(anilistIds, maxConcurrent: 3)
  //    d. AnimeDataMerger.merge(tmdbDetail, anilistMediaList)
  // 4. Salva in AnimeSeasonCache con TTL corretto
  // 5. Return List<NormalizedAnimeSeason>
}
```

### 9.2 Aggiornamento `showDetailProvider(tmdbId)`

```dart
if (showDetail.isAnime) {
  final animeSeasonsData = await ref.read(animeDataProvider(tmdbId).future);
  return showDetail.copyWith(animeSeasonsData: animeSeasonsData);
}
return showDetail;
```

### 9.3 Aggiornamento `seasonDetailProvider(showId, seasonNumber)`

```dart
// Se la serie e' anime:
// 1. Trova NormalizedAnimeSeason corrispondente (seasonNumber == n)
// 2. Usa animeSeason.tmdbSeasonNumber per sapere quali ep TMDB fetchare
// 3. Chiama TmdbService.getAnimeEpisodesBySeason() per redistribuzione e enrichment
// 4. Invece del getSeasonDetails() standard
```

### 9.4 Aggiornamento `upcomingEpisodesProvider`

Per serie anime con `nextAiringEpisode.airingAt`:
- **Priorita' 1:** timestamp AniList (preciso al secondo) → usa questo
- **Priorita' 2:** data TMDB (solo giorno) → assume **ore 09:00** come default
- Questo garantisce notifiche al momento preciso per gli anime, e notifiche ragionevoli per le serie normali

---

## Fase 10 — UI: Visualizzazione Dati Anime

### 10.1 `ShowDetailScreen` — badge anime

Aggiungere un piccolo badge "ANIME" nell'header per distinguere le serie anime.

### 10.2 `ShowDetailScreen` — info stagione anime

Per ogni stagione (tab/sezione) di un anime, mostrare:
- Stagione e anno AniList: "Fall 2023", "Winter 2024"
- Status: RELEASING, FINISHED, HIATUS (localizzare le stringhe in italiano)
- Titolo romaji da AniList, se diverso dal titolo TMDB (es. sotto il titolo principale)
- Score AniList (es. "87/100") accanto o sotto lo score TMDB

### 10.3 `EpisodeTile` — orario preciso per prossimo ep

Per l'episodio con `airingAt` valorizzato (solo il prossimo in assoluto):
- Mostrare orario preciso invece della sola data
- Esempio: "Lunedi 28 apr alle 17:30" invece di "28 Apr"

### 10.4 `NextEpisodeCard` / `UpcomingEpisodeCard`

Per anime in corso con `airingAt` disponibile:
- Countdown preciso: "Ep. 12 tra 2 giorni, 3 ore"
- Aggiornamento in tempo reale mentre la schermata e' aperta

---

## Fase 11 — Gestione Errori e Fallback

### 11.1 Fallback a TMDB-only

Se Yuna, la ricerca per titolo, o AniList falliscono:
- La serie viene trattata come serie TV normale (`isAnime = false` in locale)
- Nessun crash, nessun errore visibile all'utente
- Log dell'errore per debug

### 11.2 Fallback titoli episodio

Se AniList non ha `streamingEpisodes` per quella stagione:
- Mantieni i titoli TMDB cosi' come sono (anche i placeholder)
- Non bloccare il caricamento degli episodi

### 11.3 Fallback redistribuzione episodi

Se il pool TMDB ha meno episodi di `totalExpected` (dati TMDB incompleti):
- Usa la struttura stagioni TMDB originale senza redistribuzione
- Logga un warning con i conteggi attesi vs trovati

---

## Ordine di Implementazione Consigliato

```
1.  [Fase 1]  Aggiungere isAnime, originCountries, genres a TmdbShowDetail
2.  [Fase 4]  Creare modelli AniListMedia, AniListNextAiring, AniListStreamingEpisode, NormalizedAnimeSeason
3.  [Fase 2]  Implementare YunaService (HTTP puro, senza cache)
4.  [Fase 3]  Implementare AniListService (ANIME_DETAILS_QUERY + ANIME_SEARCH_QUERY)
5.  [Fase 3]  Implementare AniListQueue (token bucket + max concurrent)
6.  [Fase 5]  Implementare AnimeDataMerger
7.  [Fase 7]  Aggiornare schema DB a v9 (nuove tabelle + nuove colonne)
8.  [Fase 2]  Aggiungere cache SQLite a YunaService
9.  [Fase 6]  Implementare redistribuzione episodi + enrichment titoli
10. [Fase 8]  TTL dinamico + stale-while-revalidate in CacheDao
11. [Fase 9]  Aggiornare provider Riverpod (animeDataProvider, showDetail, seasonDetail, upcoming)
12. [Fase 10] Aggiornare UI
13. [Fase 11] Verifica fallback + testing manuale su anime noti (Jujutsu Kaisen, AOT, One Piece)
```

---

## File da Creare (Nuovi)

| File | Descrizione |
|------|-------------|
| `lib/features/series/data/yuna_service.dart` | Chiamate HTTP a Yuna.moe + cache SQLite |
| `lib/features/series/data/anilist_service.dart` | Chiamate GraphQL a AniList (details + search) |
| `lib/features/series/data/anilist_queue.dart` | Rate limiting token-bucket per AniList |
| `lib/features/series/data/anime_data_merger.dart` | Filtra, ordina, normalizza stagioni AniList |
| `lib/features/series/data/models/anilist_media.dart` | Modelli: AniListMedia, AniListNextAiring, AniListStreamingEpisode |
| `lib/features/series/data/models/normalized_anime_season.dart` | Stagione normalizzata post-merge |

---

## File da Modificare (Esistenti)

| File | Modifiche |
|------|-----------|
| `lib/features/series/data/models/tmdb_show_detail.dart` | `isAnime`, `originCountries`, `genres`, `animeSeasonsData` |
| `lib/features/series/data/models/tmdb_episode.dart` | `absoluteEpisodeNumber`, `airingAt` |
| `lib/features/series/data/tmdb_service.dart` | `getAnimeEpisodesBySeason()`, parsing `origin_country` e `genres` |
| `lib/core/database/app_database.dart` | Schema v9 + migrazione from8To9 |
| `lib/core/database/tables/tracked_shows.dart` | Colonna `isAnime` |
| `lib/core/database/tables/cached_episodes.dart` | Colonne `absoluteEpisodeNumber`, `airingAt` |
| `lib/core/database/daos/cache_dao.dart` | TTL dinamico anime + stale-while-revalidate |
| `lib/features/series/providers/series_providers.dart` | `animeDataProvider`, aggiornamenti showDetail/seasonDetail/upcoming |
| `lib/features/series/presentation/show_detail_screen.dart` | Badge anime, info stagione (romaji, score, status) |
| `lib/features/series/presentation/widgets/episode_tile.dart` | Orario preciso per prossimo ep anime |
| `lib/features/series/presentation/widgets/next_episode_card.dart` | Countdown da AniList airingAt |

---

## Rischi e Considerazioni

1. **Yuna.moe e' un servizio community** — potrebbe avere downtime. Il fallback per ricerca
   per titolo e poi TMDB-only e' essenziale.

2. **AniList rate limiting** — 90 req/min pubbliche. Il token bucket da 12/10s usa solo
   ~36 req/min: il triplo del margine di sicurezza.

3. **Mapping posizionale TMDB vs AniList non e' perfetto** — funziona per il 95% dei casi
   ma puo' fallire per show con archi non lineari o stagioni speciali intercalate.
   La redistribuzione con fallback gestisce questi edge case senza crash.

4. **Numerazione episodi anomala** — alcuni anime (es. FMA Brotherhood) hanno numerazione
   assoluta TMDB che differisce da quella per-stagione AniList. L'`absoluteEpisodeNumber`
   preserva il riferimento originale per il lookup nei `streamingEpisodes`.

5. **Migrazione v8→v9** — aggiunge solo colonne nullable e nuove tabelle: nessun rischio
   di perdita dati esistenti.

6. **Titoli AniList in inglese** — `streamingEpisodes` da Crunchyroll hanno titoli in
   inglese. E' accettabile: meglio un titolo vero in inglese che un placeholder in italiano.
