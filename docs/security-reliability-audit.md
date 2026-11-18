# Sicurezza e affidabilità — APK GitHub

Stato del **2026-11-17**. Un solo percorso Android, APK GitHub e OTA su tap.
Questo report descrive le protezioni e le verifiche tecniche. Procedura
operativa e registro delle prove hanno documenti separati, senza duplicare gli esiti nativi.
Documenti operativi: [checklist GitHub](github-release-checklist.md),
[prove native](native-release-validation.md), [privacy/servizi](privacy-and-services.md).

## Miglioramenti conservati

| Area | Correzioni ed evidenze conservate | Limiti residui |
| --- | --- | --- |
| QR/LAN | IPv4 privato letterale, endpoint/porta/token validati, niente redirect/DNS, sessione 5 min e stop sicuro anche durante bind; AES-GCM | Due dispositivi reali non provati; QR conferisce accesso, non identifica il peer |
| Input e dati | Download ≤2 MiB+128 byte, decompressione ≤8 MiB, budget record/range/episodi, validazione completa prima della transazione e rollback | QR non è un backup completo; niente note/voti o tombstone |
| Auth/account | Request token correlato, monouso/TTL; generazioni e secure-storage serializzato; client obsoleti chiusi; logout locale prima della revoca remota | Browser/storage reali non provati; custom scheme intercettabile da altre app |
| Rete/log | HTTPS per API, redirect negati, deadline/abort e budget; host credenziali esatti; log senza query, token, body o eccezioni grezze | Immagini/player/SDK richiedono verifica traffico reale; non si promette cancellazione remota offline |
| Integrità anime | Hydration condizionale preserva dati personali/timestamp; non ricrea record rimossi; niente coordinate/totali TMDB grezzi senza mapping cour | Migrazioni coperte da fixture v12→14/v13→14; versioni precedenti solo se dimostrate realmente distribuite |
| Android | HomeWidgetBackgroundReceiver privato, backup/transfer esclusi, FileProvider OTA non esportato e limitato alla cartella installer | PendingIntent/widget e upgrade reali ancora da verificare |
| UX | Camera solo in scansione, dialog chiavi oscurati e monouso, route validate, testo 200%/keyboard senza overflow nei casi testati | TalkBack, contrasto sui contenuti e edge-to-edge reali ancora da provare |
| Dipendenze | Patch Guava mirata, cryptography 2.9.0; ultimo inventario OSV 324 coordinate senza avvisi; ELF/ZIP 64 bit compatibili staticamente con 16 KB | Inventario e assenza avvisi non provano assenza di vulnerabilità; runtime 16 KB non provato |


Schema v14, autorità Da Vedere, AniListQueue, stale/offline, sliver/bulk/budget
immagini, container globale e patch home_widget sono preservati.
I pulsanti con logo RAWG sono stati rimossi su richiesta; restano i crediti testuali.

## Distribuzione APK e protezioni Android

