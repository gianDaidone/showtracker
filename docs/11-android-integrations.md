# Integrazioni Android

## Notifiche e avvio

Fonti: `lib/core/services/notification_service.dart`,
`lib/core/services/startup_coordinator.dart`, `lib/main.dart`,
`lib/features/series/providers/series_providers.dart`.

- `NotificationService.init` inizializza database timezone, timezone dispositivo
  con fallback UTC se il nome non è riconosciuto, e plugin prima di `runApp`.
- Il prompt notifiche viene dopo il primo frame; non deve bloccare setup widget
  o installazione dei listener recovery metadati.
- `StartupCoordinator` possiede l'unico avvio della scansione completa dopo
  prompt e auth. Scansioni concorrenti condividono una Future in-flight.
- Scansione startup e notifiche provocate da aggiunta/stato/progresso sono flussi distinti.
- Serie regolari: orario di riferimento 09:00; anime: timestamp AniList quando
  disponibile. `useExactTime` conserva il timestamp, ma il plugin usa comunque
  `AndroidScheduleMode.inexact`: non garantisce consegna al secondo.
- ID notifica basato su TMDB ID; registro diagnostico in memoria valido solo
  nella sessione corrente, non inventario persistente delle notifiche OS.
- Ricevitori Manifest gestiscono notifiche pianificate e reboot/package replace.
- `_resolveNextEpisode` deve scavalcare il puntatore TMDB già trasmesso; snapshot
  locali parziali non devono rischedulare o cancellare puntatori validi.
- Test del testo e MethodChannel non provano consegna OS con app chiusa.

## Widget home: Dart → plugin → Kotlin

Fonti:

- `lib/widgets_manager.dart`.
- `android/app/src/main/java/com/example/showtracker/MaratonaWidgetProvider.kt`.
- `android/app/src/main/java/com/example/showtracker/ProssimamenteWidgetProvider.kt`.
- `android/app/src/main/res/layout/` e `res/xml/`.

| Componente stabile | Etichetta nel selettore | Dati |
| --- | --- | --- |
| `MaratonaWidgetProvider` | Da Vedere | Prossimo episodio da guardare |
| `ProssimamenteWidgetProvider` | In Uscita | Prossimi episodi annunciati |

- Non rinominare receiver per cambiare il testo visibile: le istanze launcher
  dipendono dall'identità del componente.
- Listener globali osservano `visibleWatchingShowsProvider` e
  `upcomingEpisodesProvider` dopo setup e ripristino auth.
- La preparazione usa provider/regole condivisi e `seasonDetailProvider` cour-aware.
  Non chiamare direttamente stagione TMDB grezza per un anime.
- Refresh coalescenti per container: una preparazione attiva, passaggio trailing
  se arrivano nuove richieste; Future completata dopo l'intero drain.
- Preparare snapshot prima di pubblicarlo. Commit nativi per chiave restano
  separati; serializzazione Dart non è un lock atomico tra isolate.
- Download immagine condiviso per URL, timeout 10 s, cache file nella directory
  documenti; nessun pruning globale. Gestire anche immagini assenti.
- Non disporre il container di produzione; il provider DB ne chiuderebbe il singleton.

### Interazione effettiva

- Kotlin attuale collega i controlli all'apertura dell'app.
- Dart salva un URI `homeWidget://mark_watched?id=...&s=...&e=...` e registra
  `backgroundCallback`; il controllo nativo attuale non usa quell'URI.
- Il callback, se invocato dal plugin, valida ID numerici, usa container breve
  con `noProviderRetry`, ripristina auth, marca episodio e attende drain prima
  del dispose. Questo non prova che il launcher esponga già l'azione.
- Non dichiarare verificato il callback reale con DB singleton sulla base dei mock.

### Anteprime nel selettore

- Metadata: `res/xml/widget_maratona_info.xml`, `widget_prossimamente_info.xml`.
- Android 12+: `previewLayout`; fallback launcher: PNG `previewImage`.
- Layout/artwork con dati demo statici, senza preferenze o poster remoti.
- Generazione: `tool/generate_widget_previews.ps1`.
- Modifiche native richiedono ricompilazione/aggiornamento APK; hot reload non basta.
  Alcuni launcher mantengono anteprime in cache.
- Test metadata: `test/native_widget_metadata_test.dart`; non misura rendering launcher.

## Deep link TMDB

- Manifest registra `showtracker://auth` su MainActivity.
- `app_links` è ascoltato dall'onboarding; flusso e credenziali in
  [08](08-security-permissions.md).
- Non dedurre dal solo intent-filter un supporto generale a ogni link esterno.
- Provare browser→app realmente: i test router non coprono il ritorno del browser.

## Aggiornamento APK

Fonti: `lib/features/update/`, `lib/core/constants.dart`,
`android/app/src/main/kotlin/com/example/showtracker/MainActivity.kt`.

Unica distribuzione APK GitHub: [checklist release](github-release-checklist.md).

1. Tap `AppUpdateTile` in Profilo avvia il controllo; nessun controllo automatico.
2. `GithubReleaseService` legge `releases/latest` per `kGithubRepo`, senza token
   TMDB/RAWG; timeout e mapping errori in [04](04-services-api.md).
3. `AppVersion` confronta major/minor/patch, ignorando prefisso `v` e build suffix.
4. Scegliere primo asset dal nome `.apk`, mostrare conferma/dettagli release.
5. Controllare permesso installazione prima del download; se necessario aprire
   impostazioni e ricontrollare al resume.
6. `ota_update` scarica e passa all'installer. La chiusura del dialog download
   non certifica installazione conclusa con successo.

