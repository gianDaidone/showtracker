# Sincronizzazione P2P

## Componenti e ciclo di vita

| Componente | File sotto `lib/features/sync/` |
| --- | --- |
| Export, import e hydration | `services/sync_service.dart` |
| Server HTTP temporaneo e handler | `services/local_sync_server.dart` |
| Payload manualmente serializzato | `domain/models/sync_payload.dart` |
| Range e compressione | `utils/range_utils.dart`, `utils/sync_compressor.dart` |
| QR/scanner e invio/ricezione | `presentation/sync_screen.dart` |
| Recovery app-level | `providers/metadata_recovery_provider.dart` |

- Nessun backend cloud; il dispositivo mittente espone uno snapshot LAN.
- `LocalSyncServer.start` ferma la sessione precedente, genera token e avvia
  Shelf sul solo IPv4 privato selezionato, porta 8080; cerca IP Wi-Fi con fallback
  alle interfacce locali. Sessione massima cinque minuti e chiusura anche al dispose.
- QR contiene `http://{ip}:8080/sync?token={token}#k={chiave}`. La chiave
  AES non viene inviata nella richiesta HTTP.
- Handler separato dal socket per test; token errato → 403; risposta testo
  con envelope cifrato STSYNC2:, no-store e senza CORS wildcard; richieste browser con
  Origin e query/token duplicati rifiutati.
- `SyncScreen.dispose` avvia lo stop del server mittente. Il ricevitore consegna
  subito il QR al coordinatore app-level e lascia la pagina: download, import e
  arricchimento continuano indipendentemente dalla route.

## Contratto del payload

Esempio illustrativo del JSON prima della compressione:

```json
{
  "s": {"123": {"st": "watching", "u": 1800000000, "e": {"1": "1-3,5"}}},
  "g": {"456": {"st": "planToWatch", "u": 1800000000}},
  "m": {"789": {"st": "completed", "u": 1800000000}}
}
```

| Campo | Significato |
| --- | --- |
| `s`, `g`, `m` | Mappe serie, giochi e film; domini vuoti omessi |
| Chiave della mappa | ID esterno come stringa: TMDB o RAWG |
| `st` | Nome persistito di `MediaStatus` |
| `u` | `updatedAt ?? addedAt`, secondi Unix |
| `e` | Per serie: stagione/cour stringa → range degli episodi visti |

- Export raggruppa episodi visti con una lettura, poi `RangeUtils` compatta i range.
- QR diretto legacy: JSON → UTF-8 → zlib → base64, leggibile da chi acquisisce il QR.
- LAN v2: bytes zlib cifrati AES-256-GCM, nonce 12 byte e tag 16 byte, envelope
  STSYNC2: + base64. Chiave nuova per ogni export, nonce casuale e token legato
  come AAD. Implementazione standard del package cryptography, senza cipher proprietario.
- Non trasferisce titoli, poster, cache complete, credenziali, note, rating
  o playtime. Non è un export completo né un backup ripristinabile identico.
- Non contiene tombstone di rimozione o eventi “non visto”; non propaga quelle
  azioni come cancellazioni remote.
- Il JSON legacy non contiene un campo versione; il nuovo export usa `v: 2`
  e richiede peer aggiornati (le vecchie app rifiutano i campi nuovi). Il ricevitore
  continua a leggere il legacy. Per ogni serie v2 `c` distingue `tmdb`/`cour`;
  `a` associa numero cour esportato → AniList ID quando noto. Nessun titolo,
  credenziale o cache completa viene aggiunto al trasferimento.
  Separatamente, l’envelope LAN è versionato
  STSYNC2:. Il proprietario ha approvato l’aggiornamento di entrambi i peer:
  gli URL LAN legacy in chiaro sono rifiutati, senza downgrade; i QR diretti legacy restano leggibili dalla nuova app.
- Il ricevitore supporta anche payload base64 diretto, oltre all'URL HTTP.

## Import e conflitti

`SyncService.importData` esegue tutti i domini in una transazione.

| Dato | Risoluzione attuale |
| --- | --- |
| Media assente | Inserire placeholder `Sconosciuto`, stato e timestamp ricevuti |
| Stato media esistente | Applicare solo se `incomingDate.isAfter(existingDate)` |
| Timestamp uguali | Conservare stato locale |
| Episodi visti serie | Unione con i visti locali, anche se lo stato remoto è più vecchio |
| Episodi già visti | Non riscrivere soltanto per un nuovo timestamp parent |
| Film legacy `watching` | Normalizzare a `planToWatch` |
| Stato non riconosciuto | Fallback `watching` serie/giochi, `planToWatch` film |
| ID/coordinate o struttura non validi | Rifiutare tutto prima della transazione |

- Il merge episodi non è last-write-wins per episodio: il payload non contiene
  timestamp individuali né marcature false.
- Per episodi aggiunti si usa il timestamp parent ricevuto.
- Il codice ripristina il timestamp remoto dopo `updateStatus`, che normalmente
  lo aggiornerebbe all'ora corrente.
