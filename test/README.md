# Test di ShowTracker

## Comandi

SDK verificato: **Flutter 3.47.6 / Dart 3.13.5**.

```bash
flutter pub get
flutter analyze --no-pub
flutter test --no-pub
flutter test --no-pub --coverage --test-randomize-ordering-seed=20261029

# Un file o un singolo caso
flutter test --no-pub test/widget_test.dart
flutter test --no-pub test/widget_test.dart --plain-name 'App smoke test'

# Solo Android: scegliere un device da flutter devices
flutter test integration_test/app_smoke_test.dart -d emulator-5554 --no-pub
```

`flutter test` esegue `test/`, non lo smoke in `integration_test/`.
Il report `coverage/lcov.info` è generato e ignorato da Git. La CI lo conserva come
artefatto; non impone una soglia percentuale arbitraria. Considerare i file
applicativi, escludendo `*.g.dart`/`*.drift.dart`, quando si cercano buchi utili:
una riga eseguita non dimostra che tutti i suoi comportamenti siano corretti.

Le chiamate applicative durante i test sono simulate: non servono chiavi, account,
API esterne o una rete LAN. Il setup delle dipendenze e il primo build hook SQLite
possono invece richiedere Internet per scaricare pacchetti e librerie native.
Su Windows evitare più comandi Flutter contemporanei nella stessa directory:
la libreria SQLite del runner può restare bloccata da un altro processo.

## Mappa della copertura

| Area | File principali | Contratti verificati |
| --- | --- | --- |
| Avvio | `widget_test.dart`, `support/app_test_harness.dart` | App/router reali, schermata autenticata vuota, rescheduling di avvio sul DB vuoto, teardown senza timer pendenti |
| Auth e routing | `core/auth/`, `core/router/` | Ripristino/precedenza sessione e chiave, login/logout, errore storage, route protette, tab, privacy/ritorno, conteggi Profilo senza controllo aggiornamenti automatico, onboarding scorrevole |
| Persistenza | `core/database/` | CRUD, duplicati, stati/voti/timestamp, stream e conteggi, watched/unwatched, episodi precedenti, assente/null, cancellazione serie e figli con/senza foreign key, rollback atomico |
| Migrazioni | `core/database/migrations_test.dart` | Schema v14 e upgrade reali v12→14 e v13→14 con dati: backfill timestamp e normalizzazione stato film, progressi/cache preservati, integrità e scritture successive |
| Cache | `core/database/{cache,anime_cache}_dao_test.dart` | Chiavi composte/upsert, isolamento, TTL, cache anime scaduta ancora leggibile, scadenza Yuna, tutte le cour richieste per un insieme fresco |
| Serie e anime | `features/series/`, `watch_next_rules_test.dart` | Avanzamento puntatore dopo il visto, aggiornamento del solo nome episodio, visibilità offline, conteggi cour, fallback stale/outage, nessuna degradazione del sync alla numerazione TMDB, scelta sequel per data, merger TV/ONA e TTL |
| Coda e servizi | `features/series/{anilist_queue,anilist_service,tmdb_service,yuna_service}_test.dart`, `features/games/rawg_service_test.dart` | Budget/refill/concorrenza AniList e rilascio slot dopo errore, retry 429, fallback bilingue TMDB e stagioni/episodi, distribuzione anime in cour, errori HTTP/JSON, mapping Yuna e timeout, pagine/filtri RAWG e limite discovery |
| Notifiche | `core/notification_body_test.dart`, `features/series/upcoming_episode_sync_test.dart` | Testo italiano, date future/passate, ora anime vs 09:00, cancellazione/rischedulazione, salvataggio progressi anche se il canale nativo fallisce |
| Film e giochi | `features/{movies,games}/*providers_test.dart` | Stati, voti e rimozione con DAO reali in memoria |
| Sync | `features/sync/` | Range, compressione e payload corrotti/legacy, export/import tra due DB senza HTTP, timestamp newer/older/equal, unione visto, idempotenza, rollback, hydration offline, handler Shelf/token senza socket |
| Rete | `core/network/tmdb_http_client_test.dart` | Chiavi/sessione per host esatto, nessuna credenziale su host estranei, query/header/metodo/body preservati |
| Ricerca | `core/paged_search_test.dart`, `features/search/`, `features/games/game_search_ranking_test.dart` | Debounce, paginazione concorrente/errori/retry/dispose/cache, semi/dedup/errori parziali, discovery vuota, titolo tracciato nascosto senza refetch |
| Update | `features/update/` | Versioni, release/asset/APK, risposte anomale, timeout/rate limit, canale permessi e lifecycle; nessun download o installazione |
| Interazioni | `features/*/presentation/` | Episodi futuri/read-only/toggle, dialog episodi precedenti (solo questo/tutti/annulla), card e conteggio Da Vedere dopo il visto, film visto/doppio tap, conferma/annulla rimozione film, filtro locale giochi |
| Android | `../integration_test/app_smoke_test.dart` | Montaggio UI/router su dispositivo con DB in memoria, schermata serie vuota, film inserito e visibile nel tab Film |

