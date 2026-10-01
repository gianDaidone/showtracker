# ShowTracker

App Android per tenere traccia di **serie TV, film, anime e videogiochi**, scritta in Flutter.

È *local-first*: tutto quello che segni (episodi visti, liste, stati) resta in un database
SQLite sul telefono. I servizi esterni forniscono solo i metadati (copertine, trame, date di
uscita) e non ricevono nessun dato sulle tue visioni.

## Funzionalità

- **Serie TV** — stagioni ed episodi visti, lista "Da Vedere" con il prossimo episodio,
  schermata "In Uscita" con le date dei nuovi episodi.
- **Anime** — episodi, cour e orari di uscita precisi presi da AniList, anche quando TMDB
  raggruppa più cour in una sola stagione.
- **Film** e **Videogiochi** — liste per stato: da vedere, in visione, in pausa, completato,
  abbandonato (per i giochi: backlog, in gioco, giocato…).
- **Notifiche** all'uscita di un nuovo episodio (per gli anime all'orario reale di messa in onda).
- **Widget per la home** di Android: "Prossimamente" e "Maratona".
- **Sincronizzazione tra due dispositivi** sulla stessa rete Wi-Fi tramite QR code, senza server.
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

Requisiti: Flutter 3.41+ (Dart 3.10+), Android SDK 36, Java 17.

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
flutter analyze                                                  # analisi statica
flutter test                                                     # test
flutter pub run build_runner build --delete-conflicting-outputs  # rigenera Riverpod/Drift (*.g.dart)
```

### Struttura

Il codice è in `lib/features/` (`series`, `movies`, `games`, `search`, `settings`,
`onboarding`, `sync`, `update`), ognuna divisa in `data/` → `providers/` → `presentation/`.
Stato con Riverpod, database con Drift, navigazione con GoRouter. Più dettagli in
[CLAUDE.md](CLAUDE.md).

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
