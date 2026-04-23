# Piano: Integrazione AniList + Yuna per il Supporto Anime

## Contesto

La vecchia app React Native aveva un sistema sofisticato per il tracciamento delle serie anime,
usando **Yuna.moe** per mappare gli ID TMDB → AniList, e **AniList GraphQL** per ottenere
dati precisi su episodi, stagioni e orari di messa in onda. Questo documento pianifica la
stessa implementazione per la nuova app Flutter.

---

## Panoramica del Flusso Target

```
Utente cerca serie anime
    ↓
TMDB: isAnimation + originCountry asiatico → è un anime
    ↓
Yuna.moe: TMDB ID → [ AniList ID, ... ]
    ↓
AniList GraphQL: fetch dettagli per ogni ID
    ↓
Merge + normalizzazione stagioni
    ↓
Redistribuzione episodi TMDB per stagione AniList
    ↓
Enrich titoli episodi da Crunchyroll (via AniList)
    ↓
TTL dinamico cache basato su stato airing
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

### 1.2 Modifiche modello `TmdbShowDetail`

Aggiungere campi mancanti che attualmente non vengono parsati dalla risposta TMDB:
- `originCountries: List<String>` (campo `origin_country` dalla risposta)
- `genres: List<TmdbGenre>` (con `id` e `name`)

### 1.3 Impatto

- **File:** `lib/features/series/data/models/tmdb_show_detail.dart`
- **File:** `lib/features/series/data/tmdb_service.dart` (verificare che i campi vengano parsati)

---

## Fase 2 — Yuna.moe: Mapping TMDB → AniList

### 2.1 Servizio Yuna

Creare `lib/features/series/data/yuna_service.dart`:

**Endpoint:** `GET https://relations.yuna.moe/api/v2/themoviedb/?id={tmdbId}`

**Risposta:** array di oggetti `{ anilist: int, ... }` (uno per stagione su AniList)

**Logica:**
- Ritorna `List<int>` di AniList IDs (uno per stagione/arco)
- Ritorna lista vuota se la serie non è un anime (404 o array vuoto)
- Cache locale SQLite: 7 giorni (i mapping cambiano raramente)

### 2.2 Cache mapping in SQLite

Aggiungere tabella Drift `YunaCache`:
```
tmdbId   INTEGER PRIMARY KEY
anilistIds  TEXT (JSON-encoded list<int>)
cachedAt DATETIME
```

### 2.3 Fallback

Se Yuna non trova mapping → tentare ricerca per titolo su AniList
(`ANIME_SEARCH_QUERY` con il titolo TMDB)

---

## Fase 3 — AniList GraphQL API

### 3.1 Servizio AniList

Creare `lib/features/series/data/anilist_service.dart`:

**Endpoint:** `POST https://graphql.anilist.co`

**Query principale (`ANIME_DETAILS_QUERY`)** — per ogni AniList ID:
```graphql
query($id: Int) {
  Media(id: $id, type: ANIME) {
    id
    title { romaji english }
    status          # RELEASING | FINISHED | HIATUS | ...
    format          # TV | TV_SHORT | OVA | ONA | MOVIE | SPECIAL
    episodes
    duration
    season          # WINTER | SPRING | SUMMER | FALL
    seasonYear
    nextAiringEpisode { episode airingAt timeUntilAiring }
    streamingEpisodes { title thumbnail }
    relations { edges { relationType node { id type } } }
  }
}
```

**Fetch batch:** per ogni TMDB ID con mapping Yuna, fare una richiesta per ogni AniList ID
(parallelismo limitato a 3, come nella vecchia app)

### 3.2 Rate Limiting

Creare `lib/features/series/data/anilist_queue.dart`:
- **Token bucket:** 12 token / 10 secondi
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
  final String status;       // RELEASING, FINISHED, HIATUS, ...
  final String format;       // TV, TV_SHORT, OVA, ...
  final int? episodes;
  final String? season;      // WINTER, SPRING, SUMMER, FALL
  final int? seasonYear;
  final AniListNextAiring? nextAiringEpisode;
  final List<AniListStreamingEpisode> streamingEpisodes;
}

class AniListNextAiring {
  final int episode;
  final int airingAt;        // Unix timestamp (secondi)
  final int timeUntilAiring; // Secondi
}

