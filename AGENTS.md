# AGENTS.md

Istruzioni per gli assistenti che lavorano in ShowTracker. Leggere prima
[docs/README.md](docs/README.md) e selezionare le guide pertinenti al task.
Il codice è la fonte di verità; aggiornare la documentazione insieme ai contratti modificati.

## Contesto e mappa

App Flutter Android local-first per serie/anime, film e giochi. Stato Riverpod 3,
SQLite/Drift schema v14, GoRouter. Nessun backend dedicato: Shelf è temporaneo
sul dispositivo per sync LAN. Codice feature-first in `lib/features/`;
`lib/core/` ospita infrastruttura condivisa. Non aggiungere codice ai placeholder
`lib/models/`, `lib/services/`, `lib/shared/`.

| Intervento | Documenti da leggere |
| --- | --- |
| Architettura e avvio | [01](docs/01-architecture.md) |
| Funzionalità e regole episodio | [02](docs/02-functional-specs.md), [09](docs/09-anime-pipeline.md) |
| Schema, DAO, cache | [03](docs/03-data-local-storage.md) |
| API, auth e rete | [04](docs/04-services-api.md), [08](docs/08-security-permissions.md) |
| Provider, routing, UI e immagini | [05](docs/05-ui-state-management.md), [07](docs/07-clean-code-best-practices.md) |
| Setup, codegen, test e release | [06](docs/06-development-rules.md), [test/README.md](test/README.md) |
| Sync e recupero placeholder | [10](docs/10-p2p-sync.md) |
| Notifiche, widget home e update | [11](docs/11-android-integrations.md) |
| Misure e profiling | [Audit storico](docs/performance-audit.md) |

## Vincoli obbligatori

- UI italiana, Material 3, solo `AppTheme.dark()` e colori `AppColors`.
- Ogni container/scope Riverpod usa `retry: noProviderRetry`.
- Per letture imperative async di autoDispose usare `readFuture` o mantenere
  una subscription. Non usare ref/state dopo dispose. Conservare keepAlive dei
  notifier globali e auth.
- Non disporre il container globale di produzione: i widget ne dipendono e il
  provider DB chiude il singleton al dispose.
- Non editare `*.g.dart` e `*.drift.dart`: rigenerare dopo modifiche annotate.
- Non alterare l'ordine codegen Drift/Riverpod in `build.yaml` senza gestire la
  risoluzione dei tipi generati.
- Prima di cambiare serie leggere `lib/features/series/providers/series_providers.dart`.
- Autorità unica Da Vedere: `visibleWatchingShowsProvider`; regole condivise in
  `lib/features/series/data/watch_next_rules.dart`, anche per card e widget.
- Cour anime e stagioni TMDB non sono coordinate intercambiabili. Senza mapping
  non introdurre fallback grezzi in seasonDetail o syncMetadata.
- Refresh scade cache cour/episodi, senza eliminare l'unico fallback stale.
  Upsert cour sulla chiave naturale; pruning soltanto dopo download completo riuscito.
- Snapshot `isLocalSnapshot` non autorizzano sync metadata, scheduling o correzione
  dei totali. HTTP 401/403/404 non sono successi offline.
- AniList passa da `AniListService` e dalla sua `AniListQueue`; niente richieste
  parallele fuori coda né retry globali che aggirino la policy.
- Conservare transazioni progressi/timestamp, query bulk, stagioni lazy in sliver,
  key stabili e budget immagini `MediaImage`.
- Indici branch router e tab MainShell vanno aggiornati insieme.
- Chiavi solo in secure storage o dart-define: niente segreti nel sorgente/log/fixture.
- Hydration film/giochi preserva dati personali e timestamp; arrestare client
  obsoleti al cambio credenziali, non ricreare record rimossi.
- Controllo aggiornamenti soltanto su tap, mai all'avvio/in background.
- Mantenere patch locale home_widget: [third_party/README.md](third_party/README.md).
- Usare `debugPrint`, non `print`; `scratch*.dart` e `db.sqlite` sono artefatti locali.
- Test su DB in memoria e confini simulati; non installare/disinstallare runner
  con l'identità Android dell'app personale.

## Comandi essenziali

```powershell
flutter pub get
flutter run --dart-define-from-file=dart_defines/dev.json
dart run build_runner build
flutter analyze --no-pub
flutter test --no-pub
```

Il file dart-define locale si prepara da `dart_defines/dev.example.json`.
Su Windows eseguire comandi Flutter serialmente. Per dettagli su SDK, release,
firma, dipendenze native e test consultare le guide, senza dedurli da commenti obsoleti.
