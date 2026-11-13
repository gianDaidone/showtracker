# Audit prestazionale sistemico

Branch: `perf/process-optimizations` · baseline codice: `66e630c` · 2026-11-13.
SDK: Flutter 3.47.6 / Dart 3.13.5, Windows 11.

## Metodo e limiti

L'audit riguarda processi e pipeline, non micro-ottimizzazioni sintattiche.
Le verifiche automatiche usano SQLite in memoria, HTTP simulato, canali nativi
simulati e immagini PNG generate localmente. Nessuna chiave reale o database
personale viene letto. Nessuna app viene installata/disinstallata.

Non è collegato un dispositivo Android: cold startup, RSS/GC, tempi raster/UI e
FPS **non sono stati misurati**. Riduzione delle query, dispatch e widget montati
non equivale alla stessa percentuale di miglioramento end-to-end.

Il primo tentativo di baseline `flutter analyze --no-pub` si è sovrapposto ai
primi edit: ha rilevato simboli temporaneamente incompleti e non costituisce una
baseline valida del codice iniziale. La suite baseline non è partita perché
l'analisi era in catena condizionale. Il confronto prima/dopo si basa quindi su
workload di riferimento pre-bulk conservati nei test, non su tempi wall-clock
raccolti prima degli edit. I controlli finali sono riportati separatamente.

## Risultati e interventi

### 1. Startup e background

Prima, `main.dart` attendeva timezone/plugin, prompt permessi notifiche e setup
HomeWidget prima di `runApp`. Avviava un worker di metadata/notifiche e
`ShowTrackerApp.initState` avviava la medesima scansione post-frame.

Ora:
- timezone e init plugin restano prerequisite esplicite;
- `StartupCoordinator` avvia dopo il primo frame setup/listener dei widget e
  prompt permessi, senza bloccare l'uno sull'altro;
- manutenzione solo dopo permesso e ripristino auth, anche dopo primo login;
- una sola scansione di avvio e single-flight per scansioni concorrenti;
- `readFuture` protegge le letture imperative durante gli await;
- container globale, pacing fra serie e AniListQueue restano invariati.

Risparmio strutturale: 2→1 scansioni di avvio (**−50%**). I vecchi provider già
condividevano alcune richieste: non assumere −50% della rete complessiva.
La rimozione del prompt dal percorso al primo frame non viene tradotta in una
percentuale inventata di cold startup.

### 2. Dati locali, reattività e I/O

Prima, `visibleWatchingShowsProvider` eseguiva una JOIN e poi letture sequenziali
per ogni serie. A freddo: `1 + 2N + A + X` SELECT, dove N è il numero di serie,
A gli anime e X gli anime con cache scaduta/mancante (seconda lettura stale).
Gli episodi di ciascuna stagione venivano caricati con tutto il payload per
controllare una data e l'esistenza della stagione.

Ora i conteggi sono uno stream condiviso e le family per serie sono proiezioni;
le cour sono lette in bulk senza eliminare quelle scadute; una query mirata
restituisce separatamente esistenza stagione e date del target. Il provider
osserva anche gli aggiornamenti delle tabelle cache. Nessuna rete per contare
“Da Vedere”, nessuna duplicazione delle regole di visibilità.

Per un singolo chunk: quattro SELECT con anime presenti (tre senza anime).
N=50: 101–201→4 (**−96–98%**, workload isolato). Chunk: 900 ID anime,
300 target episodio/900 parametri. Cache assente e target assente non vengono
confusi con stagioni vuote.

Salvataggi episodi, cour e conteggi ora usano batch Drift dentro transazioni;
le chiavi uniche originali e il cleanup cour restano invariati. Cento righe:
100 dispatch insert→un batch (**−99% dispatch**, sempre 100 scritture SQL
logiche). Mark episodio e timestamp parent sono una transazione: niente stati
intermedi pubblicati al grafo reattivo.

Export sync: episodi visti raggruppati in una lettura, S+3→4 SELECT;
50 serie: 53→4 (**−92,5%**). Payload/range/timestamp invariati, import LWW non
riscritto.

### 3. Widget nativi e rete

Prima: tre possibili refresh all'avvio (esplicito + due listener), counter che
scartava risultati dopo aver già fatto rete, fetch TMDB stagione diretto che
aggirava cache e numerazione sintetica anime.