| MethodChannel `showtracker/install_permission` | Risultato |
| --- | --- |
| `canRequestPackageInstalls` | Su Android 8+ legge packageManager; versioni precedenti true |
| `openInstallSettings` | Apre `ACTION_MANAGE_UNKNOWN_APP_SOURCES` del package; false se non applicabile/non disponibile |

- `InstallPermission.isGranted` restituisce false quando manca il canale nativo; non presume un permesso concesso.
- `requestViaSettings` possiede un `AppLifecycleListener`, lo elimina in finally
  e attende il ritorno prima di ricontrollare.
- Gestire eventi e cancellazione download in `update_dialogs.dart`; non affidarsi
  al solo `PERMISSION_NOT_GRANTED_ERROR` del plugin per il controllo preventivo.
- Pubblicazione: stessa firma, versione e build number crescenti; nessun fallback
  firma debug. Procedura in [06](06-development-rules.md).

### Permessi, FileProvider e installer

L’app usa ota_update ufficiale 7.1.0. Il Manifest comune mantiene
REQUEST_INSTALL_PACKAGES; prima del download MainActivity/InstallPermission
verificano il consenso Android e lo ricontrollano al ritorno dalle impostazioni.
Non è prevista installazione silenziosa.

Il FileProvider sk.fourq.otaupdate.OtaUpdateFileProvider è non esportato, concede
accesso tramite URI e conserva l’autorità com.example.showtracker.ota_update_provider.
La risorsa android/app/src/main/res/xml/filepaths.xml espone soltanto la cartella
interna files/ota_update usata dal plugin, non l’intero storage applicativo.

INSTALL_PACKAGES, WRITE_EXTERNAL_STORAGE e READ_EXTERNAL_STORAGE sono esclusi
con tools:node=remove nel Manifest dell’app: l’installer normale non richiede
privilegi di sistema né storage esterno. Il merger può inferire READ dalla
dichiarazione WRITE del plugin; anche questo permesso viene quindi rimosso
esplicitamente, come verificato nel Manifest impacchettato.
Il controllo APK e la CI verificano permessi, provider, canali OTA e componenti;
la presenza di un evento INSTALLING non dimostra che Android abbia concluso
l’aggiornamento. Servono le [prove native](native-release-validation.md).

## Verifiche e limiti

- Automatizzate: `test/core/startup_coordinator_test.dart`,
  `test/core/notification_body_test.dart`, `test/widgets_manager_test.dart`,
  `test/native_widget_metadata_test.dart`, `test/features/update/`.
- Prove native manuali: ricezione con app chiusa, reboot/permessi, tap widget,
  anteprime launcher, browser/deep link, QR/IP LAN, impostazioni installer e APK firmato.
- Usare dispositivo di test o identità separata; non installare/disinstallare
  runner con applicationId dell'app personale.
- Checklist estesa e limiti copertura: [test/README.md](../test/README.md).

## Sincronizzazione QR in background

`SyncForegroundService.kt` espone il solo lavoro dataSync, avviato dalla scansione
mentre l'app è visibile. `SyncRuntime` collega il bridge allo stesso FlutterEngine
conservato da MainActivity: non avvia un secondo isolate/container/DB o coda AniList.
Non è WorkManager e non viene riavviato al boot (START_NOT_STICKY).
La notifica usa il canale sync_progress a importanza bassa e ID negativo -17841,
separato dagli ID positivi TMDB. Lo snapshot è quello del pannello Dart; scritture
serializzate e limitate a una al secondo, esito finale immediato. Il tap riapre il
pannello se il lavoro o un avviso sono ancora attivi. POST_NOTIFICATIONS/canale negati non bloccano il lavoro; Android può
mostrare solo il gestore attività, senza notifica nel drawer.
Il servizio possiede wake lock limitato e watchdog di dieci minuti, gestisce anche
onTimeout Android 15+, poi si ferma. I dati già commessi restano disponibili.
Home/cambio app/schermo spento sono supportati dal lifetime del servizio e motore;
non equivalgono a force-stop, morte processo o riavvio. In questi ultimi casi i
checkpoint vengono recuperati alla successiva apertura; non è promessa esecuzione
continua o ripartenza automatica. I retry da ripristino auth non avviano FGS dal
background: la continuazione protetta richiede scansione o retry manuale in app.
Build APK e test MethodChannel non provano il runtime su Android/OEM: verificare
schermo spento, recenti, force-stop, timeout, credenziali e permessi su device
isolato. Il server mittente continua ad avere TTL cinque minuti/dispose pagina.

L'avvio nativo risponde al bridge soltanto dopo la promozione effettiva a FGS.
Se il sistema rifiuta il servizio, l'import può proseguire in foreground con una
notifica ordinaria quando consentita. La sola lettura del checkpoint all'avvio
non ripubblica notifiche. Dopo un timeout la notifica finale può aggiornarsi senza
riavviare il servizio. `tool/verify_apk.py` controlla anche tipo, visibilità,
stopWithTask e permessi del servizio nel Manifest dell'APK effettivo.

La notifica sync ora usa soltanto il contatore generale, senza titoli o fasi
interne. Un avviso RAWG non letto invita ad aprire l'app; se le operazioni sono
finite il FGS si ferma comunque, mentre l'icona in app resta fino a «Ho capito».
Confermare l'avviso non richiede una nuova connessione al peer LAN.

Il contatore della notifica usa lo stesso insieme fisso del passaggio visualizzato:
la ripresa dei soli giochi non riusa il totale del trasferimento misto. Non vengono
pubblicati esiti finali intermedi tra sessione corrente e giochi arretrati.
