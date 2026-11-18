# Test di ShowTracker

Indice tecnico: [docs/README.md](../docs/README.md). Setup, codegen e CI:
[regole di sviluppo](../docs/06-development-rules.md). Questo file mantiene
la mappa delle verifiche, le convenzioni delle fixture e i limiti dei test nativi.

## Comandi

L’OTA si esercita nella suite ordinaria, senza configurazione di canale.
I test UI verificano voce aggiornamenti, sync nel Profilo, assenza di controlli
automatici, download e annullamento. I mock non provano l’installer Android:
vedere [checklist GitHub](../docs/github-release-checklist.md).

SDK verificato: **Flutter 3.47.6 / Dart 3.13.5**.

```bash
flutter pub get
flutter analyze --no-pub
flutter test --no-pub
flutter test --no-pub --coverage --test-randomize-ordering-seed=20261029

# Un file o un singolo caso
flutter test --no-pub test/widget_test.dart
flutter test --no-pub test/widget_test.dart --plain-name 'App smoke test'
```

`flutter test` esegue la suite in `test/` sul computer, senza installare o
disinstallare l'app su emulatori/dispositivi. Non sono previsti test automatici
su Android.
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
| Avvio | `widget_test.dart`, `core/startup_coordinator_test.dart`, `support/app_test_harness.dart` | App/router reali, bootstrap post-frame idempotente, prompt indipendente dai widget, worker dopo auth, rescheduling sul DB vuoto, teardown senza timer pendenti |
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

## Contratti prestazionali

Le nuove suite `core/database/pipeline_performance_test.dart`,
`features/series/visibility_performance_test.dart`,
`features/series/pipeline_coordination_test.dart`, `core/media_image_test.dart`,
`core/coalescing_refresh_test.dart`, `widgets_manager_test.dart` e
`features/series/presentation/season_virtualization_test.dart` verificano
conteggi query/dispatch, coalescing, reattività cache-only, fetch anime condivisi,
decode aspect-preserving e tile montate su stagioni 200/500 episodi.
`support/query_counter.dart` intercetta l'executor Drift: una submission batch
non equivale a una sola scrittura SQL. Queste prove non misurano FPS, RSS o
cold startup su Android. Protocollo e limiti in `docs/performance-audit.md`.

`features/series/{offline_transport,cold_offline}_test.dart` e
`features/series/presentation/cold_offline_screen_test.dart` verificano il
cold offline con provider reali e solo trasporto DNS/Socket simulato: dati
salvati accessibili, label cour invariate, cache scaduta ancora leggibile,
nessuna scrittura passiva di metadata/progressi, refresh fallito non distruttivo,
recovery online ed errori HTTP non mascherati. Gli override riusciti di
showDetail/seasonDetail non sono sufficienti a verificare questo percorso.

Le suite sync `hydration_safety_test.dart`, `metadata_recovery_test.dart` e
`metadata_recovery_screen_test.dart` coprono recupero placeholder dopo chiave
inserita successivamente, credenziali ripristinate, RAWG/TMDB isolati, cambio
chiave in volo, retry offline e aggiornamento delle librerie giochi/film.
Verificano mapping rating/piattaforme e conservazione di stati, voti personali,
note, playtime esistente, ID e timestamp LWW anche con modifiche concorrenti.
I test lifecycle mantengono auth/interceptor reali con storage e HTTP simulati.

La revisione pre-commit aggiunge regressioni per stagione cache13→12 con
rollback, anime senza mapping anche su numeri coincidenti con TMDB, orario
09:00 preservato offline e notifiche widget su aggiornamenti della sola cache.

`native_widget_metadata_test.dart` controlla etichette/descrizioni dei receiver,
layout di anteprima e fallback PNG dei widget. La build Android valida le
risorse XML; il test non prova il rendering dei diversi launcher. Verificare
manualmente il selettore dopo un aggiornamento APK, senza disinstallare l’app.

## Confini e checklist nativa

La suite e la CI verificano la logica e l'interfaccia sul computer. I mock dei
MethodChannel verificano le chiamate e gli errori gestiti dall'app, non la
realizzazione nativa del plugin: inizializzazione completa, secure storage reale,
bootstrap timezone e widget in background restano da verificare sul dispositivo.

Il test automatico Android è stato rimosso: usava lo stesso applicationId dell'app
personale e la disinstallazione automatica del runner Flutter ne ha cancellato i
dati sull'emulatore. Un DB in memoria non isola il ciclo di installazione Android.
Non reintrodurre test su dispositivo con l'identità dell'app personale.