MainActivity e FileProvider sono nel source set comune. L’app usa ota_update
ufficiale 7.1.0 e mantiene REQUEST_INSTALL_PACKAGES; i permessi di storage e il
privilegio di installazione di sistema non necessari sono rimossi dal Manifest.
Dettagli autorevoli in [integrazioni Android](11-android-integrations.md#permessi-fileprovider-e-installer).
applicationId/namespace, autorità del provider e receiver widget restano stabili;
la firma release è obbligatoria senza fallback debug. La CI compila l’APK debug
e conserva i controlli Manifest/DEX/ELF, senza deploy.

Il solo chiamante applicativo di fetchLatest rimane AppUpdateTile._checkForUpdates,
collegato a onTap. Nessun controllo all’avvio, al resume o in background.
Il checksum atteso non viene passato al plugin: la fiducia resta in GitHub/HTTPS
e nella verifica Android del pacchetto e della firma, senza promettere un hash
release applicativo non implementato.

## Problemi corretti ed evidenze dell’audit precedente

| ID | Severità tecnica / priorità | File e posizione, evidenza | Correzione e verifica / rischio residuo |
| --- | --- | --- | --- |
| LAN-1 | Alta / alta | `sync_screen.dart`, ricezione HTTP: URL arbitrari, redirect automatici e buffer senza limite | `SyncReceiver.read/validateSyncUri`: solo IPv4 RFC1918 letterale, /sync:8080, token unico, niente DNS/redirect, deadline e budget 2 MiB+128 byte per envelope; test ostili con client simulato |
| LAN-2 | Alta / alta | `SyncCompressor.decompressPayload` e `RangeUtils.expandRangeToList`: zlib/range espandibili senza budget | Decompressione incrementale ≤8 MiB, range/coordinate/media/episodi limitati e validazione dell'intero documento prima dell'import; test bomba zlib, range enormi, tipi/ID/timestamp ostili e rollback DB |
| LAN-3 | Media / alta | `LocalSyncServer.start/createSyncHandler`: bind tutte interfacce, durata indefinita, logRequests con query/token e CORS wildcard | Bind solo IP privato selezionato, token 128 bit/TTL 5 min, stop/generation guard, no-store e niente log token/CORS/browser; test handler, TTL e stop durante risoluzione IP/bind. LAN v2 AES-256-GCM con chiave nel solo QR, tag verificato prima della decompressione, token come AAD; test chiave/token/nonce/tag/ciphertext alterati e assenza chiave dalla richiesta. IP/token/metadati restano visibili; QR da condividere solo con destinatari fidati |
| AUTH-1 | Alta / alta | `OnboardingScreen._handleAuthRedirect`: qualsiasi token approvato poteva essere scambiato senza tentativo locale correlato | `TmdbLoginAttempt`: token locale monouso, 10 min, controllo URI/query/approvazione, cancellazione a cambio metodo/dispose; test estraneo, replay, scadenza, diniego e sostituzione. Custom scheme ancora intercettabile da altre app: App Links richiederebbero un dominio controllato |
| AUTH-2 | Alta / alta | `AppInterceptor`: BaseClient.close ereditato non chiudeva `_inner`; auth iniettata senza verifica HTTPS/redirect | Chiusura reale e rifiuto client obsoleti, HTTPS/443 e no redirect; conservato abortTrigger nel clone. Test closure, URI insicure, timeout/abort e recovery credenziali |
| AUTH-3 | Media / alta | AuthController/RawgAuthController: scritture concorrenti potevano pubblicare stato obsoleto; logout UI attendeva remoto e poi riusava WidgetRef | Scritture serializzate/generation guard, client invalidati durante mutazione; logout locale prima della revoca remota, riferimenti catturati prima degli await. Test login/login/logout e ultima chiave RAWG |
| NET-1 | Media / alta | TMDB/RAWG/Steam/AniList/Yuna senza budget uniforme o cancellazione delle risposte | apiRequest: HTTPS, no redirect, deadline con abort, limite 4 MiB; widget immagini 8 MiB/10 s. Retry AniList soltanto in AniListQueue, Retry-After rispettato integralmente entro 60 s, altrimenti fallback senza retry; test servizi e confini |
| LOG-1 | Media / alta | Body TMDB e eccezioni grezze nei log/UI potevano contenere URL/query/token o contenuti remoti | Log soltanto status/tipo, nessun body TMDB; errori UI generici, errori trasporto API redatti e chiavi oscurate nei form. Test dialog: errore privo del segreto e una sola operazione in volo |
| AND-1 | Alta / alta | Manifest: HomeWidgetBackgroundReceiver pubblico senza permesso, callback applicativo potenzialmente mutante | Receiver privato; PendingIntent upstream esplicito e immutable preservato. Verificatore artefatti esteso a componenti esportati. Test reale del PendingIntent ancora NON ESEGUITO |
| AND-2 | Media / media | Backup/transfer non esplicitamente esclusi; HTTP abilitato globalmente | Regole backup legacy/cloud/device transfer esplicite; NSC blocca HTTP dei fornitori noti, confine LAN applicativo conservato. Non è una whitelist CIDR nativa né cifratura SQLite |
| PRIV-1 | Alta / bloccante dichiarazioni | PrivacyInfoScreen prometteva privacy assoluta e assenza di attività inviate; SDK ML Kit/trasporto Google presente | UI corretta, flussi e bozza informativa includono cataloghi, consigli, immagini/video e diagnostica SDK. Titolare/URL/ruoli/retention da completare dal proprietario |
| DATA-1 | Alta / alta | Hydration serie scriveva per solo ID locale e poteva salvare totali/coordinate TMDB per anime | Guard ID+TMDB+placeholder, niente totali/puntatore grezzo anime, campi personali/timestamp preservati; test risposta tardiva, modifica/rimozione concorrente e anime |
| DATA-2 | Alta / alta | addShow anime senza mapping poteva inserire stagioni TMDB grezze | Totali ignoti e nessuna riga stagione grezza finché manca mapping; test aggiunta senza AniList e normale percorso cour, senza cambiare autorità Da Vedere/regole episodi |
| DEP-1 | Moderata secondo produttore / media | OSV su 313 coordinate Pub/Maven: Guava Android 33.3.1 e GHSA-xxph-c9ww-hj94 | Constraint mirato 33.7.2-android, nessun upgrade generale. Non individuata deserializzazione Java di input remoto nell'app; versione affetta non prova sfruttabilità. Risoluzione finale 33.7.2-android e R8/build verificati; 324 coordinate OSV, zero avvisi restituiti |
| UX-1 | Media / media | Testo 200%/display 320 px riproducevano overflow in skeleton, stato vuoto e barra principale; form RAWG senza scroll | Header flessibile, stato vuoto/form scorrevoli, altezza barra calcolata sul testo senza cap allo scaling, semantica tab selezionato; test con testo ingrandito e tastiera |
| UX-2 | Media / media | Export QR montava scanner con autoStart e la key dialog ignorava errori/salvataggi concorrenti | Camera avviata solo in scansione e fermata su cambio tab/background; test export senza start nativo. Dialog chiavi con controller disposed, errori redatti e salvataggio singolo. Rifiuto/revoca OS ancora da provare |
| UX-3 | Bassa / media | Route ID/tab non validi potevano causare parse/assert; splash nativo chiaro | ID validati e tab clamp, backlink RAWG accessibili, dark splash/background coerenti e label ShowTracker; test route ostili. Edge-to-edge/TalkBack/launcher nativi NON ESEGUITI |


## Verifica della sync cifrata

`SyncEncryption` usa AES-256-GCM del package cryptography, senza implementare
un cipher proprietario. Ogni export genera una nuova chiave casuale da 32 byte
e un nonce casuale da 12 byte; una sola cifratura per chiave. Ripetere il download
serve lo stesso ciphertext, non ricifra messaggi diversi con lo stesso nonce.
Il nonce non deve essere segreto; il tag da 16 byte autentica il contenuto e
l’AAD lega il token alla versione ShowTracker/sync/v2.
Controllato il sorgente risolto di cryptography 2.9.0: newSecretKey/newNonce
usano il generatore sicuro predefinito; l’app non imposta seed, Random alternativo
o un’istanza Cryptography di test in produzione. Il test confronta chiavi e nonce
di due export, senza presentarlo come prova matematica di unicità globale:
non viene riutilizzata una chiave per cifrare un secondo messaggio.

La chiave è nel fragment #k= del QR: il ricevitore chiama removeFragment prima
di costruire la richiesta. Non viene inviata in HTTP, scritta in SQLite/secure
storage o nei log. Le copie in memoria Dart non hanno una garanzia di azzeramento
forense. Il tag è verificato prima di decompressione, parsing e import atomico.
Chiave, token, nonce, ciphertext o tag alterati non autorizzano un import.

| Mittente → ricevitore | Comportamento |
| --- | --- |
| LAN v2 → v2 | Envelope STSYNC2:, autenticazione GCM e validazione prima dell’import |
| Vecchia LAN → nuovo ricevitore | URL senza chiave rifiutato prima della rete; messaggio italiano: aggiornare entrambi |
| Risposta plaintext/versione sconosciuta → nuovo ricevitore | Rifiutata; nessun downgrade, messaggio italiano invita ad aggiornare entrambi e generare nuovo QR |
| Nuova LAN → vecchia app | Il vecchio decoder non comprende STSYNC2: e fallisce prima dell’import; il testo della vecchia app non è modificabile retroattivamente. Verifica statica del vecchio flusso, prova nativa ancora necessaria |
| QR diretto legacy → app aggiornata | JSON/zlib/base64 ancora leggibile, entro i limiti e la validazione attuali. Nessuna richiesta LAN; non è cifrato e chi vede il QR può leggerlo |

AES-GCM protegge riservatezza e integrità del contenuto rispetto a chi non
possiede il QR. **Non è autenticazione reciproca dei dispositivi.** IP, token e
metadati HTTP restano osservabili, il QR va condiviso con destinatari fidati e
un replay valido durante la sessione è gestito da LWW/unione idempotente.
Nessun fallback automatico al protocollo LAN non cifrato.


## Verifiche storiche associate all’APK elencato

| Controllo | Esito |
| --- | --- |
| flutter pub get --offline | Riuscito; ota_update 7.1.0 ufficiale, nessun upgrade generale |
| flutter analyze --no-pub | Nessun problema; build/single-apk-analyze.log |
| flutter test --no-pub --coverage --test-randomize-ordering-seed=20261029 | 446 test superati sullo stato finale, nessuna selezione canale; build/single-apk-full-tests.log |
| flutter build apk --release --no-pub | Riuscito, 83,9 MB; build/single-apk-release-build.log |
| python tool/verify_apk.py build/app/outputs/flutter-apk/app-release.apk | PASS: applicationId, provider, permessi, widget, componenti esportati e canali OTA nel DEX; build/single-apk-manifest.log |
| Verificatore, casi negativi | Rifiuta provider pubblico, permesso installazione mancante e privilegio di sistema |
| apksigner verify e confronto certificato | PASS: firma valida, non debug, stesso certificato dell’APK GitHub pubblicato v1.2.0; build/audit/single-apk-signature.json |
| python tool/audit_native_libraries.py APK | PASS su tutte le librerie 64 bit, senza hazard RELRO; inventario 21 librerie/3 ABI in build/audit/single-apk-native-libraries.json |
| zipalign -c -P 16 4 APK | PASS; build/single-apk-zipalign.log |
| Versione/identità | 1.2.0+8, com.example.showtracker e firma invariati; nessun override versione durante la build finale |
| Fonte preservata | 96 file di sync/auth/rete/database/serie/home_widget identici in byte allo snapshot prima della pulizia; nessun file generato modificato |
| Entry point/IDE/script/docs | MainActivity comune, configurazione IDE esistente con solo dart-define, nessun riferimento operativo al canale rimosso; collegamenti relativi verificati |
| git diff --check e file nuovi | Superato; cache Gradle e bytecode Python ignorati con regole mirate, senza cancellazioni |
| CI remota / prove Android della nuova build | NON ESEGUITE: nessun upload o installazione richiesti |

APK finale: `build/app/outputs/flutter-apk/app-release.apk`.
SHA-256: `b77be395c6278218a2eac8bddf9497c5af326988747b78f2ea940997dbc266de`.
Certificato SHA-256: `5bda3b35b8d6d375ee466137267fa1d2bec566fb3d76a8693456f75921301cf1`.
Il riferimento precedente è l’APK archiviato con hash uguale all’asset pubblico
GitHub, non una deduzione basata sul fatto che la firma non sia debug.
La versione identica a quella pubblicata non costituisce una nuova release OTA:
la pulizia conserva il numero richiesto, senza pubblicare né cambiare il progetto.

Durante il ritorno all’upstream il merger ha inizialmente inferito
READ_EXTERNAL_STORAGE dalla richiesta WRITE del plugin. Corretto nel Manifest
comune con tools:node=remove anche per READ; il verificatore rifiuta la build
intermedia e passa sull’APK finale privo di entrambi i permessi di storage.
La suite completa associata a quell’APK è stata eseguita dopo la correzione del Manifest.


Nessun provider annotato/schema modificato dalla pulizia: codegen non necessario.
La versione in pubspec rimane 1.2.0+8. Build di verifica senza chiavi API personali;
nessuna installazione sull’app personale, pubblicazione, commit, push o upload.

### Ultima modifica mirata ai sorgenti

Retry-After AniList oltre budget o non interpretabile termina con il fallback
esistente, senza accorciare l’attesa e senza modificare AniListQueue; dettagli in
[servizi API](04-services-api.md#errori-timeout-e-retry). Il testo RAWG dell’onboarding
è stato semplificato mantenendo il collegamento alla documentazione.
Analisi statica senza problemi e **22 test mirati superati**: AniListService,
AniListQueue, ingresso/accessibilità e dialog privacy/chiavi. Le regressioni
Retry-After usano tempo simulato, compresi valori oltre 60 s, invalidi e il
limite esatto di 60 s. Log in build/final-targeted-cleanup-analyze.log e
build/final-targeted-cleanup-tests.log. Collegamenti documentali, file nuovi
e git diff --check verificati. Nessun codegen necessario.
Prima dei commit è stata rieseguita anche la suite completa sullo stato
aggiornato: **454 test superati**, log build/precommit-full-tests.log.
Non è stato ricompilato l’APK per questa modifica: l’hash e le prove della tabella
precedente riguardano la build storica, non certificano i sorgenti aggiornati.

## Prove native e limiti

Il [registro nativo](native-release-validation.md#registro-delle-prove) conserva
le build, il confronto dei certificati, la sola prova debug eseguita e tutti i
casi ancora mancanti. I test host e i mock non certificano comportamento Android.

Privacy, licenze, attribuzioni e condizioni API sono conservate in
[privacy/servizi](privacy-and-services.md) e [chiarimento AniList](anilist-terms-clarification.md).
Il proprietario ha dichiarato uso personale: nessuna attività legale o di
pubblicazione è in corso. Il report non inventa autorizzazioni o esenzioni.