- Timestamp wire sono al secondo; clock dei dispositivi non sono riconciliati.
- Validazione strutturale e budget prima di ogni import; snapshot copiato prima
  della transazione. Errori DB tardivi annullano anche modifiche dei domini precedenti.
- Formato valido legacy invariato; la permissivita su frammenti malformati non
  e piu supportata. Limiti e politica timestamp in [08](08-security-permissions.md).

## Recupero dei metadati

`metadataRecoveryProvider` possiede tre `CoalescingRefresh`, uno per dominio.

1. Startup installa listener delle credenziali indipendenti dal prompt notifiche.
2. Cambio chiave RAWG accoda giochi; cambio credenziale TMDB accoda film.
3. Import accoda tutti i domini; apertura librerie film/giochi ritenta placeholder.
4. Ogni passaggio attende credenziali, controlla chiave effettiva e mantiene una
   subscription al servizio/client corrente.
5. Una generazione credenziale arresta il lavoro ormai obsoleto; il passaggio
   successivo acquisisce il nuovo client.

### Contratti film/giochi

- Senza chiave effettiva nessuna richiesta remota per quel dominio.
- Accettare soltanto titoli utili: scartare vuoti e placeholder equivalenti.
- Update con condizione ID locale + ID esterno + titolo ancora `Sconosciuto`.
- Non ricreare record rimossi durante il fetch e non sovrascrivere modifiche personali.
- Preservare stato, rating/note e `updatedAt` LWW.
- Giochi: piattaforme JSON, voto RAWG normalizzato su 10; rileggere playtime dopo
  la rete e riempirlo soltanto se ancora null, dentro la transazione finale.
- Errore: lasciare placeholder ritentabile; nessun retry automatico Riverpod.

### Hydration serie

Update condizionato a ID locale + TMDB ID + titolo ancora Sconosciuto. Non
ripristina record rimossi ne sovrascrive un titolo aggiornato durante la rete.
Per anime aggiorna metadati descrittivi, senza totali o coordinate episodio TMDB
grezze: attende la pipeline cour per quegli allineamenti. Preserva timestamp e
campi personali; test dedicati in hydration_safety_test.

## Sicurezza e limiti

- Token casuale di 16 byte e chiave AES casuale di 32 byte nel solo fragment QR.
  Contenuto LAN cifrato/autenticato; IP, token e metadati HTTP restano osservabili.
  Nessuna autenticazione reciproca: chi acquisisce il QR possiede la chiave.
- URL, redirect, token, dimensioni, decompressione, range e tipi sono limitati
  prima dell'import. Contratto autorevole e rischi residui in [08](08-security-permissions.md).
- Server è temporaneo e lo snapshot non si aggiorna a ogni mutazione successiva.
- Socket/IP/camera/connettività reali richiedono prova manuale su due dispositivi.

La matrice di compatibilità, le garanzie AES-GCM e i limiti di identificazione
sono riassunti nell’[audit attivo](security-reliability-audit.md).
Comunicare il cambiamento con le [note release](github-release-notes.md).

## Test pertinenti

`test/features/sync/sync_codec_test.dart`, `sync_service_test.dart`,
`local_sync_server_test.dart`, `hydration_safety_test.dart`,
`metadata_recovery_test.dart`, `metadata_recovery_screen_test.dart`,
`sync_encryption_test.dart`, `encrypted_receiver_test.dart`,
`local_sync_lifecycle_test.dart`, `sync_security_test.dart`.
I test handler non aprono socket LAN; i test recovery usano confini simulati.

## Coordinatore e avanzamento progressivo (2026-11-18)

- `providers/sync_controller.dart` possiede la sessione; `SyncProgressHost`, montato
  nel builder di MaterialApp, lascia utilizzabili tutte le route. Scanner e pagina
  non possiedono più gli await di ricezione/importazione. Una nuova scansione
  durante un lavoro attivo condivide il lavoro corrente.
- Fasi: preparazione indeterminata (rete/decifratura/validazione), importazione
  locale, arricchimento, esito finale. Il totale è la somma delle identità distinte
  dominio+ID del payload; stagioni, episodi e retry non aumentano il totale.
- `SyncSessions` e `SyncItems` (schema 15) sono checkpoint, non una seconda libreria.
  Import e registrazione avvengono nella stessa transazione. Al commit le librerie
  ricevono i placeholder tramite gli stream Drift, prima dei fetch dei metadati.
- Stati elemento: pending, running, completed, failed, removed. Il riepilogo separa
  completati e non completati; una rimozione concorrente non è ritentata e non
  ricrea il record. Alla ricreazione del coordinatore running diventa failed.
- Due elementi vengono arricchiti contemporaneamente. Titolo/poster sono pubblicati
  prima di mapping/conteggi/calendario. Film/giochi già titolati non richiedono rete.
  Una serie si completa solo dopo pipeline valida, syncMetadata e preparazione
  della stagione/cour necessaria al feed se applicabile. Poster remoti e altre
  stagioni restano lazy. Snapshot locali o cour stale non certificano successo.
