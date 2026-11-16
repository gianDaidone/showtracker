# Regole Dart/Flutter applicabili al progetto

Queste sono prescrizioni per nuovo codice e refactoring, non una dichiarazione
che ogni file esistente le rispetti già. Applicare i lint di `analysis_options.yaml`.

## Responsabilità e composizione

- Mettere trasporto/parsing in `data/`, coordinamento condiviso nei provider,
  rendering/interazioni in `presentation/`; rispettare le eccezioni strutturali
  già descritte in [01](01-architecture.md).
- Estrarre widget con responsabilità leggibile e input espliciti; usare `const`
  quando possibile. Non imporre una classe per ogni frammento banale.
- Non aggiungere livelli Repository/UseCase solo per uniformità nominale.
- Centralizzare le regole episodio in `watch_next_rules.dart`: vietate copie
  indipendenti in card, header e widget Android.
- Non mettere richieste HTTP o mutazioni persistite nel `build` di un widget.
  I provider async possono eseguire letture nel loro `build` secondo il contratto Riverpod.
- Tenere distinte identità DB, TMDB, RAWG, AniList e coordinate cour.

## Async, BuildContext e risorse

- Dopo un await, prima di navigare, mostrare dialog o usare context, verificare
  `context.mounted`; in uno State usare `mounted` prima di `setState`.
- Per Ref/state provider usare le regole di lifetime Riverpod, non il mounted widget.
- Mantenere vivi provider autoDispose letti imperativamente con `readFuture`
  o subscription; chiudere la subscription in `finally`.
- Registrare cleanup di timer, controller, subscription e client sul proprietario
  corretto (`dispose`, `ref.onDispose`, `finally`).
- Usare `unawaited` solo per lavoro intenzionalmente indipendente con proprietario
  e gestione errori espliciti. L'uscita dalla schermata non deve interrompere recovery sync.
- Non disporre il container globale. I container temporanei attendono il drain
  completo prima del dispose.
- Non tenere una transazione SQLite aperta mentre si attende la rete.

## Rebuild, liste e immagini

- Osservare dipendenze necessarie; evitare un grafo di query per singola card.
  Prima di usare `.select` o nuovi cache layer misurare il problema reale.
- Usare conteggi condivisi e letture bulk esistenti per la visibilità.
- Conservare dati precedenti durante reload dove il flusso già lo prevede;
  non mascherare errori permanenti con un loader infinito.
- Liste lunghe lazy; stagioni in sliver, senza nested list shrink-wrapped.
- Conservare key e mappa indici per ID quando gli elementi possono spostarsi.
- Usare `MediaImage` per immagini non-zoom; non rompere uguaglianza dei provider,
  aspect ratio o chiavi sincrone per eliminare un sintomo di fade.
- Non chiamare “miglioramento FPS” una riduzione di query o tile montate.
  Protocollo e misure: [performance-audit.md](performance-audit.md).

## Errori, null e dati parziali

- Distinguere errore di trasporto, HTTP permanente, parsing e assenza legittima.
- `null`, lista vuota, totale zero e cache assente non sono sinonimi.
- Modellare esplicitamente snapshot parziali con `isLocalSnapshot`; non usarli
  per riscrivere totali, timestamp o puntatori.
- Preservare contratti vuoto/null dei servizi opzionali; evitare catch generici
  che trasformino un dettaglio obbligatorio fallito in successo.
- Non mostrare nuove eccezioni grezze nella UI; usare messaggi italiani e log
  privi di URL/token sensibili.
- Non applicare il retry globale Riverpod come correzione degli errori AniList.

## Scritture e regressioni

- Scrivere tramite DAO e attendere lo stream; evitare stato locale duplicato per
  la libreria persistita.
- Mantenere atomicità tra progressi e timestamp e target naturali degli upsert.
- Refresh significa scadere la cache recuperabile, non cancellare l'unica copia.
- Dopo un fetch concorrente rileggere i campi personali che potrebbero essere
  cambiati; hydration non deve ricreare record rimossi.
- Testare il comportamento che può regredire: query/risultato/DB/UI, non il nome
  di un helper privato. Usare [test/README.md](../test/README.md).
- Per cold offline usare provider reali con trasporto simulato: override di un
  dettaglio già riuscito non verifica il fallback.
- Modificare soltanto il sorgente; rigenerare le parti annotate.
