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
- Non reintrodurre chiavi in `lib/core/constants.dart`, fixture o file tracciati.
- `dart_defines/dev.json` è ignorato; `dev.example.json` è il modello condiviso.
- I dart-define finiscono nel binario: una chiave distribuita in APK deve essere
  considerata estraibile. Non è implementato un proxy backend per custodirla.

## Login browser e logout

Fonti: `lib/features/onboarding/presentation/onboarding_screen.dart`,
`lib/features/settings/presentation/tmdb_account_section.dart`.

1. Ottenere request token TMDB usando `ApiKeys.tmdb`.
2. Aprire il browser su TMDB con redirect `showtracker://auth`.
3. Ascoltare `app_links`; verificare scheme/host, approvazione e request token.
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
- Le chiavi sono query parameter: evitare log di URL completi o eccezioni
  che possano includerli. Il servizio TMDB logga path e risposta nei suoi errori HTTP.
- `main.dart` silenzia `debugPrint` e output `print` della zona in release;
  non considerarlo una sostituzione della redazione nei log di sviluppo.
- Le API metadati non ricevono chiamate per sincronizzare progressi personali.
  Le richieste di raccomandazioni includono però gli ID dei titoli seme:
  non promettere assenza assoluta di informazioni desumibili dalla libreria.

## Dati locali

- DB in storage applicativo tramite Drift; nessuna cifratura SQLCipher o password
  DB configurata. Secure storage protegge credenziali, non l'intera libreria.
- Manifest app: `android:allowBackup="false"`.
- `usesCleartextTraffic="true"` abilita HTTP a livello applicazione; il Manifest
  non lo restringe ai soli indirizzi LAN.
- Il provider OTA non è esportato e concede accesso tramite URI; leggere
  `android/app/src/main/res/xml/filepaths.xml` per l'area esposta all'installer.
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
| `REQUEST_INSTALL_PACKAGES` | Installer APK; controllo preventivo via MethodChannel |
| `WRITE_EXTERNAL_STORAGE`, maxSdk 28 | Dichiarazione limitata ai vecchi Android |
| Fotocamera / scanner | Plugin `mobile_scanner`; controllare dichiarazioni fuse e flusso runtime sul dispositivo |
| `MainActivity` esportata | Launcher e custom scheme auth |
| Receiver appwidget esportati | Aggiornamento widget Android |
| Receiver/service HomeWidget | Interattività plugin; service protetto da `BIND_JOB_SERVICE` |

- Non richiedere exact alarm sulla base del solo orario anime:
  lo scheduling attuale usa `AndroidScheduleMode.inexact`.
- Accesso Wi-Fi/IP dipende da plugin e versione Android; non documentare permessi
  aggiuntivi come già gestiti dall'app senza verificarne Manifest e runtime.
- Nessuna configurazione equivalente iOS dell'app è presente.

## Input QR e protocollo LAN: limiti attuali

Fonti: `lib/features/sync/presentation/sync_screen.dart`,
`services/local_sync_server.dart`, `utils/range_utils.dart`, `utils/sync_compressor.dart`.

- Server su tutte le interfacce IPv4, porta 8080; token casuale di 16 byte in URL.
- Token richiesto da `/sync`; diverso/mancante → 403. Non è cifratura del payload.
- Trasporto HTTP in chiaro; payload zlib+base64 è compressione/codifica.
- Il ricevitore scarica stringhe che iniziano con `http://`, altrimenti prova
  direttamente il payload legacy. Non applica una whitelist host LAN.
- Cast/parsing JSON e ID numerici filtrano alcuni input malformati, ma non
  esiste una validazione strutturale completa con limiti di dimensione.
- Espansione range e decompressione non hanno un limite esplicito di output.
- Il server usa `logRequests`: non assumere che il token query sia redatto nei
  log di debug della richiesta.
- Non descrivere la sync come end-to-end encrypted, autenticazione reciproca,
  backup completo o protocollo con firma/versionamento esplicito.

Eventuali interventi di hardening sono modifiche future al codice, non protezioni
già garantite da questi documenti. Conservare compatibilità e test del [protocollo](10-p2p-sync.md).

## Aggiornamenti e firma

- GitHub serve metadati release; il codice seleziona il primo asset con nome `.apk`.
- `OtaUpdate.execute` riceve URL e nome destinazione, senza checksum atteso
  applicativo. Gestire `CHECKSUM_ERROR` non prova che si verifichi un hash della release.
- L'installer Android verifica i requisiti di aggiornamento del pacchetto;
  mantenere stessa firma e build number crescente.
- La build release usa firma debug se il file chiavi manca: verificarla prima di pubblicare.
- Flusso permessi e limiti delle prove native: [11](11-android-integrations.md).