Ora: richieste ravvicinate accorpate, una preparazione attiva per container,
trailing pass con dati correnti se arrivano modifiche durante il lavoro.
La Future attende tutto il drain, compreso il background callback. Maratona
riusa autorità locale e regole condivise, dettaglio stagione cour-aware e
fallback locale. I download concorrenti per URL condividono la Future e hanno
un timeout. Snapshot preparato prima dei commit nativi serializzati.

Burst controllato di tre richieste: una preparazione, oppure due se i dati
cambiano durante la prima (**−33–67%**). Pubblicazioni identiche soppresse
solo nello stesso drain: fra isolate le preferenze possono cambiare.
Non è una transazione nativa atomica; il plugin conserva i commit per chiave.

Dettaglio TMDB grezzo condiviso fra `showDetail` e arricchimento anime:
quattro→due HTTP bilingui nel percorso cold duplicato (**−50% richieste di
quel dettaglio**). Due cour concorrenti condividono fetch, ridistribuzione e
salvataggio, senza rendere permanenti miss/errori e senza cancellare fallback.

### 4. Memoria immagini

Tutti i 21 siti non-zoom dei precedenti 22 `CachedNetworkImage` usano ora
`MediaImage`: budget da layout finito e DPR, bucket 32 pixel, decode da dimensioni
intrinseche preservando aspect ratio e pixel sufficienti al `BoxFit.cover`.
Anche `imageBuilder`/DecorationImage riceve il provider limitato. RAWG mantiene
l'URL originale ma decode limitato; solo URL TMDB noti scelgono varianti CDN.
Il fullscreen con zoom 4× e i video non cambiano. Nessun taglio globale alla
ImageCache che possa causare thrashing.

Non tutte le immagini erano eccessive: w185 poster 60×90 a DPR3 era già vicino
al necessario; un landscape w185 in un box 96×80 cover può essere troppo piccolo.
Quindi nessun claim uniforme sulla RAM.

Esempio teorico poster w342 (~342×513) a 46×68 DPR3: budget bucket160×224,
decode aspect-preserving circa160×240, **−78% pixel/byte bitmap** rispetto al
sorgente originale (non −83% dopo il bucketing). Il decode non equivale a RSS
processo, memoria GPU o picco transitorio: quelli richiedono profiling reale.
Per still molto ritagliati ad alto DPR la qualità può richiedere una variante
più grande di w300 (TMDB serve `original`): questo può aumentare byte di rete
per quella immagine pur limitando la bitmap decodificata. Non si promette quindi
una riduzione uniforme del traffico immagini.

### 5. Stagioni lunghe e scrolling

Prima: lista lazy delle stagioni, ma ogni stagione espansa costruiva tutti gli
episodi in una `Column`, comprese immagini fuori schermo.

Ora: `SliverMainAxisGroup` con header e `SliverList.builder`, nella scroll view
esistente; chiavi show/cour, più sezioni aperte, grouping batch-release e
interazioni originali conservati. I gruppi date non vengono ricalcolati ad ogni
emissione watched.

Fixture 200/500 episodi: obiettivo meno di 30 tile montate nel viewport/cache,
quindi **oltre85%/94% in meno** rispetto alla costruzione completa. Non è una
misura di FPS.

## Verifiche automatiche

Nuove coperture principali:
- `test/core/database/pipeline_performance_test.dart`: confronto reference/bulk,
  chunk, semantica summary, batch/rollback, atomicità progressi, export;
- `test/features/series/visibility_performance_test.dart`: provider reale,
  query-count cold10/50/100, zero rete, cache-only invalidation;
- `test/features/series/pipeline_coordination_test.dart`: single-flight scansioni,
  dettaglio anime condiviso, cour concorrenti e conteggi reattivi;
- `test/core/startup_coordinator_test.dart`: bootstrap idempotente, auth,
  widget non bloccati dal prompt;
- `test/core/coalescing_refresh_test.dart`, `test/widgets_manager_test.dart`:
  burst/trailing/errori/fallback/pubblicazione;
- `test/core/media_image_test.dart`: DPR/cover/aspect/cache keys/URL e decode PNG;
- `test/features/series/presentation/season_virtualization_test.dart`:
  scale200/500, scroll, cour, espansione e azioni.

Contatore SQL: reset dopo schema/seed; batch dispatch e SQL logiche distinti.

Risultati verificati del workload DAO con metà serie anime:

| Serie | Reference fresh | Reference stale/missing | Bulk cold | Riduzione SELECT |
|---|---:|---:|---:|---:|
| 10 | 26 | 31 | 4 | 84,6–87,1% |
| 50 | 126 | 151 | 4 | 96,8–97,4% |
| 100 | 251 | 301 | 4 | 98,4–98,7% |