Le fixture delle migrazioni sono ricavate dai DDL storici, non da un database
corrente etichettato come vecchio. **La migrazione v7→14 non è coperta**: la storia
Git disponibile non contiene uno schema v7 completo verificabile (inizia già da
v8). Non inventare una fixture per far risultare verde quel percorso.

## Convenzioni per aggiungere una regressione

1. Riprodurre prima l'errore con un assert sull'effetto osservabile (DB, risultato,
   richiesta o interfaccia), poi applicare la correzione minima.
2. Usare `AppDatabase.forTesting(NativeDatabase.memory())`, mai
   `AppDatabase.instance` o file della libreria personale. Testare le transazioni
   con trigger/errori mirati se occorre verificare davvero il rollback.
3. Usare `MockClient` per le richieste e stringhe di credenziali fittizie. Non
   leggere `dart_defines/dev.json`. Un client che rifiuta richieste inattese evita
   dipendenze Internet accidentali.
4. Dare a ogni `ProviderContainer`/`ProviderScope` `retry: noProviderRetry`.
   Tenere una subscription per stream e provider autoDispose usati attraverso
   `await`; usare `readFuture` quando adatto. Il retry automatico non deve
   mascherare errori o aggirare AniListQueue.
5. Simulare il tempo con `fake_async`, pump e Completer, non attese reali.
   `fake_async` non modifica `DateTime.now()`: usare date ben lontane dal confine
   per test TTL ordinari e riferimenti relativi quando si verifica il futuro.
6. Nei widget test avviare/attendere SQLite tramite `tester.runAsync` e poi
   eseguire pump limitati. Se un timer avvia I/O SQLite, anche il pump della sua
   scadenza può dover stare in `runAsync` (vedi `next_episodes_screen_test.dart`).
   Non usare `pumpAndSettle` su loader che possono restare attivi indefinitamente.
7. Smontare l'albero prima di disporre router/container, chiudere client e
   attendere `db.close()`. Il bootstrap globale di produzione non va alterato per
   chiudere le risorse di un test.
8. Simulare solo i confini necessari. L'harness mantiene DAO/notifier/router
   reali, ma normalmente disattiva il rescheduling di avvio su librerie popolate;
   i test dedicati esercitano separatamente scheduling e canali nativi.
9. Nessun edit manuale ai file generati. Per modifiche annotate usare
   `dart run build_runner build`.

## Confini e checklist nativa

Lo smoke Android monta `ShowTrackerApp` con container e DB temporanei; **non
chiama `main()`** e non convalida inizializzazione completa, secure storage reale,
bootstrap timezone o widget in background. I mock dei MethodChannel verificano
le chiamate e gli errori gestiti dall'app, non la realizzazione nativa del plugin.
La CI Linux esegue soltanto la suite host, non lo smoke Android.

Prima di una release restano prove manuali su un dispositivo di test:

- Login nel browser e ritorno reale con deep link `showtracker://auth`.
- Ripristino credenziali e libreria dopo chiusura/riapertura dell'app.
- Ricezione notifica con app chiusa, permessi/orari e tap sulla notifica.
- Widget home Maratona/Prossimamente e tap "visto" nel background isolate.
- Sync tra due dispositivi: fotocamera/QR, IP e connettività LAN reali.
- "Installa app sconosciute", ritorno dalle impostazioni, download e installer
  con APK firmato correttamente e build number maggiore, solo su device di test.
- Immagini/API reali, offline effettivo e comportamento con testo ingrandito.

Restano inoltre rami UI non esercitati o solo montati indirettamente, in
particolare i dettagli completi serie/giochi, sezioni stagioni, card In Uscita,
schermata QR e dialog dell'aggiornamento. Le liste film/giochi non hanno tutte le
combinazioni di filtri/transizioni coperte a livello widget (DAO e notifier hanno
verifiche separate). Il report non comprende necessariamente file mai caricati,
come il bootstrap `main.dart` e il gestore dei widget home.

La suite è una protezione ampia delle regressioni principali, non una prova di
ogni schermata, plugin, versione Android o combinazione possibile di dati.
