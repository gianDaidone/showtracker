# Credenziali, permessi e protezione dei dati

Questo documento distingue le protezioni implementate dai limiti attuali.
Non contiene valori reali di chiavi, sessioni o firma.

## Credenziali

Fonti: `lib/core/auth/auth_state.dart`, `rawg_auth_state.dart`,
`lib/core/constants/api_keys.dart`, `lib/core/network/tmdb_http_client.dart`.

| Dato | Persistenza / origine |
| --- | --- |
| Sessione TMDB | `flutter_secure_storage`, chiave `tmdb_session_id` |
| Chiave TMDB manuale | Secure storage, `tmdb_manual_key` |
| Chiave RAWG manuale | Secure storage, `rawg_api_key` |
| Fallback applicativi | `String.fromEnvironment`: `TMDB_KEY`, `RAWG_KEY`; vuoti di default |
| Firma APK | File locale `android/key.properties` e keystore; non versionati |

- Ripristino TMDB: sessione non vuota prima della chiave manuale; errore storage
  → stato non autenticato. Login con una modalità elimina l'altra credenziale.
- RAWG ha uno stato indipendente, soltanto API-key.
- Chiave manuale ha precedenza sul fallback per le richieste del proprio servizio.
- Sessione TMDB necessita anche della chiave applicativa, non la sostituisce.
- Auth valida il ripristino locale, non verifica preventivamente ogni token col server.
- Mutazioni secure storage serializzate e generation guard: login/logout concorrenti
  non ripubblicano credenziali obsolete. Durante la mutazione lo stato e in loading.
- AppInterceptor.close chiude il client sottostante al cambio credenziali; nessun
  client obsoleto puo inviare nuove richieste dopo la chiusura.
- Non reintrodurre chiavi in `lib/core/constants.dart`, fixture o file tracciati.
- `dart_defines/dev.json` è ignorato; `dev.example.json` è il modello condiviso.
- I dart-define finiscono nel binario: una chiave distribuita in APK deve essere
  considerata estraibile. Non è implementato un proxy backend per custodirla.

## Login browser e logout

Fonti: `lib/features/onboarding/presentation/onboarding_screen.dart`,
`lib/features/settings/presentation/tmdb_account_section.dart`.

1. Ottenere request token TMDB usando `ApiKeys.tmdb`.
2. Aprire il browser su TMDB con redirect `showtracker://auth`.
3. Ascoltare `app_links`: accettare soltanto il token del tentativo locale attivo,
   monouso, entro 10 minuti, con scheme/host/path e query non ambigui.
   Callback estranei, duplicati, scaduti e replay non creano sessioni.
4. Creare sessione e persisterla con AuthController.

- Non descrivere questo flusso come OAuth/PKCE: usa le API sessioni TMDB.
- Il redirect usa un custom scheme; non sono configurati Android App Links HTTPS verificati.
- Il logout tenta la cancellazione remota della sessione e ripulisce lo storage
  locale anche se il trasporto fallisce. Non cancella la libreria SQLite.
- Il router rimanda all'onboarding dopo logout: i dati conservati non equivalgono
  a una navigazione anonima completa dell'app.

## Trasporto e log

- Interceptor soltanto per host esatti TMDB/RAWG: nessuna iniezione su GitHub,
  Steam, Yuna o AniList. Test: `test/core/network/tmdb_http_client_test.dart`.
- Le chiavi sono query parameter: i log applicativi registrano tipo errore/status,
  senza URL, payload o testo grezzo delle eccezioni. TMDB non stampa il body remoto.
- I servizi attivi usano apiRequest: HTTPS/443, niente redirect, risposta entro
  4 MiB, timeout con abort. AniList mantiene AniListQueue e i soli retry 429 interni.
  Le immagini widget hanno un budget distinto di 8 MiB e 10 secondi.
- `main.dart` silenzia `debugPrint` e output `print` della zona in release;
  non considerarlo una sostituzione della redazione nei log di sviluppo.
- Le API metadati non ricevono chiamate per sincronizzare progressi personali.
  Le richieste di raccomandazioni includono però gli ID dei titoli seme:
  non promettere assenza assoluta di informazioni desumibili dalla libreria.

## Dati locali

- DB in storage applicativo tramite Drift; nessuna cifratura SQLCipher o password
  DB configurata. Secure storage protegge credenziali, non l'intera libreria.
- Manifest app: `android:allowBackup="false"`, regole esplicite per backup legacy,
  cloud e device transfer. Non e cifratura del database.
- HTTP rimane abilitato per peer LAN dinamici; Network Security Config vieta
  HTTP per i domini noti dei fornitori. Le regole Android per domini non sono
  CIDR: non dichiarare una whitelist nativa completa delle sole reti private.
  Il confine ricevente applicativo limita gli endpoint LAN (vedi sotto).
- Il provider OTA non è esportato e concede accesso tramite URI; leggere
  `android/app/src/main/res/xml/filepaths.xml` per l'area esposta all'installer.
  Provider e installer sono parte dell’unica distribuzione APK.
- Cache immagini/file widget e dati DB hanno retention diverse; nessuna pulizia
  globale deve eliminare i fallback cour necessari ai progressi.