Anche il provider reale, con cache fresh/stale/missing miste nello stesso
workload, conferma quattro SELECT cold a10/50/100 serie e visibilità uguale al
riferimento. Nessun test attribuisce le percentuali SQL ai tempi end-to-end.
Il download filesystem/HTTP dei widget non ha ancora un test diretto dedicato;
il drain del callback background è verificato nella struttura del codice, non
con un'invocazione che aprirebbe il DB singleton. I canali mock non verificano
il rendering Kotlin o l'interazione reale fra isolate.
Prima esecuzione completa: 315 pass, 15 failure (dodici misure cold contaminate
riutilizzavano la JOIN in cache Drift, un import rendering mancante nel test,
una fixture cour non contigua e un test bootstrap bloccato dal fake scheduler).
Le fixture sono state corrette senza indebolire i budget SQL: i riferimenti
usano letture one-shot e il percorso misurato resta realmente cold. Il bootstrap
è ora provato con test asincroni reali e Completer, senza timeout artificiosi.
Rerun mirato: 51 pass, un'asserzione residua di viewport nel test delle due cour
(la tile lazy non era ancora montata e l'header poteva essere coperto dall'app
bar). Il test ora centra gli header e rivela le righe per chiave, senza
pretendere che tutte le righe lazy siano montate contemporaneamente.

**Suite completa finale: 335 test superati**, comando
`flutter test --no-pub --reporter expanded --timeout 90s`, circa12s (host,
nessun confronto temporale prima/dopo). Confermati: quattro SELECT cold con
10/50/100 serie miste;100 insert logici in un batch; export quattro SELECT;
nessuna rete per visibilità; condivisione metadata/cour; decode PNG; meno30
EpisodeTile montate nelle fixture200/500; burst/trailing e fallback widget.
**Rigenerazione finale riuscita** con `dart run build_runner build`.
**Analisi statica finale pulita**: `flutter analyze --no-pub` →
`No issues found!`.
**Build Android debug riuscita**: `flutter build apk --debug --no-pub` →
`build/app/outputs/flutter-apk/app-debug.apk` (assembleDebug circa67s).
Le licenze segnalate da doctor non hanno bloccato questo build; non è stata
eseguita alcuna accettazione automatica. APK solo compilato, non installato.
`git diff --check` senza errori di whitespace (avvisi LF/CRLF del repository).

## Follow-up: identità delle card dopo “visto”

Segnalazione: scheletri su tutte le card dopo aver segnato un episodio.
`visibleAsync.when` aveva già `skipLoadingOnReload: true`; aggiungere la stessa
flag o mantenere tutte le stagioni in memoria non risolve la causa verificata.
Le liste lazy avevano card con `ValueKey(show.id)`, ma senza mappatura
`findChildIndexCallback`; inoltre gli sliver delle sezioni non avevano chiavi.
Una rimozione/spostamento distruggeva gli Element/State delle serie superstiti.

Riproduzione prima della correzione: due dei primi tre test di
`feed_identity_test.dart` fallivano sull'identità della serie102, sia alla
rimozione della prima card sia alla scomparsa dell'intera prima sezione.
Il caso senza rimozione passava. **Nelle fixture non è stato riprodotto lo
scheletro di tutte le card**: i provider superstiti avevano ancora un solo build
e zero dispose, coerentemente con il grace period di autoDispose. Non si
attribuisce quindi al rimontaggio un dispose non osservato.

Correzione: indici per show ID O(1) per entrambi i delegate, chiavi stabili
header/liste per gruppo. Nessuna modifica a query, visibilità, animazione,
notifiche o politica di retention. Le prove includono anche migrazione di una
serie inattiva nel gruppo recente e il provider stagione reale su cache SQLite. Verificano identità delle card,
nessuno skeleton ad ogni pump, provider non riavviati e aggiornamento effettivo
di progressi/header. Resta da confermare su dispositivo che il lampeggio
segnalato sia interamente eliminato; non si dichiara una riproduzione che i test
non hanno mostrato.

Verifica follow-up: cinque test mirati superati, `flutter analyze --no-pub`
senza segnalazioni e suite completa **340 test superati**. Nessuna nuova build
APK effettuata per questo follow-up: l'APK precedentemente compilato non
contiene questa correzione UI.

## Follow-up: lampeggio immagini confermato in debug

