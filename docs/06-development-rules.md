# Regole di sviluppo

## Ambiente

- Usare come riferimento Flutter **3.47.6**; Dart documentato **3.13.5**.
  Verificare l'ambiente effettivo con `flutter --version` prima di un upgrade.
- Servono Android SDK 36 e Java 17; minSdk è delegato al tool Flutter.
- Conservare `pubspec.lock`: il minimo SDK risolto è più alto di quello dichiarato
  in `pubspec.yaml`. Versioni e struttura: [01](01-architecture.md).
- `android/local.properties`, `android/key.properties`, keystore e chiavi reali
  sono locali/ignorati; non copiarne valori nei documenti o log.

```powershell
flutter pub get
flutter run

# Per login browser TMDB e fallback applicativi: compilare il file locale.
Copy-Item dart_defines/dev.example.json dart_defines/dev.json
flutter run --dart-define-from-file=dart_defines/dev.json
```

`flutter run` senza chiavi applicative può usare una chiave TMDB manuale
dell'utente; il login browser necessita invece `ApiKeys.tmdb`.
Il flag giochi attuale è una costante `true`, non un dart-define.

## Code generation

```powershell
dart run build_runner build
dart run build_runner watch
```

- Non editare `*.g.dart` Riverpod o `*.drift.dart` Drift.
- Rigenerare dopo modifiche a provider annotati o schema/DAO che richiedono generazione.
- `build.yaml` esegue Drift in un target separato `drift`, con `not_shared`,
  prima di Riverpod. I tipi Drift devono essere risolvibili dal generatore provider.
- Le parti Drift usano `part 'nome.drift.dart'`; non convertirle al builder
  condiviso senza risolvere l'ordine di generazione.
- Non aggiungere `--delete-conflicting-outputs`: non serve al build_runner attuale.
- Se codegen fallisce visitando nuovi nodi SDK e poi resta inattivo, verificare
  compatibilità analyzer/generatori. Il lockfile attuale risolve analyzer 14.5.0;
  coordinare upgrade di `riverpod_generator`, `drift_dev`, `build_runner`.

## Android e dipendenze native

- Gradle 9.1.0, AGP 9.0.1, built-in Kotlin attivo; app senza plugin `kotlin-android`.
- `org.jetbrains.kotlin.android` in settings pinna una versione: non significa
  che l'app applichi KGP.
- Prima di aggiornare plugin verificare compatibilità con built-in Kotlin.
- `url_launcher_android` risolto 6.3.33; `network_info_plus` risolto 8.2.1.
  I vincoli di dipendenza vanno verificati con pub, non dedotti dal solo caret.
- `home_widget` è locale in `third_party/home_widget`; mantenere la patch
  documentata in [third_party/README.md](../third_party/README.md).
- `sqlite3` 3.x usa build hooks e binari nativi; il primo build può richiedere rete.
  Non reintrodurre `sqlite3_flutter_libs`, presente solo come stub transitivo EOL.
- Rigenerare anteprime widget con:

```powershell
powershell -NoProfile -File tool/generate_widget_previews.ps1
```

## Analisi e test

```powershell
flutter analyze --no-pub
flutter test --no-pub
flutter test --no-pub test/widget_test.dart --plain-name 'App smoke test'
flutter test --no-pub --coverage --test-randomize-ordering-seed=20261029
```

- Eseguire comandi Flutter serialmente su Windows per evitare lock SQLite.
- Se dipendenze cambiano, eseguire `flutter pub get` prima dei comandi `--no-pub`.
- Test unit/provider/widget sul computer: DB in memoria, HTTP/storage/canali
  simulati. Non installano l'app e non richiedono API key reali.
- Non ci sono test automatici Android attivi; `integration_test/` è vuota.
- Nuove regressioni devono verificare effetti osservabili, non copiare l'implementazione.
- Guida autorevole per fixture, teardown, copertura e limiti: [test/README.md](../test/README.md).
- CI `.github/workflows/test.yml`: Ubuntu, Flutter 3.47.6, pub get, analyze,
  suite randomizzata con seed fisso e artefatto coverage. Non compila l'APK e
  non applica una soglia coverage.
- Non trasferire i conteggi storici di [performance-audit.md](performance-audit.md)
  nel report di una verifica corrente senza rieseguire la suite.

## Convenzioni di modifica

- Nuovo codice sotto la feature pertinente o `lib/core/` quando condiviso.
- Naming Dart: file `snake_case`, tipi `UpperCamelCase`, membri `lowerCamelCase`;
  allinearsi alle convenzioni del file modificato.
- UI italiana e dark theme; commenti coerenti con la lingua circostante.
- Usare `debugPrint`, mai `print` applicativo: `avoid_print` è attivo.
- `analysis_options.yaml` include flutter_lints e regole aggiuntive const/super.
- Non introdurre chiavi in costanti tracciate o in fixture.
- `scratch*.dart` e `db.sqlite` alla root sono artefatti locali, non fonti applicative.

## Git e revisione

Il repository non codifica una policy completa su branch, messaggi commit o
merge. Convenzione operativa per lavoro Codex: prefisso `codex/` per nuovi branch,
salvo istruzioni diverse; non rinominare un branch esistente per uniformarlo.

- Controllare `git status --short` prima di editare; preservare modifiche altrui.
- Separare refactoring cosmetici dalle correzioni di comportamento.
- Aggiornare il documento principale del contratto modificato e relativi rimandi.
- Prima della consegna usare `git diff --check` e controllare anche file nuovi,
  non solo il diff dei file tracciati. Non includere cache Gradle locali.
- Non eseguire commit, push o pubblicazione se non richiesti.

## Release APK

1. Incrementare nome versione **e** build number in `pubspec.yaml`.
2. Compilare con le chiavi applicative appropriate e la stessa firma delle release precedenti.
3. Verificare la firma: il build script ripiega sulla chiave debug se manca
   `android/key.properties`. Una build riuscita non certifica una firma pubblicabile.
4. Creare release GitHub pubblicata, non draft/non prerelease, con tag parsabile
   e asset `.apk`.
5. Verificare su dispositivo di test i flussi nativi della checklist.

```powershell
flutter build apk --release --dart-define-from-file=dart_defines/dev.json
```

Output standard: `build/app/outputs/flutter-apk/app-release.apk`.
Non installare o disinstallare test runner sull'app personale; un DB in memoria
non isola il ciclo di installazione Android.
