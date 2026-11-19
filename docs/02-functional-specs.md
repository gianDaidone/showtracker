# Specifiche funzionali

## Domini e accesso

Fonti: `lib/features/`, `lib/core/router/app_router.dart`,
`lib/core/database/tables/enums.dart`.

- Serie TV e anime condividono la libreria; gli anime hanno numerazione normalizzata.
- Film e giochi hanno librerie proprie; non esiste una feature libri.
- Il router richiede stato TMDB autenticato: sessione oppure chiave manuale.
- RAWG è opzionale e indipendente; non sblocca da solo l'onboarding TMDB.
- In `lib/core/constants.dart`, `kEnableGames` vale attualmente `true`.
  Non legge `ENABLE_GAMES`: il commento relativo al dart-define è obsoleto.

## Stati e azioni

| Valore persistito `MediaStatus` | Serie | Film | Giochi |
| --- | --- | --- | --- |
| `planToWatch` | Da vedere | Da vedere | Backlog |
| `watching` | In visione | Non previsto nei flussi correnti | In gioco |
| `completed` | Completato | Visto/completato secondo schermata | Giocato |
| `paused` | In pausa | Enum condiviso; non dedurre una transizione UI dedicata | In pausa |
| `dropped` | Abbandonato | Abbandonato | Abbandonato |

- Film: migrazione v14 e import convertono `watching` in `planToWatch`.
  Il notifier film espone ancora un metodo generico di cambio stato: non equivale
  a una validazione di dominio a ogni confine.
- Nuovi film/giochi entrano in `planToWatch`; nuove serie entrano in `watching`.
- Rating personale e voto API sono dati distinti. I voti RAWG sono normalizzati su 10.
- Azioni giochi: `markPlayed` completa e salva rating; `markFolded` abbandona e
  cancella rating; `resetToBacklog` ripristina backlog e cancella rating.
- Rimozione e conferme appartengono alle schermate; la persistenza passa dai DAO.

Fonti operative: `lib/features/{series,movies,games}/providers/` e relative
schermate di dettaglio/lista in `presentation/`.

## Serie: “Da Vedere” e “In Uscita”

- `visibleWatchingShowsProvider` in `series_providers.dart` è l'autorità per lista
  e conteggio “Da Vedere”. La visibilità non richiede rete.
- `NextEpisodeCard` riusa `watch_next_rules.dart`; può invalidare una volta la
  lista quando riceve metadati più freschi che ne cambiano la visibilità.
- La card mostra il titolo per intero, gli arretrati aggiuntivi nel badge
  `+N ep` e una barra per gli episodi visti nella stagione o nel cour del
  prossimo episodio. Il badge compare per conteggi positivi. La barra sta sotto
  il titolo dell'episodio, nella colonna del testo, e richiede un totale noto
  compatibile con il prossimo episodio. Se il riepilogo non ha un totale,
  la card usa il conteggio locale della stagione o del cour.
- La miniatura segue l'altezza del contenuto della card fino a 112 px logici.
  Nelle card più alte resta allineata in alto e il testo può andare a capo.
- `computeNextToWatch` prosegue dal massimo episodio visto nella massima stagione
  vista; non è un algoritmo di ricerca del primo buco nella cronologia.
- Avanzare stagione solo con totale noto e positivo. Per cour in produzione,
  `episodeCount == 0` significa totale ignoto.
- `resolveHasAired` combina i verdetti: una conferma AniList/TMDB prevale su un
  diniego, poi usa il DB quando entrambi sono ignoti. Eccezione: per una serie
  normale il puntatore del giorno corrente ancora futuro impedisce l'anticipo
  rispetto all'orario salvato, tipicamente 09:00.
- Episodio assente dalla cache → informazione ignota; presente senza data valida
  → nessuna prova di uscita. Non confondere i due casi.
- `upcomingEpisodesProvider` costruisce “In Uscita” usando anche il puntatore
  denormalizzato `nextEpisode*`, disponibile offline.
- Il tab “In Uscita” raggruppa le card in un'unica timeline per data locale,
  anche oltre i 30 giorni. Ogni card mostra il titolo completo della serie e
  il codice episodio. Mostra l'orario, centrato verticalmente sul lato destro,
  solo se il calendario fornisce un orario preciso. Il tap apre il dettaglio
  episodio.