La verifica sul processo debug dell'emulatore (senza reinstallazioni) ha
mostrato che dopo il tap la lista conserva `hasValue=true`, le card non vengono
smontate e non compare `LIST SKELETON`. Solo il reale passaggio di stagione
carica lo skeleton della card interessata. L'utente ha poi precisato che a
lampeggiare sono le immagini, non tutta la card.

Causa riprodotta con test su immagine già in cache: `MediaImageProvider` aveva
uguaglianza per istanza pur avendo chiavi cache equivalenti, e `obtainKey` con
async/await rendeva asincrona anche la chiave sincrona del provider sorgente.
OctoImage usa `ValueKey(image)` sul widget Image: ricreando il wrapper a ogni
rebuild cambiava quella chiave, distruggeva ImageState e riavviava placeholder e
fade. I precedenti test delle sole chiavi cache non coprivano questo contratto.

Correzione: uguaglianza/hash del provider per sorgente+budget+fit, preservando
la SynchronousFuture del sorgente. Test prima rosso sull'ImageState distrutto,
poi verde: stesso ImageState e nessuna nuova invocazione del placeholder sui
rebuild con immagine invariata. Budget decode, qualità, URL e zoom invariati.
L'utente ha confermato sull'emulatore: «Ora funziona correttamente» dopo il
reload della correzione. Analisi statica pulita e **342 test superati**.
Log diagnostici temporanei `[feed-trace]` rimossi e monitor logcat fermato dopo
la conferma. Nessuna installazione/disinstallazione o modifica dei dati utente;
nessun nuovo APK compilato per questo follow-up.

## Follow-up: intestazione “Da Vedere (1)” senza card

Caso riprodotto con fixture sintetiche: stagioni precedenti completate e un
nuovo episodio annunciato in cache, ma air_date/airing_at null.
`airedPerCachedEpisodes` restituiva null per quella riga; il conteggio usava
quindi il totale DB per considerarla disponibile. `TmdbEpisode.hasAired`, usato
dalla card, restituiva invece false e la nascondeva. L'invalidazione una-tantum
della lista non poteva risolvere una differenza deterministica di semantica.

Correzione nel solo helper condiviso: cache target assente→null (fallback
offline invariato); target presente senza data valida→false, come nella card.
L'eventuale conferma AniList continua a essere valutata da `resolveHasAired`.
Nessuna modifica ai progressi personali, ai totali o al prossimo puntatore.

Test widget con due stagioni viste e una terza annunciata senza data: prima
falliva, dopo mostra “Sei in pari!” e nessun conteggio/card fantasma. Test delle
regole per date null/vuote/non valide e cache assente; 38 test mirati superati.
Verifica completa: analisi statica pulita e **344 test superati**.

## Follow-up: avvio a freddo in modalità aereo

Il test offline manuale ha esposto un percorso non coperto dai precedenti mock:
`showDetail` attendeva TMDB prima di animeData, e `seasonDetail` attendeva
showDetail prima della cache episodi. La failure DNS impediva quindi di
raggiungere anche dati persistiti freschi/stale: label anime perse, dettaglio
con eccezione grezza e riemersione di un episodio senza data dal fallback ai totali.

Riproduzione prima del fix con trasporto ClientException e provider reali:
`offline_transport_test.dart` falliva sulla lettura del dettaglio già tracciato.
Non era un test con override di dettaglio riuscito.

Correzione:
- snapshot locale parziale dai campi tracked/counts, solo su failure di
  trasporto/timeout/server5xx; HTTP401/403/404 non mascherati;
- identità anime dal flag persistito, cour stale composti dallo stesso builder
  online, niente paesi/genre inventati né chiamate AniList per il fallback;
- episodi stale accessibili anche quando il dettaglio remoto fallisce;
  numeri assoluti, date e timestamp preservati;
- snapshot locali esclusi da sync metadata/scheduling: nessun aggiornamento
  passivo a progressi/timestamp/totali/puntatore;
- stato stagione parziale esplicito: niente correzioni conteggi/completamento
  dedotte da una lista incompleta; senza mappatura anime azioni ambigue bloccate;
- refresh manuale expire-not-delete anche per episodi e feedback di errore se
  usa il locale; banner italiano saved-data e messaggi connessione leggibili.

Nessuna migrazione o cache completa di payload remoti: backdrop e altre
informazioni mai salvate possono mancare offline. Le label “Parte N” derivano
dalla mappatura persistita e conservano la stessa convenzione numerica online.