- Il dettaglio serie grezzo è condiviso; AniList resta nella coda esistente.
  Le richieste film/giochi contemporanee sullo stesso servizio/ID condividono la
  Future in-flight, senza introdurre cache di risposte completate.
- Il SHA-256 del JSON ordinato identifica replay della stessa sessione senza
  conservare QR/token/chiave LAN. Il retry lavora sui soli elementi incompleti;
  le serie fallite invalidano in modo mirato i dettagli durante il retry.
  Nuovi snapshot creano una sessione; quelle precedenti incomplete sono accessibili
  dal pannello tramite «Riprendi trasferimenti precedenti».
- Il cambio credenziali riaccoda anche le serie; una generazione per servizio
  impedisce commit da client obsoleti. Credenziali TMDB assenti o errori producono
  elementi non completati, senza retry globali Riverpod o loop AniList esterni.
  La chiave RAWG assente segue il percorso differito descritto sotto.
- I cour v2 non sono inseriti usando numeri sorgente: i progressi ricevuti restano
  nel checkpoint e vengono uniti ai visti locali solo dopo una corrispondenza
  univoca con AniList ID. Cour divisi/ambigui o senza ID restano ritentabili;
  nessun fallback su stagioni TMDB. Le coordinate legacy conservano il contratto
  precedente e non possono provare identità cour fra mapping diversi.
- Se esistono progressi cour sospesi per serie ancora presenti, l'export è fermato
  con un messaggio esplicito: generare un QR incompleto perderebbe quei progressi.
- La barra misura elementi elaborati (completati o non completati), il testo
  mantiene il contatore dei successi. «Sincronizzazione completata» richiede tutti
  gli elementi elaborati senza errori e gli eventuali avvisi confermati. I giochi
  differiti sono salvataggi riusciti dell’elenco, con dettagli da completare.
- Errori prima del commit richiedono un nuovo QR se il mittente non è più
  disponibile. Dopo il commit il retry usa solo ID/dati persistiti, senza LAN.

Notifica e lifetime Android: [11](11-android-integrations.md). Prove automatiche:
`sync_controller_test.dart`, `sync_progress_panel_test.dart`,
`sync_android_bridge_test.dart`, oltre alle regressioni preesistenti.

## Giochi senza chiave e conferma dell'avviso

La mancanza di una chiave RAWG effettiva (incluso il fallback dart-define) non è un
errore: i placeholder già importati restano nel DB e i dettagli vengono saltati.
I job `deferred` sono contati come elaborati per questo trasferimento, separati dai
successi di hydration e dai fallimenti. Gli altri domini continuano normalmente.
Il banner sostituisce la barra con l'avviso «Configura la chiave API per completare
i tuoi giochi» e il testo che conferma il salvataggio dell'elenco. Solo «Ho capito»
conferma la lettura: chiusura, navigazione e fine delle richieste non lo fanno.
La conferma persiste nel job (`deferred_ack`), senza cambiare lo schema v15.
Se i dettagli vengono recuperati prima della conferma, gli esiti `*_notice`
conservano l'avviso fino alla lettura. La conferma è globale per gli avvisi già
presenti; un nuovo trasferimento può richiedere un nuovo avviso. Non cancella job
né dati personali. I titoli restano soltanto dati interni e non sono esposti nel
pannello o nella notifica di avanzamento.
Al cambio chiave RAWG lo stesso coordinatore riprende i dettagli differiti di tutte
le sessioni, anche se l'ultima era già conclusa. Rimangono attivi controllo della
generazione credenziale, update condizionato, conservazione dei timestamp e divieto
di ricreare record rimossi. Nessun nuovo worker o polling viene introdotto.

## Contatore dei passaggi di recupero

Il primo trasferimento conta insieme serie, film e giochi del QR. Ogni successivo
retry fissa un insieme di lavoro separato, composto soltanto da elementi ancora da
elaborare: i successi precedenti non entrano nel denominatore. Se contiene solo
giochi, pannello e notifica mostrano «Aggiornamento giochi» e «N/T giochi aggiornati».
L'insieme degli ID del passaggio resta fisso; il coordinatore tiene separati gli
elementi ancora da elaborare dai checkpoint precedenti. Un gioco prima differito
non è già completato nel nuovo passaggio mentre ne vengono recuperati i dettagli.
Il contatore quindi parte da zero e cresce, senza alternare 53/54 e 54/54.
I giochi differiti/falliti di altre sessioni vengono accodati nello stesso passaggio
automatico, senza pubblicare completamenti intermedi. Identità duplicate dello
stesso record locale condividono un lavoro; l'esito viene propagato ai checkpoint
corrispondenti mantenendo gli eventuali avvisi non letti. Non vengono ripetuti
l'import o le richieste per i contenuti già completati.
«Ho capito» conferma soltanto l'avviso: non completa l'eventuale ultimo elemento
ancora in lavorazione. La UI mantiene visibile l'ambito del totale e segnala
«Ultimo elemento in corso…» durante quell'attesa, senza mostrare fasi o titoli.