## Permessi e componenti Android

Fonte principale: `android/app/src/main/AndroidManifest.xml`.
I plugin possono contribuire ulteriori dichiarazioni: per un APK distribuibile
controllare anche il Manifest risultante dalla fusione.

| Permesso / componente | Uso e comportamento |
| --- | --- |
| `INTERNET` | API, immagini, sync LAN e download APK |
| `POST_NOTIFICATIONS` | Prompt post-frame tramite servizio notifiche |
| `RECEIVE_BOOT_COMPLETED` | Receiver plugin per ripristino notifiche |
| `REQUEST_INSTALL_PACKAGES` | Installer APK, controllo preventivo via MethodChannel |
| `READ_EXTERNAL_STORAGE`, `WRITE_EXTERNAL_STORAGE`, `INSTALL_PACKAGES` | Assenti: l'OTA usa storage interno e non richiede privilegi di sistema; rimozione anche del READ implicito introdotto dal merger upstream |
| Fotocamera / scanner | Plugin `mobile_scanner`; controllare dichiarazioni fuse e flusso runtime sul dispositivo |
| `MainActivity` esportata | Launcher e custom scheme auth |
| Receiver appwidget esportati | Aggiornamento widget Android |
| Receiver/service HomeWidget | Receiver `exported=false`; PendingIntent esplicito/immutable, service protetto da `BIND_JOB_SERVICE` |

- Non richiedere exact alarm sulla base del solo orario anime:
  lo scheduling attuale usa `AndroidScheduleMode.inexact`.
- Accesso Wi-Fi/IP dipende da plugin e versione Android; non documentare permessi
  aggiuntivi come già gestiti dall'app senza verificarne Manifest e runtime.
- Nessuna configurazione equivalente iOS dell'app è presente.

## Input QR e protocollo LAN

- Solo URL HTTP con IPv4 letterale RFC1918, porta 8080, path /sync, un unico
  token base64url di 22 caratteri e fragment k=chiave base64url di 43 caratteri;
  nessun DNS, loopback, IPv6 o userinfo. Fragment rimosso prima della richiesta HTTP.
- Niente redirect, massimo 2 MiB di payload base64 (+128 byte per envelope LAN), deadline 10 secondi e client
  chiuso anche in errore/timeout. Payload base64 diretto legacy ancora supportato.
- Decompressione incrementale limitata a 8 MiB prima di jsonDecode; errori generici
  privi del payload. Validazione completa prima delle scritture, anche per import
  programmatici; copia del payload per evitare mutazioni durante gli await.
- Massimo 10.000 media, 1.000 stagioni per serie, 20.000 episodi per range e
  100.000 episodi totali; coordinate fino a 1.000.000, ID positivi canonici int32.
- Timestamp wire interi non negativi e non oltre 24 ore nel futuro; stagioni
  speciali zero ammesse, episodi positivi. Input malformato rifiuta tutto.
- Server associato al solo IPv4 privato selezionato, token casuale di 16 byte,
  TTL cinque minuti e chiusura su dispose/stop. Generation guard chiude server
  completati dopo uno stop; timer chiude anche sessioni dimenticate in background.
- Handler senza logRequests/CORS wildcard, Cache-Control no-store, query/token
  duplicati e richieste con Origin rifiutati. Snapshot non aggiornato live.
- Fotocamera soltanto sulla scheda scansione, formati QR, stop in background e
  cambio scheda. Rifiuto del permesso mostrato in italiano; verifiche OS mancanti.
- LAN v2 usa AES-256-GCM standard (cryptography), chiave nuova per export nel
  solo QR, nonce casuale e token come AAD. Verifica del tag prima di decomprimere:
  chiave/token/ciphertext alterati sono rifiutati. Nessun fallback in chiaro.
  Entrambi i peer devono essere aggiornati, come approvato dal proprietario.
  IP/token/metadati HTTP restano visibili; il QR conferisce accesso al contenuto.
  Nessuna autenticazione reciproca o revoca di un QR diretto gia condiviso.

Test: sync_security_test, sync_codec_test, local_sync_server_test,
sync_service_test (incluso rollback su errore DB tardivo), sync_screen_privacy_test.
Un replay valido durante la sessione è gestito dal merge LWW/unione idempotente;
il tag GCM autentica lo snapshot ma non attribuisce un’identità al mittente. Prove LAN/fotocamera effettive in [procedura nativa](native-release-validation.md).

## Aggiornamenti e firma

- GitHub serve metadati release; il codice seleziona il primo asset con nome `.apk`.
- `OtaUpdate.execute` riceve URL e nome destinazione, senza checksum atteso
  applicativo. Gestire `CHECKSUM_ERROR` non prova che si verifichi un hash della release.
- L'installer Android verifica i requisiti di aggiornamento del pacchetto;
  mantenere stessa firma e build number crescente.
- La build release richiede la configurazione firma release, senza fallback debug.
- L’OTA GitHub parte soltanto su tap; Manifest e canali nativi si verificano
  sull’APK finale con tool/verify_apk.py. [Checklist](github-release-checklist.md).
- Flusso permessi e limiti delle prove native: [11](11-android-integrations.md).
