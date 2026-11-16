# ShowTracker

App Android per tenere traccia di **serie TV, film, anime e videogiochi**, scritta in Flutter.

È *local-first*: tutto quello che segni (episodi visti, liste, stati) resta in un database
SQLite sul telefono. I servizi esterni forniscono metadati (copertine, trame, date di
uscita); l'app non vi sincronizza i progressi personali. I consigli usano gli ID dei
titoli seme per richiedere raccomandazioni.

## Funzionalità

- **Serie TV** — stagioni ed episodi visti, lista "Da Vedere" con il prossimo episodio,
  schermata "In Uscita" con le date dei nuovi episodi.
- **Anime** — episodi, cour e orari di uscita precisi presi da AniList, anche quando TMDB
  raggruppa più cour in una sola stagione.
- **Film** — da vedere, completati o abbandonati; **Videogiochi** — backlog, in gioco,
  in pausa, giocati o abbandonati.
- **Notifiche** programmate per l'uscita di un nuovo episodio, usando per gli anime
  l'orario AniList; la consegna effettiva dipende dalla pianificazione Android.
- **Widget per la home** di Android: "Da Vedere" e "In Uscita" (componenti Maratona/Prossimamente).
- **Sincronizzazione tra due dispositivi** sulla stessa rete Wi-Fi tramite QR code,
  senza backend esterno, con un server temporaneo sul dispositivo mittente.
- **Aggiornamento in-app**: dal tab Profilo, "Cerca aggiornamenti" scarica e installa l'ultima
  release pubblicata su GitHub.
- Interfaccia in italiano, solo tema scuro.

## Installazione

Scarica l'APK dall'ultima [release](../../releases/latest) e aprilo sul telefono (Android ti
chiederà di consentire l'installazione da questa fonte).

Al primo avvio colleghi il tuo account TMDB, oppure inserisci una tua API key TMDB. Per i
videogiochi serve una API key [RAWG](https://rawg.io/apidocs) (facoltativa).

Gli aggiornamenti successivi si installano direttamente dall'app: **Profilo → Cerca
aggiornamenti**.

## Sviluppo

SDK verificato e usato in CI: Flutter 3.47.6 (Dart 3.13.5). Servono inoltre Android SDK 36 e Java 17.

```bash
flutter pub get
flutter run
```

### API key

Le chiavi non sono nel repository. Per il login TMDB via browser, e come fallback quando
l'utente non ha inserito una chiave sua, l'app usa chiavi passate in fase di build:

```bash
cp dart_defines/dev.example.json dart_defines/dev.json   # poi inserisci le tue chiavi
flutter run --dart-define-from-file=dart_defines/dev.json
```

`dart_defines/dev.json` è nel `.gitignore`. Tieni presente che le chiavi passate con
`--dart-define` finiscono comunque dentro l'APK: considera pubblica qualsiasi chiave distribuita
agli utenti.

### Comandi utili

```bash
flutter analyze --no-pub                 # analisi statica
flutter test --no-pub                    # test unitari, provider e widget
flutter test --no-pub --coverage         # report coverage/lcov.info
# Rigenera Riverpod (*.g.dart) e Drift (*.drift.dart)
dart run build_runner build
```

### Test

I test unitari, provider e widget girano sul computer, senza installare o
disinstallare l'app su emulatori/dispositivi. Usano database SQLite in memoria,
credenziali fittizie e HTTP simulato: non servono API key e non toccano la libreria
personale. La CI esegue analisi e suite con ordine randomizzato e seed fisso a ogni push/PR,
salvando la coverage come artefatto.

Non sono previsti test automatici su Android. Prima delle release, le funzioni
native (notifiche, widget home, login nel browser, sync e installer) si verificano
manualmente su un dispositivo di test. Comandi mirati, aree coperte, convenzioni
per le fixture e checklist manuale sono in [test/README.md](test/README.md).

### Struttura

Il codice è in `lib/features/` (`series`, `movies`, `games`, `search`, `settings`,
`onboarding`, `sync`, `update`, `debug`). I domini principali seguono
`data/` → `providers/` → `presentation/`; le altre feature adattano i livelli alle proprie responsabilità.
Stato con Riverpod, database con Drift, navigazione con GoRouter.

### Documentazione tecnica e assistenti IA

Partire da [docs/README.md](docs/README.md): l'indice associa ogni tipo di task
alle guide su architettura, dati, API, UI, anime, sync e integrazioni Android.
Le regole essenziali per gli assistenti sono in [AGENTS.md](AGENTS.md).
I test hanno una [guida dedicata](test/README.md); misure e profiling precedenti
sono conservati nell'[audit prestazionale](docs/performance-audit.md).

## Pubblicare una nuova versione

1. In `pubspec.yaml` alza **sia** la versione **sia** il numero di build, es. `1.0.0+1` → `1.0.1+2`.
   L'app confronta la versione; Android rifiuta un aggiornamento con numero di build non superiore.
2. Compila firmando sempre con la stessa chiave (`android/key.properties`, non versionato):
   ```bash
   flutter build apk --release --dart-define-from-file=dart_defines/dev.json
   ```
3. Crea su GitHub una release **non** in bozza e **non** pre-release, con tag `v1.0.1`, le note di
   rilascio nella descrizione e allegato `build/app/outputs/flutter-apk/app-release.apk`.

Chi ha l'app installata la troverà con "Cerca aggiornamenti".

## Crediti

- Dati di film e serie da [TMDB](https://www.themoviedb.org/). *This product uses the TMDB API
  but is not endorsed or certified by TMDB.*
- Dati dei videogiochi da [RAWG](https://rawg.io/).
- Dati degli anime da [AniList](https://anilist.co/), collegati a TMDB tramite
  [Yuna](https://yuna.moe/).
