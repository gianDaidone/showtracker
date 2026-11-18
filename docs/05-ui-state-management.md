# Stato, navigazione e UI

## Riverpod 3: regole operative

Fonti: `lib/core/riverpod_utils.dart`, `lib/features/*/providers/`, `lib/main.dart`.

- Stato condiviso in Riverpod; `setState` resta ammesso per stato locale del widget.
- Ogni nuovo `ProviderContainer`/`ProviderScope` deve ricevere `retry: noProviderRetry`.
- Servizi annotati con `@riverpod`; provider generici di paginazione scritti a mano.
- `TrackedShowsNotifier`, `TrackedMoviesNotifier`, `TrackedGamesNotifier`,
  `AuthController`, `RawgAuthController` sono `keepAlive`: non rimuoverlo senza
  riprogettare le operazioni async in corso.
- I notifier delle librerie scrivono nei DAO e restituiscono stream in `build()`.
  Non aggiornare una copia parallela della lista come fonte autorevole.
- Un provider autoDispose letto con `read(p.future)` senza listener può essere
  eliminato durante un await. Per letture imperative usare `readFuture` su Ref
  o container; per servizi sincroni mantenerne una subscription quando necessario.
- Nei provider, verificare `ref.mounted` prima di usare ref/state dopo lavoro
  asincrono suscettibile di disposal. Non confonderlo con `context.mounted`.
- In Riverpod 3 i listener dei widget invisibili nell'IndexedStack possono
  essere sospesi: il lavoro globale non deve dipendere da una tab nascosta.
- Non usare `.valueOrNull`: il codice usa `.value`.
- Provider generati: il suffisso `Notifier` sparisce dal nome, ad esempio
  `TrackedShowsNotifier` → `trackedShowsProvider`.
- `StateProvider` è nel pacchetto `flutter_riverpod/legacy.dart`;
  `ProviderListenable` in `flutter_riverpod/misc.dart`.

## Provider che definiscono contratti condivisi

| Provider / coordinatore | Responsabilità |
| --- | --- |
| `trackedShowsProvider`, `trackedMoviesProvider`, `trackedGamesProvider` | Librerie reattive DB |
| `rawShowDetailProvider`, `showDetailProvider`, `seasonDetailProvider` | Dettaglio grezzo, arricchito e stagione/cour |
| `animeDataProvider`, `redistributedAnimeEpisodesProvider` | Mapping normalizzato e fetch condiviso episodi anime |
| `allSeasonEpisodeCountsProvider` | Stream condiviso conteggi; family come proiezioni |
| `visibleWatchingShowsProvider` | Lista e conteggio Da Vedere, osservando anche cache |
| `upcomingEpisodesProvider` | Episodi in uscita, anche per widget |
| `showDiscoverProvider`, `movieDiscoverProvider`, `gameDiscoverProvider` | Liste discovery per `DiscoverList` |
| `metadataRecoveryProvider` | Lavoro app-level per placeholder sync, separato dalla pagina QR |

Il file centrale per serie è `lib/features/series/providers/series_providers.dart`:
leggerlo prima di modificare serie, notifiche o numerazione.

## Navigazione

Fonti: `lib/core/router/app_router.dart`, `lib/core/shell/main_shell.dart`.

| Branch | Route | Tab |
| --- | --- | --- |
| 0 | `/series` | Serie, `NextEpisodesScreen`; query `tab` |
| 1 | `/movies` | Film |
| 2 | `/games` | Giochi, voce condizionata da `kEnableGames` |
| 3 | `/settings` | Profilo |
| 4 | `/search` | Ricerca nella shell, senza voce nella barra; query `filter` |
| 5 | `/debug` | Solo debug |

- `StatefulShellRoute.indexedStack` conserva lo stato delle sezioni.
- Indici hardcoded in `MainShell`: cambiare router e tab insieme.
- Il branch giochi esiste nel router anche quando si nasconde la voce navbar.
  Il flag non costituisce da solo una protezione della route.
- La ricerca mantiene evidenziata l'ultima sezione visitata.
- Route fuori shell: `/onboarding`, `/series/list`, `/series/detail/:id`,
  `/movies/list`, `/movies/detail/:id`, `/games/list`, `/games/search`,
  `/games/detail/:id`, `/sync`, `/privacy`.
- Il redirect aspetta il caricamento auth; non autenticato → onboarding;
  autenticato su onboarding → serie. `/` è ricondotto a `/series`.
- `appRouterProvider` mantiene una sola istanza di `GoRouter`: un listener auth
  aggiorna i redirect tramite `refreshListenable` quando cambia l'accesso
  (autenticato/non autenticato), senza ricreare lo stack o
  completare le future delle route aperte. Router e notifier di refresh vengono
  disposti dal provider alla chiusura del container proprietario.
- Il redirect del router valida gli ID dei dettagli come interi positivi int32
  prima dei builder, che usano `int.parse`; ID non validi tornano a `/series`.
  Gli indici del tab episodi sono limitati all’intervallo 0–1.

## Gerarchia UI e stile

```text
ShowTrackerApp → MaterialApp.router → GoRouter
  ├── MainShell → StatefulNavigationShell → schermata della sezione
  └── schermate full-screen / dettaglio
```

- Tema unico: `AppTheme.dark()` in `lib/core/theme/app_theme.dart`.
- Material 3; `AppColors.background` #161622, surface #1E1E2E, accent #E68A00.
- Nuovi testi utente italiani; mantenere etichette per dominio e mesi italiani.
  Label metadati anime come `Winter 2026` sono un comportamento esistente del modello.
- Componenti riutilizzabili: `lib/core/widgets/` e
  `lib/features/settings/presentation/widgets/settings_widgets.dart`.
- Riutilizzare `AppToast`, `AnimatedRefreshButton` e `PagedListFooter` dove pertinenti.
- Layout usa vincoli locali, `LayoutBuilder`, `MediaQuery` e SafeArea; non esiste
  un sistema globale di breakpoint tablet/desktop. Non promettere supporto non verificato.
- Verificare tastiera, inset inferiori, testo ingrandito e onboarding scorrevole.

## Liste e immagini

- Stagioni: `SeasonSection` è un gruppo sliver con lista lazy. Non sostituire
  con Column di tutti gli episodi o ListView shrink-wrapped annidata.
- Conservare key show/cour e `findChildIndexCallback` dei feed: rimozioni e
  riordini non devono ricreare lo State delle card superstiti.
- `MediaImage` in `lib/core/widgets/media_image.dart` limita decode secondo
  layout, DPR e aspect ratio, anche con `imageBuilder`.
- Conservare uguaglianza/hash di `MediaImageProvider` e risoluzione sincrona
  delle chiavi sorgenti: evitarne la regressione che riavvia placeholder/fade.
- Solo host/path TMDB noti scelgono varianti CDN; per RAWG non riscrivere URL arbitrari.
- Zoom fullscreen resta intenzionalmente non limitato dal budget dei thumbnail.
- Non aggiungere retention illimitata o tagli globali a ImageCache senza profiling.

Test: `test/core/router/app_router_test.dart`, `test/core/media_image_test.dart`,
`test/features/series/presentation/{feed_identity,season_virtualization}_test.dart`.
