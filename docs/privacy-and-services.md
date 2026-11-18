# Privacy, flussi dati e condizioni dei servizi — APK GitHub

Audit del **2026-11-17**. Questa è una bozza tecnica da completare e approvare dal
proprietario; non è una certificazione legale. Non pubblicare i placeholder.
È il documento privacy attivo per la distribuzione APK GitHub.
Report e gate di release: [audit](security-reliability-audit.md) e
[checklist GitHub](github-release-checklist.md).

## Inventario verificato sul codice e sulle dipendenze

| Destinazione | Dati in uscita / finalità | Trasporto e persistenza |
| --- | --- | --- |
| TMDB API e browser TMDB | Testi cercati, ID di serie/film/episodi e titoli seme per consigli; API key e, se usata, sessione TMDB; autenticazione e metadati | API HTTPS senza redirect, deadline 20 s e risposta ≤4 MiB. Sessione/chiavi in secure storage; metadati in SQLite/cache. Browser esterno gestisce il login sul sito TMDB |
| TMDB immagini | URL/path delle copertine/still, IP e informazioni della richiesta | HTTPS CDN, cache immagini e file widget; nessun invio di note/voti/progressi |
| RAWG API e immagini | Testo ricerca, filtri/ID dei giochi, generi usati per discovery, API key | API HTTPS con gli stessi limiti; chiave in secure storage, metadati/cache locali |
| Yuna relations | ID TMDB per mapping AniList, IP/richiesta | HTTPS, 10 s/4 MiB; mapping in cache SQLite; nessuna credenziale TMDB/RAWG |
| AniList | ID anime, titoli cercati per matching, IP/richiesta | HTTPS GraphQL, attraverso AniListQueue; dati normalizzati/cache locali; niente login AniList o sync della lista personale |
| Steam e CDN dei trailer | App ID Steam e richieste video/preview, IP e informazioni di rete | API HTTPS, riproduzione video nativa; non viene inviato un account Steam. Endpoint store `appdetails` non costituisce un contratto pubblico di API garantito |
| Google ML Kit / DataTransport | Scanner bundled Android: diagnostica, informazioni app/dispositivo, identificatori d'installazione e metriche di uso; non immagini o risultati QR secondo Google | SDK nativo incluso da mobile_scanner, HTTPS; retention e dettagli provider secondo Google. Nessuna promessa di assenza di telemetria |
| Secondo dispositivo scelto con QR | ID, stati, timestamp e progressi episodi; non titoli, note, voti o credenziali | Payload QR diretto oppure HTTP LAN con contenuto AES-256-GCM e chiave nel solo QR, token temporaneo; ricezione privata IPv4/porta 8080, senza DNS/redirect, limiti applicativi, import SQLite atomico |
| GitHub, soltanto su tap | Repository/release richiesta, URL dell'APK, IP/richiesta; nessuna chiave dei cataloghi | Metadati HTTPS; download e installer nativo soltanto dopo tap e conferma |

Fonti di codice: `lib/core/network/`, `lib/core/auth/`, servizi sotto
`lib/features/{series,games,sync,update}/`, `lib/core/widgets/media_image.dart`,
`lib/widgets_manager.dart` e dipendenze native effettive in
`build/audit/native-dependencies.txt`.
Il solo fatto che non esista un backend proprietario non elimina i trasferimenti
ai fornitori o la raccolta del loro SDK. La cache locale non cifra la libreria.