Nuove suite cold con soli HTTP mock, non provider di dettaglio: metadata normali,
DNS/Socket, cour fresh/stale, episodi scaduti, snapshot DB prima/dopo tutti i
percorsi di scheduling, mancanza cache esplicita, HTTP permanenti e recovery
online. Test UI apre il dettaglio, espande un cour e prova refresh fallito senza
perdere payload. **Suite completa:360 test superati**, incluse quattro prove
UI cold e undici prove provider (più regressione trasporto e scadenza DAO).
Prima esecuzione UI ha segnalato fixture/harness non corrette (override duplicato,
confronto UTC/local, attese async e header inattivi) risolte senza sostituire i
provider reali o rimuovere i controlli di integrità DB.
Rigenerazione finale riuscita, `flutter analyze --no-pub` senza segnalazioni,
`flutter build apk --debug --no-pub` riuscito:
`build/app/outputs/flutter-apk/app-debug.apk` (assembleDebug circa30s).
Nessuna installazione o azione watched automatizzata sulla libreria personale.

## Follow-up: errore offline nella ricerca

Discovery e risultati digitati interpolavano direttamente l'eccezione nel
widget Text. Ora condividono `searchErrorMessage`: messaggio italiano su
connessione/timeout e messaggio generico per altri errori, nessun dettaglio
ClientException/SocketException/host nella UI. La ricerca digitata offre anche
Riprova, invalidando soltanto le categorie attive fallite; la discovery conserva
il retry già esistente. Nessuna modifica a cache/paginazione o risultati già
caricati. Due test prima rossi coprono barra vuota/query, testo sicuro e recovery
al retry quando torna la rete. Verifiche completate: analisi statica pulita e
**362 test superati**; quattro test mirati ricerca passano, incluso retry dopo
riconnessione per query vuota e digitata.

## Follow-up: giochi “Sconosciuto” dopo import QR senza RAWG

Il payload sync contiene ID/stati, non titoli. Il recupero metadata veniva
avviato una sola volta dopo import; se mancava la chiave RAWG, aggiungerla dopo
ricreava il client ma non rilanciava l'hydration. Il problema valeva anche per
film con primo tentativo offline/non autenticato. Inoltre hydration giochi
ometteva piattaforme e memorizzava il voto RAWG /5 invece della scala /10.

Nuovo `metadataRecoveryProvider`: coordinatore stabile per dominio, listener
credenziali al bootstrap indipendente dal prompt notifiche; login/cambio chiave
riavvia il dominio relativo, apertura libreria ritenta i soli placeholder,
post-import usa lo stesso coordinatore e continua oltre la schermata QR.
Coalescing per dominio, acquisizione dei service correnti e generazione auth
per fermare richieste residue di client superati. Nessuna rete senza chiave
effettiva né se non esistono placeholder; nessun polling.

`hydrateUnknownMedia` conserva default compatibile e aggiunge flag dominio e
cancellation guard. Scrive solo metadata con predicato ID+IDesterno+titolo ancora
placeholder, non ricrea righe cancellate o già risolte. Giochi: cover, release,
piattaforme JSON, voto normalizzato; playtime letto dopo la rete e riempito solo
se ancora null. Film: titolo/poster/trama/data/anno. Stati, voti personali, note,
addedAt/updatedAt e precedenza LWW non cambiano.

Test aggiunti: safety metadata, lifecycle con auth/interceptor reali e chiavi
fittizie, UI giochi/film aggiornata dall'apertura senza reimport. Primo run:
44 test passati, due widget test bloccati dal confine fake/real del runner:
il post-frame aveva aperto una transazione nella zona fake e il flush attendeva
SQLite senza poterla completare. Montando la schermata nella zona runAsync
(come le scritture watched già testate), entrambe le prove passano senza
invocare manualmente il recupero né cambiare la produzione per il test.
I run globali hanno esposto anche il confine fake-clock di smoke e schermate
offline. Il solo harness avvia in runAsync il montaggio quando il bootstrap è
abilitato, lasciando invariato il montaggio ordinario; il test libreria giochi
avvia esplicitamente il proprio post-frame SQLite fuori dal fake clock. Otto
prove mirate startup/librerie/offline passano senza cambi alla produzione per
soddisfare il runner.

**Verifica finale:395 test superati**, `flutter analyze --no-pub` senza
segnalazioni e `flutter build apk --debug --no-pub` riuscito:
`build/app/outputs/flutter-apk/app-debug.apk` (assembleDebug circa31s).
Nessun accesso a chiavi/DB personali e nessuna modifica schema/payload QR.