class AniListStreamingEpisode {
  final String? title;       // Format: "Episode N - Title"
  final String? thumbnail;
}
```

### 4.2 Nuovo modello `NormalizedAnimeSeason`

Rappresenta una stagione dopo merge TMDB + AniList:

```dart
class NormalizedAnimeSeason {
  final int seasonNumber;       // 1-based dopo filtro (indice AniList)
  final int tmdbSeasonNumber;   // Posizione originale TMDB (per fetch episodi)
  final int anilistId;
  final int episodeCount;       // Da AniList (autoritativo)
  final String status;          // RELEASING, FINISHED, ...
  final String? season;         // WINTER/SPRING/SUMMER/FALL
  final int? seasonYear;
  final AniListNextAiring? nextAiringEpisode;
  final List<AniListStreamingEpisode> streamingEpisodes;
}
```

### 4.3 Aggiornamento `TmdbShowDetail`

Aggiungere campo opzionale:
```dart
final List<NormalizedAnimeSeason>? animeSeasonsData; // null se non è anime
```

### 4.4 Aggiornamento `TmdbEpisode`

Aggiungere campi anime:
```dart
final int? absoluteEpisodeNumber; // Numero episodio assoluto (pre-redistribuzione)
final DateTime? airingAt;         // Timestamp preciso da AniList (solo prossimo ep)
```

---

## Fase 5 — Merge e Normalizzazione Stagioni

### 5.1 Servizio `AnimeDataMerger`

Creare `lib/features/series/data/anime_data_merger.dart`:

**Input:** `TmdbShowDetail` (dati TMDB) + `List<AniListMedia>` (dati AniList grezzi)

**Output:** `List<NormalizedAnimeSeason>` normalizzate

**Algoritmo:**
1. **Filtra** per format TV: tieni solo `TV` e `TV_SHORT` (scarta OVA, Movie, Special, ONA)
2. **Ordina** deterministicamente per `(seasonYear ASC, SEASON_ORDER ASC, anilistId ASC)`
   - `SEASON_ORDER`: WINTER=0, SPRING=1, SUMMER=2, FALL=3
3. **Assegna** `seasonNumber` = indice 1-based dopo filtro
4. **Assegna** `tmdbSeasonNumber` = posizione corrispondente nel array stagioni TMDB
   (mapping posizionale: prima stagione AniList → prima stagione TMDB, ecc.)
5. **Costruisci** oggetti `NormalizedAnimeSeason` da dati AniList filtrati/ordinati

**Edge cases:**
- AniList ha più stagioni di TMDB → usa solo le prime N (N = `numberOfSeasons` TMDB)
- AniList ha meno stagioni di TMDB → usa solo quelle AniList trovate
- AniList ID non trovati → fallback a dati TMDB puri (serie rimane `type: tv`)

---

## Fase 6 — Redistribuzione Episodi per Stagione

### 6.1 Problema

TMDB può raggruppare gli episodi in modo diverso da AniList:
- Caso A: TMDB ha tutto in S1 (es. 72 ep), AniList ha 3 stagioni da 24 ciascuna
- Caso B: TMDB ha S1=24, S2=23, S3=25 e AniList coincide (caso fortunato)

### 6.2 Algoritmo di redistribuzione

In `TmdbService.getAnimeEpisodesBySeason()`:

```
1. Calcola totalExpected = sum(animeSeason.episodeCount for all seasons)
2. Fetch TMDB S1 episodes
3. Se S1.length >= totalExpected:
   → fetchPerSeason = false (tutti episodi sono in S1 TMDB)
   → usa S1 come pool flat
Altrimenti:
   → fetchPerSeason = true
   → itera stagioni TMDB finché pool.length >= totalExpected
   → costruisci pool flat con tutti gli episodi

