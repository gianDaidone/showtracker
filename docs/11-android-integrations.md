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

- `InstallPermission.isGranted` tratta `MissingPluginException` come true:
  non è una verifica nativa riuscita su piattaforma senza canale.
- `requestViaSettings` possiede un `AppLifecycleListener`, lo elimina in finally
  e attende il ritorno prima di ricontrollare.
- Gestire eventi e cancellazione download in `update_dialogs.dart`; non affidarsi
  al solo `PERMISSION_NOT_GRANTED_ERROR` del plugin per il controllo preventivo.
- Pubblicazione: stessa firma, versione e build number crescenti; attenzione al
  fallback firma debug nel build script. Procedura in [06](06-development-rules.md).

## Verifiche e limiti

- Automatizzate: `test/core/startup_coordinator_test.dart`,
  `test/core/notification_body_test.dart`, `test/widgets_manager_test.dart`,
  `test/native_widget_metadata_test.dart`, `test/features/update/`.
- Prove native manuali: ricezione con app chiusa, reboot/permessi, tap widget,
  anteprime launcher, browser/deep link, QR/IP LAN, impostazioni installer e APK firmato.
- Usare dispositivo di test o identità separata; non installare/disinstallare
  runner con applicationId dell'app personale.
- Checklist estesa e limiti copertura: [test/README.md](../test/README.md).