Prova manuale consigliata per l'archivio già importato: hot restart con rete
attiva e chiave RAWG salvata, aprire “I miei giochi” e attendere la sostituzione
dei placeholder. Controllare gli stati/voti prima e dopo, poi riaprire per
verificare la persistenza. Per il caso iniziale: su dati di test, import senza
chiave, inserire la chiave e verificare il recupero senza un secondo QR. Ripetere
con film e credenziali TMDB. Chiave invalida/offline lasciano il placeholder
ritentabile alla prossima apertura, senza rimuovere l'elemento.

## Revisione finale prima dei commit

Revisione dell'intero diff, inclusi file nuovi non tracciati, e nuovo run
randomizzato seed20261113:395 test passavano prima delle ulteriori correzioni.
Quattro casi limite confermati e corretti con regressioni dedicate:
- nessun fetch grezzo per anime senza mapping anche se il numero coincide con
  una stagione TMDB, per non contaminare la cache cour;
- sostituzione transazionale dei download completi di stagione, così episodi
  rimossi dal sorgente non sopravvivono come stale; failure preservano la copia;
- fallback locale/stale e regole di visibilità conservano l'orario del puntatore
  delle serie normali invece di anticipare l'uscita a mezzanotte;
- listener widget sull'autorità della lista visibile, per accodare refresh
  anche quando cambiano soltanto date/cache e non progressi o metadata show.

Esclusi dai commit chiavi locali, keystore e cache Gradle non tracciata.
Verifica finale dopo le correzioni: **403 test superati** con ordine
randomizzato seed20261113, analisi statica senza segnalazioni, build APK debug
riuscita (assembleDebug circa18s). Il primo test globale delle09:00 ha inoltre
segnalato una precedenza troppo ampia sui puntatori futuri: il blocco ora vale
solo per il giorno corrente, mantenendo il recupero da dati cache già trasmessi.
Codegen eseguito con build_runner, nessun edit manuale dei generati.

## Rilievi differiti

- JOIN watching ripete colonne show per ogni episodio: non riscritta in questa
  fase, per limitare la superficie mentre si elimina il fan-out successivo.
- Import/hydration sync sequenziali e range expansion senza limite: lavoro
  separato che richiede conservare conflitti/unione e recovery.
- Cache metadata/file widget senza pruning globale: nessuna cancellazione
  automatica introdotta; le cour stale sono l'unico fallback offline.
- HomeWidget: molti commit per passaggio, nessun lock cross-isolate; batch nativo
  differito. Il widget Kotlin corrente apre l'app, non espone il mark URI salvato.
- Indici: UNIQUE esistenti coprono i prefissi show/stagione; non sono stati
  aggiunti indici speculativi né migrazioni senza EXPLAIN/costo dimostrato.
- Liste principali e discovery già lazy, famiglie Riverpod già condivise;
  nessun refactoring cosmetico/scattered-select.

## Protocollo manuale su dispositivo di test

1. Non usare applicationId dell'app personale per runner/installazioni di test.
   Usare dispositivo vuoto o identità separata e backup esplicito.
2. Con la stessa build profile e stessi seed, confrontare baseline e branch:
   dieci avvii a processo freddo per ciascuno, auth e cache stabili. Registrare
   tempo primo frame e contenuto utilizzabile, mediana/p95, non il singolo migliore.
3. Liste10/50/100 serie, anime fresh/stale/offline; stagione500 episodi e discovery
   RAWG con stesse immagini. Ripetere gesto scroll, traccia DevTools timeline:
   p50/p95 UI/raster e frame oltre budget del display (60/90/120Hz).
4. Heap snapshot prima/apertura/scroll/ritorno, ImageCache byte/count/live,
   eventi GC e memoria native/GPU/RSS separati; rete fredda e cache calda distinte.
5. Mock clock o date lontane dai confini per ripetibilità; verificare anche reale
   passaggio orario anime, puntatore appena trasmesso, offline e riavvio.
6. Widget reali Maratona/Prossimamente, ultimo snapshot dopo burst, dati offline,
   immagini assenti, permessi notifiche negati/concessi e ritorno dalle impostazioni.

Comandi di validazione seriali: `flutter pub get`,
`dart run build_runner build`, `flutter analyze --no-pub`,
`flutter test --no-pub`, `flutter build apk --debug --no-pub`.
Nessuna accettazione automatica di licenze Android, nessun commit/push richiesto.
