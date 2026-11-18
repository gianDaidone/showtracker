# Procedura di verifica nativa isolata — GitHub

Priorità e gate correnti nella [checklist GitHub](github-release-checklist.md).
Usare l’unico APK dell’app. Le prove sono separate per confine nativo; non
riutilizzare automaticamente gli esiti storici per una nuova candidata.

## Stato delle verifiche (2026-11-17)

Le verifiche host comprendono analisi/test Flutter con DB in memoria, build APK,
Manifest, firma ed ELF/ZIP alignment. Non equivalgono a prove Android reali.
Il [registro sotto](#registro-delle-prove) conserva gli artefatti e l’unica prova
nativa eseguita: upgrade debug su Pixel_9 isolato. OTA release, LAN a due peer e
le altre prove restano NON ESEGUITI. Nessuna installazione o nuova prova nativa
è stata effettuata durante l’ultima pulizia mirata.

## Preparare l'ambiente

1. Creare **un nuovo AVD senza account personali**, chiamato
   `ShowTrackerAudit16k`, e un secondo ambiente pulito per LAN. Non riutilizzare
   l'emulatore dell'app personale. In Android Studio → SDK Manager → Show Package
   Details, scegliere l'immagine Google APIs Experimental 16 KB per Android 15 o
   successivo compatibile con l'host, poi creare l'AVD da quell'immagine.
   Se immagine/virtualizzazione non sono disponibili, registrare il blocco.
2. Per API 36/edge-to-edge affiancare un AVD Android 16 pulito. Per comportamento
   precedente ai permessi runtime notifiche usare un ambiente API 32 o inferiore
   isolato. Per LAN reale usare due dispositivi di test su Wi-Fi privata senza
   client isolation: l'emulatore NAT da solo non certifica due peer raggiungibili.
3. Avviare solo gli ambienti di audit e rilevare il seriale con `adb devices`.
   Non usare comandi senza `-s` quando c'è più di un target.
4. Eseguire il controllo di identità seguente **prima di ogni installazione**.
   Il nome dell'AVD è un controllo operativo, non una sandbox crittografica:
   deve essere quello appena creato e privo di dati personali.

```powershell
$auditSdk = "$env:LOCALAPPDATA/Android/Sdk"
$auditAdb = "$auditSdk/platform-tools/adb.exe"
& $auditAdb devices
$auditSerial = 'INSERIRE_SERIALE_DEL_NUOVO_AVD'
$auditAvd = (& $auditAdb -s $auditSerial emu avd name | Select-Object -First 1).Trim()
if ($auditAvd -ne 'ShowTrackerAudit16k') { throw 'Target non isolato: interrompere' }
$auditPageSize = (& $auditAdb -s $auditSerial shell getconf PAGE_SIZE).Trim()
if ($auditPageSize -ne '16384') { throw 'Il target non usa pagine da 16 KB' }
```

Nessun comando di questa procedura deve puntare a un dispositivo personale.
Non avviare `flutter test integration_test` con l'applicationId di produzione.
Usare l’APK su questo AVD esclusivamente come app in prova, senza runner.

## Preparare artefatti e dati di test

- Generare l’APK con i [comandi documentati](github-release-checklist.md), usare
  la firma prevista e verificare Manifest/ELF prima dell'installazione.
- Usare direttamente l’APK firmato. Per upgrade entrambi gli APK devono avere la stessa
  firma di test dedicata o la stessa firma release verificata, e versione/build
  strettamente crescenti. Non mescolare debug e release per dichiarare provata
  la continuità delle installazioni distribuite.
- Preparare dati sintetici: serie regolare, anime diviso in più cour, film, gioco,
  note e voti riconoscibili, progressi con buchi, date in passato/futuro. Salvare
  schermate/valori attesi prima dell'upgrade. Non copiare un database personale.
- Login browser/API reali richiedono risorse di test autorizzate dal proprietario.
  Al momento non sono disponibili: quei casi restano BLOCCATI, non saltati come
  successi. Per i soli flussi locali/offline si può inserire una chiave fittizia
  non valida e usare un payload QR sintetico, senza promettere metadata online.
- Per l'OTA end-to-end serve un APK già disponibile da una release GitHub,
  compatibile per firma e più recente della build di partenza. Se manca, non
  pubblicarlo per questa prova: registrare il blocco e verificare gli altri casi.

Esempio di avvio del solo target già verificato (APK debug, nessun runner):

```powershell
& $auditAdb -s $auditSerial install -r build/app/outputs/flutter-apk/app-debug.apk
& $auditAdb -s $auditSerial shell am start -n com.example.showtracker/.MainActivity
```

Non usare `pm clear`, `uninstall` o un reset dell'AVD per la prova di continuità:
prima installare la build iniziale sul nuovo AVD, inserire i dati sintetici,
poi `install -r` della candidata con firma compatibile e build maggiore.

## Matrice da eseguire e registrare

N09 è superata solo per i tre valori osservati nel percorso debug descritto nel
registro sotto; N09 release e le altre prove sono **NON ESEGUITE**. La numerazione conserva gli identificativi delle prove storiche. Compilare per ogni caso data,
seriale di test, API, ABI, PAGE_SIZE, tipo build, versione/build, SHA-256 artefatto,
passi, atteso/osservato, screenshot/log redatto e PASS/FAIL/BLOCCATO con motivo.

| ID | Passi e atteso concreto |
| --- | --- |
| N01 Avvio | Cold start online, poi offline e dopo kill processo: onboarding/loading comprensibili, nessun crash, libreria conservata |
| N02 Browser/auth | Login di test → browser → callback app. Ripetere callback consumato, token estraneo, diniego, nuovo tentativo e cambio a chiave manuale: nessuna sessione non sollecitata. Non salvare token nei log |
| N03 Credenziali | RAWG/TMDB: inserimento, riavvio, cambio account durante fetch, logout offline e storage revocato/indisponibile se riproducibile. Dati personali conservati; nessuna risposta obsoleta ripristina metadata/sessioni |
| N04 LAN | Due peer Wi-Fi privati: QR diretto e snapshot cifrato STSYNC2 via porta 8080 con entrambi i peer aggiornati, import valido, conflitti, reimport idempotente. Verificare stop uscendo e scadenza dopo 5 minuti. Verificare con cattura redatta che chiave e JSON non compaiano in HTTP. Non basta l'handler testato sull'host |
| N05 QR ostile | URL pubblico/loopback/IPv6/DNS, porta/path diversi, token duplicato/errato/scaduto, risposta 302, download oltre 2 MiB+128 byte, chiave/tag/nonce/ciphertext alterati, risposta plaintext, URL LAN legacy senza chiave (rifiutato), zlib oltre 8 MiB, range enorme e timestamp futuro: errore italiano e zero modifiche DB. Nessun download verso Location |
| N06 Fotocamera | Aprire Mostra QR: niente prompt/avvio fotocamera. Passare a Scansiona QR: consenso; negare/revocare e riprovare. Camera ferma al cambio scheda/background/uscita |
| N07 Notifiche | Consentire/negare; programmare dato sintetico futuro, chiudere app, riavviare dispositivo, revocare il permesso e riprovare. Verificare testo/tap, orario inexact, assenza di esattezza promessa e nessun crash |
| N08 Widget | Aggiungere entrambi i widget al launcher, controllare anteprime, dati e tap. Invio di broadcast esplicito da app esterna al background receiver deve essere negato; PendingIntent legittimo dell'app deve restare utilizzabile. Non considerare implementato il tap “visto” se il layout Kotlin non lo espone |
| N09 Upgrade | Installare candidata con dati/widget già presenti: note, voti, stati, timestamp, mapping cour e istanze widget invariati. Mai disinstallare per “risolvere” un fallimento |
| N10 Offline | Modalità aereo e Wi-Fi disattivato, cache episodi scaduta: dettagli serie salvati leggibili, refresh fallisce senza cancellare stale; nessun totale/notifica modificato da snapshot parziali. Separare offline da HTTP 401/403/404 |
| N12 OTA GitHub | Nessuna rete OTA senza tap; tap → release/conferma → permesso installazione prima del download; negare, tornare dalle impostazioni, annullare download, poi installare APK compatibile. Non confondere avvio installer con installazione completata |
| N13 Accessibilità | TalkBack: etichette e stato selezionato dei tab, focus e azioni. Testo 200%/massimo sistema, display stretto, landscape e tastiera: contenuti scrollabili e target toccabili. Provare contrasto su poster reali, non soltanto colori statici |
| N14 API 36 | Edge-to-edge, status/navigation bar e gesture/back: nessun elemento sotto barre/tastiera, dark splash senza flash bianco, ritorno browser e uscita dialog coerenti |
| N15 16 KB | PAGE_SIZE=16384, modalità di compatibilità disattivata se presente. Cold start, apertura SQLite/migrazione, scanner ML Kit, immagini, trailer, widget e notifiche: nessun linker error/SIGSEGV. Ripetere almeno su arm64 reale quando disponibile |
| N16 Prestazioni | Libreria sintetica grande, stagioni 200/500 episodi: misurare cold start, frame/raster con DevTools/Perfetto, memoria prima/dopo scroll/QR/trailer e tempi query. Annotare dispositivo/build; nessun FPS/RSS è stato misurato in questa sessione |

La prova 16 KB segue la [guida Android](https://developer.android.com/guide/practices/page-sizes).
I test in memoria coprono v12→14 e v13→14; per versioni più vecchie servono copie
sintetiche verificabili di schemi realmente distribuiti, senza inventare una
fixture per dichiarare supportato un percorso non documentabile.

## Registro delle prove

### Artefatti e confronto statico delle firme

Evidenze raccolte il **2026-11-17**, riferite esclusivamente alle build elencate.
applicationId comune: **com.example.showtracker**. Manifest estratti con apkanalyzer
e firme verificate con apksigner verify --print-certs, senza leggere le chiavi.

| Build | SHA-256 APK | Risultato e limite |
| --- | --- | --- |
| GitHub pubblicata v1.2.0 (8), app-release.apk | 1a2c130876e57798c9439048f07a81b38e80805c192f727fc7a5d6868c152f37 | Riferimento distribuito verificato tramite digest dell’asset GitHub |
| Prima candidata locale release 1.2.0 (8) | d00e7125420b3f2ea460489de944a23bd2579cb0007c2ab4c4b71ad02e5d6168 | applicationId e certificato identici; versionCode non crescente, quindi non candidata a nuova release OTA |
| Release locale per prova 1.2.1 (9) | 46a29ecbaba844229651a338a324257b8de274148917a5cbeefa56f2a02d5b9d | Stesso certificato release, 9 > 8; non pubblicata e non installata nella prova debug |
| Debug locale 1.2.1 (9) | e6a5be7d0bed6f9b07d5b8f4911a0111ab28b3118678c175e6430ea9fcd37db1 | Stesso certificato della debug 1.1.1 (7) sul target; usata per la prova nativa sotto |
| APK release verificato dopo la pulizia, 1.2.0 (8) | b77be395c6278218a2eac8bddf9497c5af326988747b78f2ea940997dbc266de | Stessa firma della release distribuita, Manifest/DEX/ELF/ZIP verificati sull’host; nessuna prova runtime di questa build |

Gli hash sono storici: l’ultimo APK elencato precede la successiva correzione
Retry-After e il testo RAWG. Non rappresenta automaticamente i sorgenti attuali:
prima di una nuova prova o distribuzione ricompilare e verificare l’artefatto esatto.
Le build locali 1.2.1 (9) erano state preparate con soli flag di build; pubspec.yaml
è rimasto 1.2.0+8 e non è stato cambiato durante queste verifiche.

Certificato SHA-256 **release**, identico negli APK release confrontati:
`5bda3b35b8d6d375ee466137267fa1d2bec566fb3d76a8693456f75921301cf1`.
Certificato SHA-256 **debug** del target e della candidata debug:
`c62b196b010b342fd991c7307231779651b8e70d5d9f9267c0564e1223aaec8d`.
Sono diversi: non tentare release sopra debug e non disinstallare per aggirare
la differenza. “Non debug” da solo non dimostra compatibilità con una release.

Riferimento attendibile: [release GitHub v1.2.0](https://github.com/gianDaidone/showtracker/releases/tag/v1.2.0),
pubblicata il 13 novembre 2026; release ID 444597562, asset ID 744737897,
87.048.533 byte. Il digest dichiarato nell’API coincide con l’APK locale archiviato
in build/audit/upgrade-verification/distributed-v1.2.0-8.apk. La release non era
immutable: il riscontro riguarda l’asset letto, non prova assenza di sostituzioni
storiche. Non si è dedotta la provenienza dal solo nome del file.

Evidenze host sotto build/audit: github-latest-reference.json,
github-update-continuity.json, single-apk-signature.json e archivio
upgrade-verification/initial-continuity-v1.2.0-8.json. L’APK locale release 1.2.1 (9)
è archiviato in upgrade-verification/candidate-release-v1.2.1-9.apk.

### Selezione dell’asset GitHub: verifica host

Il parser reale GithubReleaseService.parseRelease, eseguito sui metadati della
release v1.2.0, ha selezionato correttamente app-release.apk e il relativo URL
di download; unico asset APK della risposta letta. Log: build/github-asset-selection.log.
Il parser sceglie il primo asset .apk con URL non vuoto: la futura release deve
contenere l’APK previsto come unico asset APK, non affidarsi al nome per verificare
certificato o provenienza. L’updater confronta major/minor/patch: due versioni
1.2.0 non mostrano un aggiornamento anche se cambia soltanto il suffisso build.

La candidata 1.2.1 non è stata pubblicata: download e installazione OTA di quella
build tramite releases/latest sono **NON ESEGUITI**. Il test host del parser e
adb install -r non sostituiscono il percorso OTA completo.

### N09: prova nativa debug con dati conservati

Target: **Pixel_9 / emulator-5554 / API 36**, confermato dal proprietario privo di
dati personali, con dati di serie e giochi di test. Nessun dispositivo personale,
account, secure storage o database personale è stato usato o letto per la prova.

1. Installazione iniziale rilevata: debug 1.1.1 (7). Estratto il solo APK per
   confrontare il certificato, senza modificare l’installazione o i dati.
2. Candidata debug 1.2.1 (9): stesso applicationId e certificato, versionCode 9 > 7.
3. Baseline osservata dal proprietario: The Witcher con episodio 1 visto;
   GTA V nello stato giocato, voto 8.
4. Eseguito aggiornamento con adb -s emulator-5554 install -r: **Success**;
   avviata MainActivity, PackageManager conferma 1.2.1 (9).
5. Il proprietario ha verificato nella UI e confermato tutti e tre i valori:
   **PASS, limitato a questa prova debug e a quei dati osservati**.

Evidenze in build/audit/upgrade-verification/debug-candidate.json e
debug-install-result.txt. Nessun mock ha prodotto questo risultato. Non sono
stati usati uninstall, pm clear o reset dell’AVD; non si deduce la conservazione
di sessioni, widget, altri campi o tutti i record dalla conferma dei tre valori.

### Verifiche native ancora mancanti

N09 **release** con dati sintetici e firma release; N12 **OTA completo** con
consenso, annullamento, download e installazione; N04/N05 **LAN tra due peer**
aggiornati e incompatibilità in entrambe le direzioni; browser/login/cambio
credenziali, notifiche/widget, offline e runtime 16 KB. Gli altri casi della
matrice restano NON ESEGUITI finché non vengono registrati risultati reali.
La prova debug storica non certifica l’APK successivo né il canale OTA release.
