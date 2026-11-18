# Architettura

## Ambito e versioni

ShowTracker è un'app Android local-first per serie TV/anime, film e videogiochi.
Non esiste un backend dedicato. Shelf espone temporaneamente dati dal dispositivo
durante la [sync LAN](10-p2p-sync.md). Non esiste un progetto applicativo iOS;
la cartella iOS di `third_party/home_widget/` appartiene alla dipendenza.

| Riferimento | Valore nel repository |
| --- | --- |
| Versione app | `1.2.0+8` in `pubspec.yaml` |
| Flutter di riferimento | `3.47.6` nella CI e in `.dart_tool/version` locale |
| Dart documentato per tale SDK | `3.13.5` nel README e nella guida test |
| Vincolo Dart dichiarato | `>=3.3.0 <4.0.0` in `pubspec.yaml` |
| Vincoli risolti del lockfile | Dart `>=3.12.0 <4.0.0`, Flutter `>=3.44.0` |
| Android | compile/target SDK 36, minSdk delegato a Flutter, Java 17 |
| Build Android | Gradle 9.1.0, AGP 9.0.1, Kotlin 2.3.20 con built-in Kotlin |

Il minimo dichiarato nel manifest Dart non dimostra che le dipendenze attuali
funzionino su Dart 3.3. Per setup e upgrade usare [06](06-development-rules.md).

## Struttura e responsabilità

```text
lib/
├── main.dart                    # bootstrap nativo e container globale
├── app.dart                     # MaterialApp.router
├── core/
│   ├── auth/                    # stati credenziali persistiti
│   ├── constants/               # chiavi compile-time e helper endpoint
│   ├── database/                # schema, tabelle, DAO e provider DB
│   ├── network/                 # interceptor HTTP
│   ├── router/ e shell/         # route e tab
│   ├── services/                # startup, notifiche, coalescing e toast
│   ├── theme/ e widgets/        # stile e componenti condivisi
│   ├── paged_search.dart        # motore di paginazione
│   └── riverpod_utils.dart      # retry e letture async mantenute vive
├── features/
│   ├── series/ movies/ games/   # domini dei contenuti
│   ├── search/                 # ricerca e discovery trasversali
│   ├── onboarding/ settings/   # accesso, chiavi, Profilo e privacy
│   ├── sync/                   # protocollo LAN e recupero metadati
│   ├── update/                 # GitHub Releases e installer APK
│   └── debug/                  # schermata disponibile solo in debug
└── widgets_manager.dart         # snapshot e pubblicazione widget Android
```

- Pattern feature-first; i domini principali seguono `data/ → providers/ → presentation/`.
- Non imporre una struttura uniforme inesistente: sync usa anche `services/`,
  `utils/` e `domain/models/`; alcune feature hanno solo presentazione.
- Non esiste un livello Repository comune: provider coordinano servizi e DAO.
- `lib/models/`, `lib/services/`, `lib/shared/` sono placeholder: non inserirvi codice nuovo.
- Il servizio TMDB condiviso risiede sotto `features/series/data/` ed è usato anche dai film.

## Dipendenze principali

| Ruolo | Pacchetti |
| --- | --- |
| Stato / generazione | `flutter_riverpod` 3, `riverpod_annotation` 4, `riverpod_generator` 4 |
| DB | `drift`, `drift_flutter`, `sqlite3` transitivo, `drift_dev` |
| Navigazione | `go_router` 14 |
| Rete / immagini / video | `http`, `cached_network_image`, `octo_image`, `video_player` |
| Credenziali / link | `flutter_secure_storage`, `app_links`, `url_launcher` |
| Notifiche / widget | `flutter_local_notifications`, `timezone`, `flutter_timezone`, `home_widget` locale |
| Sync | `shelf`, `shelf_router`, `network_info_plus`, `qr_flutter`, `mobile_scanner` |
| Update | `package_info_plus`, `ota_update` ufficiale con installer APK Android |

Le versioni esatte appartengono a `pubspec.lock`; evitare di copiarne l'intero
contenuto nella documentazione. La patch `home_widget` è in [third_party](../third_party/README.md).

## Flussi dati

```text
Lettura personale: UI → provider → DAO.watch* → SQLite → stream → UI
Scrittura:         UI → notifier → DAO/transazione → SQLite → stream → UI
Metadati:          provider → servizio HTTP → modello → cache/record locale
Anime:             TMDB + Yuna + AniList → merger → cour persistiti → UI
Widget Android:    provider condivisi → snapshot Dart → home_widget → Kotlin
```

- Le mutazioni persistite tornano alla UI dagli stream DB, senza mantenere una
  seconda libreria autorevole in memoria.
- Non tutte le risposte remote sono salvate integralmente. Offline significa
  accesso a dati persistiti, non equivalenza con ogni dettaglio online.
- Non introdurre fallback di numerazione anime nel livello UI: vedere [09](09-anime-pipeline.md).

## Bootstrap e proprietà delle risorse

Fonti: `lib/main.dart`, `lib/core/services/startup_coordinator.dart`,
`lib/core/database/database_provider.dart`.

1. Inizializzare Flutter e notifiche/timezone prima di `runApp`.
2. Creare il container globale con `retry: noProviderRetry`.
3. Passarlo a `UncontrolledProviderScope`; avviare `StartupCoordinator` dopo il primo frame.
4. Installare il coordinatore recupero metadati senza attendere il prompt notifiche.
5. Avviare setup widget e manutenzione in parallelo; i listener widget attendono auth.
6. Avviare una sola scansione metadata/notifiche dopo prompt e autenticazione.

Il provider DB registra `db.close` sul dispose. Non disporre il container globale
mentre l'app è attiva. Container di test/background hanno un ciclo di vita distinto.

## Verifiche pertinenti

- `test/widget_test.dart`: montaggio app con harness.
- `test/core/startup_coordinator_test.dart`: avvio idempotente e coordinamento auth/permessi.
- `test/features/series/pipeline_coordination_test.dart`: condivisione richieste e scansioni.
- `test/widgets_manager_test.dart`: coalescing e pubblicazione tramite confini simulati.
