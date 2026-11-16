# Dati e persistenza locale

## Proprietà del database

- Schema **v14**: `lib/core/database/app_database.dart`.
- Produzione: singleton `AppDatabase.instance`, aperto con
  `driftDatabase(name: 'showtracker')`.
- Provider DAO: `lib/core/database/database_provider.dart`.
- Test: `AppDatabase.forTesting(NativeDatabase.memory())`; mai DB personale.
- Non esiste cifratura SQLite configurata nel codice applicativo. Le credenziali
  usano storage separato: [08](08-security-permissions.md).

## Schema e identificativi

Definizioni autorevoli: `lib/core/database/tables/`.

| Tabella / classe Dart generata | Chiavi | Dati e responsabilità |
| --- | --- | --- |
| `TrackedShows` / `TrackedShow` | PK `id`, UNIQUE `tmdbId` | Identità, stato, rating/note, totali, anime flag, date, puntatore prossimo episodio |
| `TrackedEpisodes` / `TrackedEpisode` | PK `id`, UNIQUE `(showId, seasonNumber, episodeNumber)` | Visto e timestamp; `showId` riferisce l'ID locale serie |
| `TrackedSeasons` / `TrackedSeason` | PK `id`, UNIQUE `(showId, seasonNumber)` | Conteggio persistito per stagione/cour; FK verso serie |
| `TrackedMovies` / `TrackedMovy` | PK `id`, UNIQUE `tmdbId` | Titolo, descrizione, poster, stato, rating/note, uscita e timestamp |
| `TrackedGames` / `TrackedGame` | PK `id`, UNIQUE `rawgId` | Titolo, cover, stato, rating/note, uscita, playtime, piattaforme e voto API |
| `CachedEpisodes` / `CachedEpisode` | PK `id`, UNIQUE `(tmdbShowId, seasonNumber, episodeNumber)` | Metadati episodio, numero assoluto, date/orario e `cachedAt` |
| `YunaCache` / `YunaCacheData` | PK `tmdbId` | Lista ID AniList JSON e `cachedAt` |
| `AnimeSeasonCache` / `AnimeSeasonCacheData` | PK `id`, UNIQUE `(tmdbShowId, seasonNumber)` | Cour normalizzato JSON, conteggi, stato, AniList ID, `cachedAt`, `validUntil` |

- Non confondere `showId` locale con `tmdbShowId` esterno.
- Per anime, `seasonNumber` nei progressi/cache normalizzati è il numero sintetico
  del cour. `tmdbSeasonNumber` nel modello normalizzato è una coordinata diversa.
- Non assumere cancellazione SQL a cascata: le FK dichiarate non la configurano.
  Usare il DAO serie che elimina i figli; vedere i test con/senza foreign key.
- `TrackedMovy` è il nome effettivo generato da Drift, non un refuso da correggere a mano.

## Modelli e serializzazione

| Tipo | Implementazione |
| --- | --- |
| DTO TMDB / AniList / RAWG | Classi Dart e factory manuali in `features/*/data/models/` |
| Cour normalizzato | `NormalizedAnimeSeason.toJson/fromJson` |
| Stato media | `textEnum<MediaStatus>()`, valori enum persistiti come testo |
| Piattaforme gioco | JSON `List<String>` in colonna testo |
| Mapping Yuna | Lista interi JSON |
| Payload sync | `lib/features/sync/domain/models/sync_payload.dart`, chiavi compatte |
| Record DB / companion | Generati da Drift in `*.drift.dart` |

Non introdurre assunzioni su Freezed o json_serializable: non sono usati.
I payload API non coincidono con i record DB né con il formato sync.

## DAO, query e scritture