- Una card può espandersi per mostrare gli episodi successivi della stessa
  stagione o cour in uscita insieme. La card carica il dettaglio stagione
  solo quando viene costruita nella timeline. Con dati TMDB di sola data
  raggruppa per giorno. Se l'episodio ha un orario preciso, include solo
  episodi con lo stesso istante esplicito. Ogni riga apre il suo dettaglio.
  Se il dettaglio non è disponibile, resta visibile il prossimo episodio
  salvato.
- `_resolveNextEpisode` deve superare un puntatore TMDB già trasmesso: il remoto
  può mantenerlo in `next_episode_to_air` per ore.
- Per segnare episodi precedenti usare il flusso esistente di scelta solo
  episodio/tutti/annulla. Episodi futuri e snapshot incompleti hanno azioni limitate.

Regole canoniche: `lib/features/series/data/watch_next_rules.dart`.
Numerazione e fallback anime: [09](09-anime-pipeline.md).

## Film e giochi: librerie e date di uscita

- L'header mostra il conteggio della libreria e apre l'elenco completo. La
  ricerca si apre con il filtro del dominio.
- Le card di Da Vedere, Backlog e Giocati mostrano il titolo su più righe.
  La copertina può seguire il contenuto fino a 112 px logici. I giochi
  mostrano fino a due piattaforme e i voti già disponibili.
- In Uscita usa una timeline per giorno locale, anche oltre i 30 giorni.
  La data compare nell'intestazione. I giochi in backlog senza una data
  rimangono in fondo sotto «Data da annunciare». I film senza data e in
  stato Da vedere rimangono nel tab Da Vedere.

## Ricerca e discovery

Fonti: `lib/features/search/presentation/search_screen.dart`, `discover_view.dart`,
`lib/features/search/providers/`, `lib/features/search/data/discover_rules.dart`.

- Query vuota: mostrare discovery. Sotto due caratteri, il motore di ricerca
  paginata restituisce vuoto senza chiamare il servizio.
- “Tutti”: righe orizzontali per dominio, limitate alla prima pagina.
- Filtro singolo: lista verticale paginata e chip Per te/Di tendenza/Più votati.
- Provider discovery condivisi tra righe e liste; retention 30 minuti dopo
  l'ultimo listener. Gli errori iniziali non vengono conservati nello stesso modo.
- Escludere i titoli già tracciati nella UI, senza rifare la richiesta.
- “Per te”: fino a cinque semi serie/film in `watching` o `completed`, ordinati
  per voto e recenza. Unire consigli per frequenza e ordine intercalato.
- Giochi: tre semi, fino a due generi prevalenti. Trending è un'approssimazione
  RAWG: più aggiunti tra le uscite degli ultimi 90 giorni; topRated usa Metacritic.
- Discovery RAWG: massimo dieci pagine da 40. La ricerca testuale ha regole proprie.
- Errore su pagina successiva: mantenere risultati precedenti e offrire retry
  esplicito, senza loop automatico del footer.
- Ricerca offline: usare `searchErrorMessage`, senza esporre eccezioni DNS nella UI.

## Profilo, sync e aggiornamenti

- Profilo gestisce credenziali TMDB/RAWG, privacy, sync e controllo aggiornamenti.
- Sync via QR: trasferire ID, stati e progressi supportati; recuperare i titoli
  `Sconosciuto` successivamente. Non è una copia completa del DB: [10](10-p2p-sync.md).
- “Cerca aggiornamenti” è un'azione manuale. Nessun controllo all'avvio o in background.
- Gli aggiornamenti confrontano `major.minor.patch`; per pubblicare alzare anche
  il build number e usare la stessa firma: [11](11-android-integrations.md).

## Offline: contratto limitato

- Librerie e progressi persistiti restano locali.
- Il dettaglio serie tracciate può usare `isLocalSnapshot`, metadati salvati e
  episodi stale. Mostrare banner italiano e preservare la numerazione.
- Uno snapshot parziale non autorizza correzione dei totali, completamento,
  sync metadata o rischedulazione.
- Refresh che ripiega sul locale deve segnalare mancato aggiornamento.
- Non promettere il dettaglio remoto completo offline per film/giochi o dati mai salvati.

## Regressioni da consultare

`test/watch_next_rules_test.dart`, `test/features/series/presentation/`,
`test/features/search/`, `test/features/movies/presentation/`,
`test/features/games/games_providers_test.dart` e `test/features/sync/`.