4. Redistribuisci pool per stagione AniList:
   offset = 0
   Per ogni animeSeason in normalizedSeasons:
     animeEps = pool[offset ... offset + animeSeason.episodeCount]
     Per ogni ep in animeEps:
       ep.episodeNumber = (1-based nell'anime season)
       ep.absoluteEpisodeNumber = offset + index + 1
     offset += animeSeason.episodeCount

5. Return: Map<int, List<TmdbEpisode>> { seasonNumber → episodes }
```

### 6.3 Enrich titoli episodi

Per ogni stagione AniList con `streamingEpisodes`:
- Parse titoli dal formato `"Episode N - Real Title"` o `"EN - Real Title"`
- Costruisci map `{ episodeNumber → realTitle }`
- Per ogni episodio con titolo placeholder (regex `/^Episodio?\s+\d+$/i`):
  - Sostituisci con titolo reale da Crunchyroll

---

## Fase 7 — Aggiornamento Database SQLite

### 7.1 Nuove tabelle Drift (schema v9)

**`YunaCache`** — mapping TMDB → AniList IDs:
```dart
class YunaCache extends Table {
  IntColumn get tmdbId => integer()();          // PK
  TextColumn get anilistIdsJson => text()();    // JSON array
  DateTimeColumn get cachedAt => dateTime()();
  @override Set<Column> get primaryKey => {tmdbId};
}
```

**`AnimeSeasonCache`** — dati AniList per stagione:
```dart
class AnimeSeasonCache extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get tmdbShowId => integer()();
  IntColumn get seasonNumber => integer()();
  IntColumn get anilistId => integer()();
  IntColumn get episodeCount => integer()();
  TextColumn get status => text()();
  TextColumn get animeSeasonJson => text()(); // JSON completo NormalizedAnimeSeason
  DateTimeColumn get cachedAt => dateTime()();
  DateTimeColumn get validUntil => dateTime()();
}
```

### 7.2 Aggiornamento `TrackedShows`

Aggiungere colonna:
```dart
BoolColumn get isAnime => boolean().withDefault(const Constant(false))();
```

### 7.3 Aggiornamento `CachedEpisodes`

Aggiungere colonne:
```dart
IntColumn get absoluteEpisodeNumber => integer().nullable()();
DateTimeColumn get airingAt => dateTime().nullable()();
```

### 7.4 Migrazione schema v8 → v9

```dart
// In app_database.dart MigrationStrategy:
from8To9: (m, schema) async {
  await m.addColumn(schema.trackedShows, schema.trackedShows.isAnime);
  await m.addColumn(schema.cachedEpisodes, schema.cachedEpisodes.absoluteEpisodeNumber);
  await m.addColumn(schema.cachedEpisodes, schema.cachedEpisodes.airingAt);
  await m.createTable(schema.yunaCache);
  await m.createTable(schema.animeSeasonCache);
}
```

---

## Fase 8 — TTL Cache Dinamico per Anime

### 8.1 Logica TTL aggiornata in `CacheDao`

Estendere la logica già esistente:

```
Serie anime RELEASING con nextAiringEpisode.airingAt:
  → validUntil = DateTime.fromMillisecondsSinceEpoch(airingAt * 1000)
  (cache scade esattamente quando l'episodio va in onda)

Serie anime RELEASING senza airingAt:
  → validUntil = now + 6 ore

Serie anime FINISHED/CANCELLED:
  → validUntil = now + 30 giorni

Yuna mapping cache:
  → validUntil = now + 7 giorni

AniList season cache:
  → stessa logica basata su status AniList
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
  // 1. Check cache AnimeSeasonCache (SQLite)
  // 2. Se miss/scaduta: getAniListDataForTmdbId(tmdbId)
  //    a. YunaService.getAniListIds(tmdbId)
  //    b. AniListService.fetchBatch(anilistIds)
  //    c. AnimeDataMerger.merge(tmdbDetail, anilistMediaList)
  // 3. Salva in cache
  // 4. Return List<NormalizedAnimeSeason>
}
```

### 9.2 Aggiornamento `showDetailProvider(tmdbId)`

```dart
// Dopo aver ottenuto TmdbShowDetail:
if (showDetail.isAnime) {
  final animeSeasonsData = await ref.read(animeDataProvider(tmdbId).future);
  return showDetail.copyWith(animeSeasonsData: animeSeasonsData);
}
return showDetail;
```

### 9.3 Aggiornamento `seasonDetailProvider(showId, seasonNumber)`

```dart
// Se la serie è anime:
// Usa animeSeasonsData per determinare tmdbSeasonNumber e episodeCount
// Chiama getAnimeEpisodesBySeason() per redistribuzione
// Invece di getSeasonDetails() standard
```

### 9.4 Aggiornamento `upcomingEpisodesProvider`

Per serie anime con `nextAiringEpisode.airingAt`:
- Usa timestamp AniList (preciso al secondo)
- Invece della data TMDB (solo giorno)

---

## Fase 10 — UI: Visualizzazione Dati Anime

### 10.1 `ShowDetailScreen` - badge anime

Aggiungere badge visivo "ANIME" o icona per distinguere le serie anime dalle TV normali.

### 10.2 `ShowDetailScreen` - info stagione anime

Per ogni stagione di un anime, mostrare:
- Anno di uscita e stagione dell'anno (es. "Fall 2023")
- Status AniList (RELEASING, FINISHED, HIATUS)
- Titolo in romaji/inglese da AniList (se diverso da TMDB)

### 10.3 `EpisodeTile` - orario preciso

Per episodi con `airingAt` (solo prossimo ep di anime in corso):
- Mostrare orario preciso invece della sola data
- Es. "Oggi alle 17:30" invece di "28 Apr"

### 10.4 `NextEpisodeCard` / `UpcomingEpisodeCard`

Per anime in corso:
- Usare `airingAt` da AniList per countdown preciso
- Mostrare "Ep. 12 tra 2 giorni, 3 ore"

---

## Fase 11 — Gestione Errori e Fallback

### 11.1 Fallback a TMDB-only

Se Yuna o AniList falliscono:
- La serie rimane con `isAnime = false` (o mantiene i dati TMDB puri)
- Nessun crash, nessun errore visibile all'utente
- Log dell'errore per debug

### 11.2 Fallback titolo AniList

Se Yuna non trova mapping:
- Tentare `ANIME_SEARCH_QUERY` su AniList con il titolo TMDB
- Se trovato → usare quell'ID
- Se non trovato → fallback TMDB-only

### 11.3 Fallback episodi

Se la redistribuzione produce un conteggio diverso da quello atteso:
- Usare i dati TMDB originali senza redistribuzione
- Logga warning

---

## Ordine di Implementazione Consigliato

```
1. [Fase 1]  Aggiungere rilevamento anime a TmdbShowDetail
2. [Fase 4]  Creare modelli AniListMedia e NormalizedAnimeSeason
3. [Fase 2]  Implementare YunaService (solo HTTP, no cache)
4. [Fase 3]  Implementare AniListService (GraphQL + rate limiting)
5. [Fase 5]  Implementare AnimeDataMerger
6. [Fase 7]  Aggiornare schema DB (v9) con nuove tabelle
7. [Fase 2]  Aggiungere cache SQLite a YunaService
8. [Fase 6]  Implementare redistribuzione episodi
9. [Fase 8]  TTL dinamico per cache anime
10. [Fase 9] Aggiornare provider Riverpod
11. [Fase 10] Aggiornare UI
12. [Fase 11] Testing e fallback
```

---

## File da Creare (Nuovi)

| File | Descrizione |
|------|-------------|
| `lib/features/series/data/yuna_service.dart` | Chiamate HTTP a Yuna.moe |
| `lib/features/series/data/anilist_service.dart` | Chiamate GraphQL a AniList |
| `lib/features/series/data/anilist_queue.dart` | Rate limiting token-bucket per AniList |
| `lib/features/series/data/anime_data_merger.dart` | Merge + normalizzazione stagioni |
| `lib/features/series/data/models/anilist_media.dart` | Modelli dati AniList |
| `lib/features/series/data/models/normalized_anime_season.dart` | Stagione normalizzata post-merge |

---

## File da Modificare (Esistenti)

| File | Modifiche |
|------|-----------|
| `lib/features/series/data/models/tmdb_show_detail.dart` | Aggiungere `isAnime`, `originCountries`, `genres`, `animeSeasonsData` |
| `lib/features/series/data/models/tmdb_episode.dart` | Aggiungere `absoluteEpisodeNumber`, `airingAt` |
| `lib/features/series/data/tmdb_service.dart` | Aggiungere `getAnimeEpisodesBySeason()`, parsing `origin_country` e `genres` |
| `lib/core/database/app_database.dart` | Schema v9 + migrazione |
| `lib/core/database/tables/*.dart` | Nuove tabelle + nuove colonne |
| `lib/core/database/daos/cache_dao.dart` | TTL dinamico anime |
| `lib/features/series/providers/series_providers.dart` | `animeDataProvider` + aggiornamenti showDetail/seasonDetail/upcoming |
| `lib/features/series/presentation/show_detail_screen.dart` | Badge anime, info stagione AniList |
| `lib/features/series/presentation/widgets/episode_tile.dart` | Orario preciso per anime |
| `lib/features/series/presentation/widgets/next_episode_card.dart` | Countdown da AniList |

---

## Rischi e Considerazioni

1. **Yuna.moe è un servizio community** — potrebbe avere downtime o discontinuità. Il
   fallback per ricerca per titolo è essenziale.

2. **AniList non richiede autenticazione** per query pubbliche, ma ha rate limiting.
   Il token bucket da 12/10s è conservativo e sicuro.

3. **Mapping TMDB ↔ AniList non è perfetto** — alcuni anime potrebbero avere stagioni
   che non coincidono. La redistribuzione posizionale funziona nella maggior parte dei
   casi ma può fallire per show con archi non lineari.

4. **Episode numbering anomalo** — alcuni anime (es. Fullmetal Alchemist Brotherhood)
   hanno numerazione assoluta in TMDB che differisce da quella per-stagione AniList.
   L'`absoluteEpisodeNumber` preserva il riferimento originale per il tracking.

5. **Schemi DB** — la migrazione v8→v9 aggiunge colonne nullable e nuove tabelle,
   è backward-safe per i dati esistenti.