Google descrive elaborazione immagini sul dispositivo e invio di metriche per
ML Kit nei [termini privacy](https://developers.google.com/ml-kit/terms) e nella
[scheda Data disclosure](https://developers.google.com/ml-kit/android-data-disclosure),
consultati il 2026-11-17. Il plugin include il modello barcode bundled; non si usa
auto-zoom nell'app. Non è stata eseguita una cattura del traffico su dispositivo:
la descrizione della telemetria è basata sull'inventario e sulla documentazione
del produttore, non su una misura dei pacchetti di rete.

## Bozza informativa da rendere pubblica

**Titolare:** [NOME/RAGIONE SOCIALE E INDIRIZZO PERTINENTE].
**Contatto privacy:** [EMAIL]. **URL pubblico:** [URL HTTPS STABILE].
**Ultimo aggiornamento:** [DATA APPROVATA DAL TITOLARE].

ShowTracker consente di tenere una libreria locale di serie/anime, film e giochi.
Stati, progressi, voti e note personali sono conservati sul dispositivo. L'app non
gestisce un proprio account cloud e non sincronizza automaticamente la libreria
su un backend del titolare. Le credenziali dei cataloghi sono conservate nello
storage protetto del sistema; il database della libreria non è cifrato dall'app.

Per ricerche, dettagli, consigli, immagini e video, l'app contatta i fornitori
elencati nella tabella precedente. Le richieste possono rivelare interessi e
attività di ricerca. Questi fornitori ricevono inoltre informazioni di rete,
incluso l'indirizzo IP. Il login TMDB avviene nel browser esterno; ShowTracker
riceve una sessione del servizio e non la password TMDB. RAWG usa una API key.
L'uso di tali servizi è soggetto anche alle rispettive condizioni e informative.

La fotocamera viene attivata scegliendo la scheda di scansione del QR e serve
all'elaborazione sul dispositivo. Lo scanner Android usa Google ML Kit, che può
inviare dati diagnostici e metriche a Google. Le notifiche richiedono il consenso
Android; il rifiuto non elimina la libreria. Notifiche e widget possono mostrare
titoli e progressi a chi vede lo schermo o il launcher del dispositivo.

Il trasferimento QR è un'azione esplicita dell'utente. Per librerie più grandi,
il dispositivo mittente espone uno snapshot sulla rete privata per un massimo di
cinque minuti. Il contenuto LAN è cifrato e autenticato con AES-256-GCM; la
chiave è nel QR e non viene trasmessa nella richiesta HTTP. IP, token e metadati
HTTP restano osservabili. Entrambi i dispositivi devono essere aggiornati;
usare soltanto reti e destinatari fidati. La ricezione valida e importa i dati
entro i limiti documentati. Non è un backup completo e non sostituisce le note,
i voti o i metadati mancanti. Chi acquisisce il QR diretto può leggerne il contenuto.

ShowTracker viene distribuita come APK GitHub. Il controllo
degli aggiornamenti parte soltanto da Profilo → Cerca aggiornamenti; download
e installer richiedono conferma e il permesso Android. Nessun controllo automatico.

Disconnettere TMDB/RAWG elimina le credenziali locali ma conserva la libreria.
Per eliminare tutti i dati locali, aprire le impostazioni Android di ShowTracker,
Spazio di archiviazione → Cancella dati, oppure disinstallare l'app. L'azione è
irreversibile. Un QR già condiviso o dati già ricevuti da altri dispositivi non
possono essere cancellati da remoto. Gli account dei servizi terzi si gestiscono
nei rispettivi siti; la revoca remota della sessione TMDB può fallire offline.

I dati locali restano fino alla rimozione da parte dell'utente. Cache immagini,
file widget e metadati hanno retention distinta e possono restare fino alla
cancellazione dei dati Android; non viene promesso un azzeramento delle cache al
logout. I dati già trasmessi ai fornitori seguono le loro policy di conservazione.

[COMPLETARE: basi giuridiche applicabili, finalità del titolare, fornitori/ruoli,
destinatari, trasferimenti internazionali e garanzie, tempi di conservazione
pertinenti, diritti/esercizio/reclamo, pubblico ed eventuali minori. Non dedurre
questi elementi dal solo codice. Controllare tutti i link prima di pubblicare.]

## Condizioni, attribuzioni e licenze anche per GitHub

Le seguenti fonti sono state consultate nell’audit del 2026-11-17; non
sono state ripetute ricerche o richieste ai fornitori per questo consolidamento.
Il cambio di canale non elimina le condizioni delle API.


- **TMDB:** utilizzo non commerciale con attribuzione; per uso commerciale
  confermare licenza col fornitore. Logo e disclaimer sono visibili nella UI;
  la presenza del logo non certifica diritti su tutto il contenuto.
  [FAQ ufficiale](https://developer.themoviedb.org/docs/faq).
- **RAWG:** rimossi su richiesta i pulsanti con logo aggiunti a ricerca e pagine
  giochi; restano i crediti nelle informazioni privacy e il testo/link nel dettaglio gioco. La pagina
  ufficiale ha indicazioni commerciali non uniformi tra prezzi e Terms: il
  proprietario deve confermare piano e condizioni effettive, senza dedurre una
  licenza dal possesso di una chiave personale. Nessuna redistribuzione di
  metadati tramite sync: soltanto ID e progressi.
  [API/Terms](https://rawg.io/apidocs).
- **AniList — blocco da chiarire:** i termini vietano servizi concorrenti non
  complementari, citando tracker anime/manga. Le soglie commerciali non
  sostituiscono tale restrizione. Per ShowTracker serve conferma dell'applicabilità
  o autorizzazione scritta prima della pubblicazione. La pipeline esistente non
  è stata rimossa. Consultata la pagina ufficiale indicizzata; l'apertura diretta
  ha restituito 403 durante l'audit.
  [Terms of Use](https://docs.anilist.co/guide/terms-of-use).
- **Yuna:** endpoint relazioni presente nel codice; non è stato individuato un
  contratto/SLA esplicito per il servizio. Confermare condizioni e attribuzione
  con il gestore. La licenza del codice server non è automaticamente una
  licenza per tutti i dati aggregati.
- **Steam e trailer:** endpoint store appdetails usato come fallback video,
  senza account Steam. Documentazione/diritti del contenuto e uso del servizio
  per distribuzione pubblica da confermare; non assimilare questo endpoint a
  una licenza di ridistribuzione dei video.
- **ML Kit:** elaborazione on-device con metriche Google; informativa aggiornata,
  mantenute le funzioni scanner e le dipendenze bundled.
  [Termini ufficiali](https://developers.google.com/ml-kit/terms).
- **Dipendenze e artwork:** licenze open source accessibili dalla UI tramite il
  registro Flutter; licenze MIT vendorizzate conservate. Titolarità di logo app,
  screenshot pubblicitari, marchi e contenuti da confermare dal proprietario.


### Cosa è verificato e cosa richiede chiarimenti

Aggiornamento mirato con fonte ufficiale letta anche dal repository AniList/docs:
[clausola specifica e applicabilità a ShowTracker](anilist-terms-clarification.md).
Distinguere il divieto per la categoria indicata dalla qualificazione dell’app,
ancora da chiarire; non dedurre un’esenzione dall’uso dei soli metadati.

- Verificati sul codice: logo/disclaimer TMDB, crediti RAWG nelle informazioni
  privacy e nel dettaglio gioco e registro licenze Flutter; licenze delle patch vendorizzate
  conservate. Nessun servizio è stato disabilitato per il cambio di obiettivo.
- AniList: restrizione sui tracker concorrenti verificata nei termini ufficiali
  indicizzati durante l’audit (apertura diretta 403); applicabilità a ShowTracker
  e autorizzazione non confermate. Il proprietario ha risposto “da verificare o
  richiedere”. È un blocco di chiarimento prima della distribuzione pubblica,
  indipendente dalla distribuzione; non si afferma che AniList abbia autorizzato l’app.
- TMDB/RAWG: piano applicabile e uso commerciale dipendono dal proprietario;
  una chiave funzionante non dimostra una licenza. Yuna/Steam: limiti contrattuali
  e diritti da chiarire, senza dichiarare una violazione sulla sola assenza di SLA.
- Informativa: titolare, contatto, finalità/ruoli, retention e basi applicabili
  non sono stati forniti. La bozza tecnica resta utile, ma non va presentata come
  informativa completa né come autorizzazione dei fornitori.
- La descrizione SDK segue documentazione Google e inventario; cattura traffico
  e comportamento nativo ancora NON ESEGUITI. Non promettere “zero raccolta”.
