# Pipeline serie e anime

## File da leggere prima di modificare

- `lib/features/series/providers/series_providers.dart`: coordinamento completo.
- `lib/features/series/data/anime_data_merger.dart`: normalizzazione.
- `lib/features/series/data/models/normalized_anime_season.dart`: cour e TTL.
- `lib/features/series/data/watch_next_rules.dart`: prossimo episodio/uscita.
- `lib/features/series/data/local_show_snapshot.dart`: fallback parziale.
- `lib/core/database/daos/anime_cache_dao.dart`: mapping persistito e upsert.

## Identità e coordinate

- `TmdbShowDetail.isAnime`: genere Animation/Animazione e almeno un paese
  di origine in `{JP, KR, CN, TW, HK}`; snapshot locale usa il flag persistito.
- `seasonNumber` normalizzato è sintetico, da 1 a N; `tmdbSeasonNumber` indica
  la stagione sorgente, che può contenere più cour.
- Progressi utente sono salvati sulle coordinate sintetiche: non sostituirle
  con stagioni TMDB anche quando i numeri coincidono.
- `absoluteEpisodeNumber` e offset servono alla redistribuzione episodi.
  Non ricostruirli in una card o in codice Kotlin.

## Pipeline online

1. Leggere la cache cour fresca con `getFreshAnimeSeasons`.
2. Se manca, ottenere mapping TMDB→AniList da cache Yuna o `YunaService`.
   Non salvare mapping vuoti: `[]` può significare outage, non assenza definitiva.
3. Senza mapping utile, cercare per titolo TMDB localizzato e poi originale.
4. Se c'è una data TMDB, scegliere il candidato AniList con inizio più vicino
   entro ±60 giorni; senza data il codice usa il primo risultato. Non scegliere
   sempre il primo per un sequel omonimo.
5. Caricare i media attraverso `AniListService`/`AniListQueue`. Se gli ID mappati
   non producono media, tentare ricerca titolo e aggiornare il mapping utile.
6. `AnimeDataMerger.merge` combina stagioni TMDB e media AniList, preferisce
   `TV`/`TV_SHORT`, usa `ONA` quando non ci sono TV idonei.
7. Cercare stagioni rimaste placeholder (`anilistId == -1`) usando titolo e
   data di quella stagione; escludere ID già noti e stagioni già parzialmente mappate.
8. Salvare cour normalizzati con upsert naturale. `_withAnimeSeasons` costruisce
   stagioni sintetiche e label “Parte N · …” per la UI esistente.

`rawShowDetailProvider` condivide il dettaglio bilingue; la Future locale alla
pipeline evita richieste duplicate. `redistributedAnimeEpisodesProvider` condivide
fetch e ridistribuzione tra cour concorrenti. Non duplicare queste chiamate.

## Episodi e conteggi

- TMDB resta la sorgente dei metadati episodio; AniList aggiunge totali,
  confini cour e orari. Il merger non implica che TMDB usi le stesse coordinate.
- Stagione TMDB vuota: il servizio può provare endpoint episodio singoli;
  batch/limiti/errori sono descritti in [04](04-services-api.md).
- `seasonDetail` anime legge solo il cour normalizzato corrispondente; senza
  mapping usa dati stale/locali o una stagione parziale vuota. Non entra nel
  ramo stagione TMDB regolare.
- `syncMetadata` ignora snapshot locali e anime senza `animeSeasonsData`.
- `_effectiveTotalEpisodes` somma i cour quando disponibili; somma zero ripiega
  sul totale TMDB. Non interpretare zero come conferma di assenza episodi.
- `NextEpisodeCard` conserva i conteggi cour DB durante indisponibilità AniList.
- Non dichiarare completamento basandosi su una risposta parziale o saltare
  cour `RELEASING`/`NOT_YET_RELEASED` solo perché il totale è zero.

## Limite attuale dell'aggiunta

`TrackedShowsNotifier.addShow` attende AniList se il dettaglio anime non è ancora
arricchito e usa `readFuture` per mantenerne vivo il caricamento. Tuttavia, se
non ottiene dati utili, prosegue col dettaglio originale e può salvare totali e
stagioni grezzi. Il commento “inserimento immediato” non descrive l'ordine reale:
l'insert avviene dopo il tentativo async.

- Non documentare un blocco completo dell'aggiunta senza mapping: non esiste.
- Un eventuale rafforzamento di questo percorso richiede una modifica dedicata
  e regressioni; non indebolire le protezioni già presenti su lettura e sync.

## Outage, cold offline e refresh

- `animeData` tenta il refetch e poi legge `getStaleAnimeSeasons`; non perde
  la numerazione persistita soltanto perché è scaduta.
- Senza alcuna cache può restituire null: il dettaglio grezzo non autorizza
  azioni episodio con coordinate incompatibili.
- Su errore recuperabile TMDB, `rawShowDetailProvider` costruisce snapshot del
  titolo tracciato e conteggi; `showDetail` compone direttamente i cour persistiti,
  senza lanciare Yuna/AniList nel ramo locale.
- Snapshot non inventano paesi/generi per derivare identità anime.
- `seasonDetail` legge episodi anche scaduti; preserva numeri assoluti e orari.
- HTTP 401/403/404 restano errori; vedere `isRecoverableSeriesError`.
- Non sincronizzare metadati, totali o notifiche da uno snapshot parziale.
- UI segnala dati salvati/indisponibilità mapping; refresh fallito dà feedback
  di errore anche quando riesce a mostrare il locale.
- Refresh usa `expireAnimeCacheForShow` e `expireCacheForShow`, non delete.
  Controllare freschezza dopo il refresh per distinguere fallback stale da successo.
- `saveAnimeSeasons` aggiorna su `(tmdbShowId, seasonNumber)` e rimuove cour
  eccedenti dopo salvataggio riuscito; non sostituire con upsert sul solo `id`.

TTL canonici in [03](03-data-local-storage.md). Coda/retry AniList in [04](04-services-api.md).
Autorità di lista/conteggio e regole 09:00 in [02](02-functional-specs.md).

## Test pertinenti

- `test/features/series/anime_data_merger_test.dart`: mapping/formati/cour.
- `test/features/series/upcoming_episode_sync_test.dart`: puntatore e notifiche.
- `test/features/series/pipeline_coordination_test.dart`: fetch condivisi.
- `test/features/series/{offline_transport,cold_offline}_test.dart`: provider reali,
  trasporto simulato, stale e assenza di scritture passive.
- `test/features/series/presentation/cold_offline_screen_test.dart`: dettaglio e refresh.
- `test/core/database/anime_cache_dao_test.dart`: upsert e scadenza conservativa.
- `test/watch_next_rules_test.dart`: regole condivise, assenza dati e uscite.