Prima di una release restano prove manuali su un dispositivo di test:

- Login nel browser e ritorno reale con deep link `showtracker://auth`.
- Ripristino credenziali e libreria dopo chiusura/riapertura dell'app.
- Ricezione notifica con app chiusa, permessi/orari e tap sulla notifica.
- Widget home "Da Vedere"/"In Uscita" (Maratona/Prossimamente), anteprime del
  selettore e tap di apertura app. Il callback Dart `mark_watched` esiste, ma il
  widget Kotlin corrente non collega il controllo all'URI salvato: non considerare
  disponibile/verificato il tap "visto" in background. Contratto in
  [integrazioni Android](../docs/11-android-integrations.md).
- Sync tra due dispositivi: fotocamera/QR, IP e connettività LAN reali.
- "Installa app sconosciute", ritorno dalle impostazioni, download e installer
  con APK firmato correttamente e build number maggiore, solo su device di test.
- Immagini/API reali, offline effettivo e comportamento con testo ingrandito.

Restano inoltre rami UI non esercitati o solo montati indirettamente, in
particolare i dettagli completi giochi, card In Uscita, schermata QR e dialog
dell'aggiornamento. Le sezioni stagioni e le loro azioni hanno ora test dedicati,
ma non ogni combinazione del dettaglio serie è coperta. Le liste film/giochi non hanno tutte le
combinazioni di filtri/transizioni coperte a livello widget (DAO e notifier hanno
verifiche separate). Il report non comprende necessariamente file mai caricati,
come il bootstrap nativo completo di `main.dart`. Il coordinatore e il gestore
dei widget home hanno test Dart/canali simulati, non una prova del rendering
Android o del callback con DB singleton.

La suite è una protezione ampia delle regressioni principali, non una prova di
ogni schermata, plugin, versione Android o combinazione possibile di dati.

## Regressioni sicurezza e affidabilità 2026-11-17

Test dedicati sotto core/auth, core/network, features/sync e features/settings:
callback monouso, mutazioni credenziali concorrenti, cancellazione e redirect,
budget risposte, input QR/zlib/range ostili, rollback, AES-GCM e chiave esclusa
da HTTP, TTL/stop durante bind, camera non avviata in export, testo 200% e tastiera.
I test hydration preservano campi personali e impediscono coordinate TMDB grezze
negli anime. Nessun MethodChannel simulato certifica il runtime Android:
vedere [prove isolate](../docs/native-release-validation.md).

## Consolidamento GitHub

Obiettivo corrente: APK/OTA GitHub su tap, senza configurazione di canale. Dopo il cambio
obiettivo non è stata ripetuta la suite intera: regressioni pertinenti in
sync_encryption_test, encrypted_receiver_test, sync_service_test,
sync_security_test e features/update. Il nuovo test DB prova che plaintext,
envelope sconosciuto e tag alterato falliscono prima di modificare record locali.
Risultati correnti e limiti nell’[audit](../docs/security-reliability-audit.md);
prove native prioritarie nella [checklist GitHub](../docs/github-release-checklist.md).

## Sync progressiva e schema 15

`features/sync/sync_controller_test.dart` verifica pubblicazione prima del drain,
totale unico, retry selettivo/replay, progressi e feed serie senza aprire dettagli,
coordinate cour per ID AniList, cancellazione concorrente, checkpoint recuperabili
e nuova scansione. `sync_progress_panel_test.dart` copre navigazione e testo 200%;
`sync_android_bridge_test.dart` copre throttle/ordine e completamento notifica.
`core/database/migrations_test.dart` include 14→15 e conserva le prove 12/13→corrente.
Le fixture native restano simulate: prima della release provare QR su due device,
Home/schermo spento, ricreazione Activity, rimozione recenti, force-stop, timeout e
permessi/canale notifiche negati. Nessun runner con applicationId personale.

Le regressioni del banner sync verificano posizione alta e sovrapposta senza
ridimensionare il contenuto, chiusura/riapertura dall'icona, navigazione, assenza di
titoli e fasi interne, chiusura automatica e avviso leggibile al 200%. I test del
coordinatore coprono RAWG assente senza errori, conferma persistente e recupero
all'inserimento chiave anche da sessioni precedenti o prima di «Ho capito».

Regressioni contatore sync: trasferimento misto da 54 contenuti seguito da recupero
RAWG con totale dei soli giochi, progresso non decrescente in ogni passaggio,
identità duplicate tra sessioni contate/scaricate una volta e testi del pannello
per ambito del totale e attesa dell'ultimo elemento.
