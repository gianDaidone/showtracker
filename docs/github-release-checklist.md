# Checklist release GitHub / APK

Documento operativo principale insieme all’[audit](security-reliability-audit.md).
Obiettivo: APK GitHub, OTA solo su tap, un unico percorso Android. Nessuna pubblicazione autorizzata
da questa checklist; i passi esterni richiedono una richiesta esplicita.

Esiti e limiti delle verifiche storiche, incluse firme e conservazione dati:
[registro nativo](native-release-validation.md#registro-delle-prove). Una prova
debug non certifica il percorso OTA release.

## Configurazione e comandi canonici

PowerShell, dalla root; eseguire Flutter serialmente. SDK attuale Flutter 3.47.6,
Dart 3.13.5, Android SDK 36, Java 17. Preparare i JSON locali dal solo esempio
tracciato; sostituire i placeholder prima dell’uso. Non copiarvi token personali
per i test e non includere le configurazioni reali nel repository.

```powershell
flutter pub get
# Solo la prima volta, se i file non esistono:
if (-not (Test-Path dart_defines/dev.json)) {
    Copy-Item dart_defines/dev.example.json dart_defines/dev.json
}
if (-not (Test-Path dart_defines/release.json)) {
    Copy-Item dart_defines/dev.example.json dart_defines/release.json
}

# Sviluppo GitHub (chiavi di sviluppo autorizzate nel JSON locale):
flutter run --dart-define-from-file=dart_defines/dev.json

# Release GitHub (chiavi applicative appropriate nel JSON locale):
flutter build apk --release --dart-define-from-file=dart_defines/release.json

python tool/verify_apk.py build/app/outputs/flutter-apk/app-release.apk
python tool/audit_native_libraries.py build/app/outputs/flutter-apk/app-release.apk --output build/audit/native-libraries.json
Get-FileHash build/app/outputs/flutter-apk/app-release.apk -Algorithm SHA256
```

Senza fallback API si può omettere --dart-define-from-file: resta l’inserimento
manuale TMDB/RAWG, mentre il login browser TMDB richiede una chiave applicativa.
I JSON dev/release sono ignorati da Git; non esistono flag per scegliere un canale.
L’output canonico è **build/app/outputs/flutter-apk/app-release.apk**.
L’artefatto distribuibile è l’APK firmato; non serve alcuna configurazione store.

## Prima di candidare l’APK

- [ ] Decidere una nuova versione e build number in pubspec.yaml, superiori alla
  precedente release distribuita. Il confronto OTA usa major/minor/patch: alzare
  soltanto +build non fa apparire un aggiornamento nell’app.
- [ ] Tag GitHub vX.Y.Z coerente con versionName; per la release stabile usare
  un unico APK corretto, perché il parser sceglie il primo asset .apk.
- [ ] Conservare com.example.showtracker, nomi widget, autorità provider e firma
  delle installazioni storiche. Nessun applicationIdSuffix. Mai disinstallare per
  far passare l’upgrade o usare una chiave diversa.
- [ ] Firma release da android/key.properties/keystore esistenti e custoditi con
  backup sicuro. Nessun fallback debug; non esporre password o valori nei log.
- [ ] Verificare certificato dell’APK candidata e confronto con APK storico
  attendibile tramite apksigner; nessuna catena di fiducia deriva dal solo nome file.
- [ ] Chiavi/API/diritti appropriati: AniList chiarito prima della distribuzione
  pubblica; confermare piani TMDB/RAWG ed eventuale uso commerciale.
- [ ] Completare contatto/informazioni privacy pertinenti e rendere disponibile
  l’informativa approvata, senza placeholder: [bozza](privacy-and-services.md).
- [ ] Includere le [note di aggiornamento](github-release-notes.md), soprattutto
  l’obbligo di aggiornare entrambi i peer LAN e la compatibilità dei QR diretti.

## Verifiche tecniche

- [ ] Dopo modifiche di codice: analyze e test pertinenti secondo docs/06 e
  test/README.md. Per una nuova candidata che cambia altro codice, suite completa
  `flutter test --no-pub`; non ripetere automaticamente una
  suite già valida per modifiche soltanto documentali.
- [ ] Rigenerare provider/schema solo se necessario; non modificare file generati.
- [ ] Ispezionare l’APK esatto: REQUEST_INSTALL_PACKAGES, provider non esportato,
  grant URI e area files/ota_update, identità widget; conservare hash e log.
- [ ] Controllare ELF/ZIP per i dispositivi supportati; runtime 16 KB secondo la
  procedura nativa, per compatibilità con i dispositivi supportati.
- [ ] `git diff --check`; nessun segreto/cache/artefatto incluso per errore.

## Prove Android isolate — stato aggiornato dopo il consolidamento

Il [registro nativo](native-release-validation.md#registro-delle-prove) distingue
la prova debug eseguita dai casi release, LAN e integrazioni ancora mancanti.

Procedura di isolamento, dati sintetici e registrazione degli esiti:
[validazione nativa](native-release-validation.md). Non usare account o DB
personali; non installare runner con l’identità dell’app personale.

| Ordine | Prova prioritaria | Atteso |
| --- | --- | --- |
| 1 | OTA: N09/N12, versione iniziale firmata → candidata più recente | Nessuna rete senza tap; conferma, permesso negato/resume, download/annullamento e installer; libreria, credenziali e widget conservati senza disinstallazione |
| 2 | LAN: N04/N05, due peer aggiornati e coppia vecchia/nuova | Payload cifrato, chiave assente in HTTP, alterazioni rifiutate; incompatibilità fallisce senza scritture/perdita dati; QR diretto legacy ancora importabile |
| 3 | Auth: N02/N03 | Browser→app, replay/token inatteso/diniego, cambio credenziali durante rete e logout offline; nessuna sessione/risposta obsoleta |
| 4 | Notifiche/widget: N07/N08 | App chiusa/reboot/permessi revocati, launcher/tap e PendingIntent legittimo funzionanti; broadcast esterno negato |
| 5 | Offline: N01/N10 | Cold start con rete assente, dati locali e stale leggibili, nessun falso successo 401/403/404 o perdita progressi |
| 6 | Accessibilità/API 36/16 KB: N06/N13–N16 | Camera solo in scansione, tastiera/gesture/TalkBack, nessun errore linker/SQLite/scanner; misure solo se realmente effettuate |

Per OTA end-to-end usare un asset già disponibile e compatibile se esiste; non
pubblicare un asset di prova senza richiesta. Se manca, registrare il blocco.
Il codice storico può mostrare un errore generico per la nuova LAN: non è possibile
cambiarlo retroattivamente; la nota release deve invitare ad aggiornare entrambi.

## Dopo una futura autorizzazione alla pubblicazione

- [ ] Gate sopra risolti e log/prove associati all’hash esatto della candidata.
- [ ] Release GitHub non draft/non prerelease, tag coerente, note e solo asset
  APK previsto; pubblicare soltanto su richiesta esplicita.
- [ ] Da una versione precedente di test: Profilo → Cerca aggiornamenti trova
  la release e procede solo dopo conferma. Non introdurre check automatici.

Versione e firma si verificano sull’APK esatto. Questa checklist non esegue pubblicazioni.