- `ShowsDao`, `MoviesDao`, `GamesDao`: librerie e mutazioni personali.
- `CacheDao`: metadati episodio, letture fresh/stale e summary compatti.
- `AnimeCacheDao`: mapping Yuna e cour fresh/stale.
- Notifier restituiscono `watch*`; le scritture devono pubblicarsi tramite DB.
- Per progressi episodio e timestamp parent, mantenere la transazione condivisa.
- Mantenere chiavi naturali come target di `DoUpdate`. Un upsert sul solo `id`
  autoincrementale non risolve conflitti su `(tmdbShowId, seasonNumber)`.
- Usare batch dentro transazioni per scritture multiple; un dispatch batch non
  equivale a una sola scrittura SQL.
- `replaceSeasonEpisodes`: download completo riuscito, sostituzione atomica delle
  coordinate obsolete. `saveSeasonEpisodes`: scritture parziali senza pruning.
- Non eliminare dati stale dopo fetch fallito.
- `allSeasonEpisodeCountsProvider` condivide i conteggi; le family per serie sono
  proiezioni. Evitare una query per card.
- La visibilità legge cour e summary in bulk; distinguere target assente, stagione
  senza righe e target presente senza data.

## Cache e refresh

| Contenuto | Policy effettiva |
| --- | --- |
| Mapping Yuna | 7 giorni, `AnimeCacheDao.getYunaIds` |
| Episodi serie conclusa/cancellata | 30 giorni |
| Episodi stagione corrente regolare | 1 giorno |
| Episodi stagioni precedenti regolari | 7 giorni |
| Cour `RELEASING` | Fino al prossimo airing; 6 ore se assente o già trascorso |
| Cour `HIATUS` | 14 giorni |
| Cour `NOT_YET_RELEASED` | 7 giorni |
| Altri stati cour | 30 giorni |
| Discovery | Retention in memoria 30 minuti, non tabella Drift dedicata |

Fonti TTL: `_seasonCacheTtl` in `series_providers.dart` e
`NormalizedAnimeSeason.cacheTtl`. Il commento a `CacheDao.ttlDays` nella tabella
episodi è obsoleto: quel campo non definisce la policy attuale.

- `getFreshAnimeSeasons` richiede che l'insieme letto sia fresco; il fallback
  `getStaleAnimeSeasons` resta disponibile anche dopo la scadenza.
- Refresh manuale: `expireAnimeCacheForShow` scade cour e mapping Yuna;
  `expireCacheForShow` scade episodi. Non sostituire con cancellazione.
- La presenza di `clearCacheForShow` nel DAO non ne autorizza l'uso per il refresh.
- Cache delle immagini e file dei widget hanno un ciclo diverso da Drift;
  non è implementato un pruning globale applicativo.

## Timestamp e denormalizzazioni

- `nextEpisode{Number,Season,Name,AirDate}` alimenta calendario/widget offline.
  Non azzerarlo usando uno snapshot parziale.
- `updatedAt` di serie/episodi/film/giochi serve alla sync; può essere null per
  compatibilità. La sync usa il fallback ad `addedAt` sui media.
- Hydration film/giochi aggiorna soltanto metadati e preserva timestamp/personale.
- Il formato wire sync usa secondi Unix: non trasferire millisecondi senza una
  modifica esplicita del contratto. Conflitti e unione: [10](10-p2p-sync.md).

## Migrazioni e generazione

1. Modificare `tables/` e incrementare `schemaVersion`.
2. Aggiungere step `if (from < N)` a `MigrationStrategy.onUpgrade`.
3. Gestire backfill e dati legacy, non solo schema vuoto.
4. Eseguire `dart run build_runner build`; non editare i generati.
5. Aggiungere fixture/migrazioni verificabili e test delle query coinvolte.

Esempi storici: v7 rimuove libri; v8 ricostruisce giochi IGDB→RAWG; v9 aggiunge
anime/cache; v12 aggiunge puntatore; v13 aggiunge timestamp; v14 normalizza film.
`test/core/database/migrations_test.dart` copre upgrade reali v12→14 e v13→14;
non dichiarare copertura completa v7→14.
