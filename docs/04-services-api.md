# Servizi e API

## Client effettivi

- `TmdbService`: `lib/features/series/data/tmdb_service.dart`, condiviso con i film.
- `RawgService` e `SteamService`: `lib/features/games/data/`.
- `YunaService`, `AniListService`, `AniListQueue`: `lib/features/series/data/`.
- `GithubReleaseService`: `lib/features/update/data/github_release_service.dart`.
- I provider costruiscono i servizi; non esiste un Repository comune.
- `lib/core/network/http_client.dart` e `lib/core/constants/api_endpoints.dart`
  non sono usati dai servizi correnti: non usarli come descrizione del percorso attivo.

## Autenticazione del trasporto

`lib/core/network/tmdb_http_client.dart` contiene `AppInterceptor`, un
`http.BaseClient`. I provider TMDB/RAWG lo costruiscono con lo stato auth corrente.

| Host esatto | Stato | Parametri aggiunti |
| --- | --- | --- |
| `api.themoviedb.org` | Chiave manuale | `api_key` utente |
| `api.themoviedb.org` | Sessione | `api_key` da `ApiKeys.tmdb`, `session_id` utente |
| `api.themoviedb.org` | Unauthenticated esplicito | `api_key` fallback |
| `api.rawg.io` | RAWG autenticato | `key` utente |
| `api.rawg.io` | RAWG unauthenticated esplicito | `key` fallback |
| Altri host | Qualsiasi | Nessuna credenziale TMDB/RAWG aggiunta |

- Stato auth null non attiva l'iniezione per quel servizio.
- La riscrittura è implementata per `http.Request`; altri `BaseRequest` passano
  senza sostituzione. Non assumere supporto multipart/stream senza verificarlo.
- Preservare metodo, header e body quando si modifica l'interceptor.
- Login browser e cancellazione sessione fanno chiamate TMDB dedicate nelle
  schermate account/onboarding: vedere [08](08-security-permissions.md).

## Contratti remoti usati dal codice

Gli endpoint sotto descrivono l'integrazione implementata, non l'intero contratto
dei fornitori né le loro quote aggiornate.

| Servizio / base | Endpoint e operazioni |
| --- | --- |
| TMDB `https://api.themoviedb.org/3` | `/search/tv`, `/search/movie`; `/trending/{tv,movie}/week`; `/{tv,movie}/top_rated`; `/{tv,movie}/{id}/recommendations`; `/tv/{id}`, `/tv/{id}/season/{n}`, `/tv/{id}/season/{n}/episode/{k}`; `/movie/{id}` |
| Auth TMDB | `/authentication/token/new`, `/authentication/session/new`, `/authentication/session` |
| Yuna `https://relations.yuna.moe/api/v2/themoviedb` | `/?id={tmdbId}` → lista mapping, campo `anilist` |
| AniList `https://graphql.anilist.co` | POST GraphQL `Media(id, type: ANIME)` e `Page(perPage: 10).media(search, type: ANIME, format_in: [TV, TV_SHORT])` |
| RAWG `https://api.rawg.io/api` | `/games` ricerca/discovery; `/games/{id}`; `/games/{id}/screenshots`, `/movies`, `/stores` |
| Steam `https://store.steampowered.com/api` | `/appdetails?appids={id}&filters=movies` per trailer |
| GitHub `https://api.github.com` | `/repos/{kGithubRepo}/releases/latest` per release e primo asset APK |

### Mapping e pagine

- TMDB ricerca/discovery usa `page`, `total_pages`, `total_results`, `results`.
  `SearchPage<T>` espone `items`, `hasMore`, `totalCount`.
- Dettagli TMDB serie, film ed episodi combinano italiano e inglese; preservare
  il fallback campo per campo nei modelli, non sovrascrivere testi validi.
- Stagione TMDB vuota: probe bilingue degli episodi in batch da cinque, fino
  al primo 404, con limite implementato di 100. Altri errori si propagano.
- RAWG: pagina da 40; prima ricerca unisce rilevanza e ricerca precisa/popolarità,
  poi `rankGameSearch`. Pagine successive proseguono la rilevanza.
- Discovery RAWG limita `hasMore` alla pagina dieci. Non applicare quel limite
  alla ricerca testuale per semplice analogia.
- Trailer: ottenere Steam app ID dagli store RAWG, tentare Steam, poi RAWG.
  Nessun trailer disponibile/errore gestito → lista vuota, sezione assente.
- Steam può restituire `data: []`: controllare il tipo prima del cast.
- Screenshot RAWG falliti → lista vuota. Non estendere questo fallback ai dettagli.

## Errori, timeout e retry

| Confine | Comportamento attuale |
| --- | --- |
| TMDB | Non-2xx → `TmdbException` con status; 5xx messaggio di indisponibilità; apiRequest: timeout/abort 20 s, 4 MiB, no redirect; nessun retry |
| RAWG | Non-2xx → `RawgException`; apiRequest: timeout/abort 20 s, 4 MiB, no redirect; nessun retry |
| Yuna | Timeout 10 s; rete/status non utile/JSON inatteso → lista vuota |
| AniList | Errori trasporto/non-2xx/JSON → null; ricerca converte assenza in lista vuota; deadline 20 s/4 MiB per tentativo; 429 fino a due retry solo se l’attesa richiesta è interpretabile e rientra nel budget di 60 s |
| Steam | Non-200 → `SteamException`; fallback trailer gestito dal provider; apiRequest: timeout/abort 20 s, 4 MiB, no redirect |
| GitHub | Timeout 15 s; errori di trasporto → `UpdateNoConnection`; 404 → `UpdateNoReleases`; rate limit → `UpdateRateLimited`; formato inatteso → eccezione update tipizzata |
| Download immagini widget | Timeout 10 s e condivisione Future per URL; errore → nessun nuovo file |
| Ricezione sync HTTP | Solo endpoint RFC1918 validato, no redirect, 10 s/2 MiB; non-200 fallisce prima dell'import |

- AniList passa da `AniListQueue`: 12 token/10 s, massimo tre lavori concorrenti.
  I retry 429 sono interni al lavoro già accodato, non nuove enqueue indipendenti.
- Su 429, `Retry-After` espresso come intero da 0 a 60 secondi viene rispettato
  integralmente: non viene troncato. Se supera 60 secondi, è negativo o non è
  interpretabile come numero di secondi, il tentativo termina senza retry,
  restituendo il fallback null/vuoto già previsto. Questo include formati non
  supportati e numeri fuori intervallo, senza attese illimitate. Soltanto in
  assenza dell’header resta l’attesa predefinita di 10 secondi. Non vengono
  introdotti coordinamenti o retry esterni a `AniListQueue`.
- Riverpod non ritenta automaticamente: `noProviderRetry` è obbligatorio.
- Non generalizzare “ogni errore produce un'eccezione”: Yuna/AniList e contenuti
  opzionali hanno contratti null/vuoto propri.
- Per GitHub, il codice riconosce 429 o segnali di rate limit nel 403;
  un 403 generico non significa necessariamente quota esaurita.

## Offline e cache

- Solo errori recuperabili della pipeline serie possono produrre snapshot locali:
  `http.ClientException`, `SocketException`, `TimeoutException`, TMDB 5xx.
- TMDB 401/403/404 non diventano successi offline. Anche un errore di parsing
  non è automaticamente un problema di connessione.
- `rawShowDetailProvider` condivide il dettaglio grezzo; dettaglio online riuscito
  ha una retention breve di 30 secondi. Il fallback parziale non riceve la stessa retention.
- Cache persistita e TTL: [03](03-data-local-storage.md). Pipeline anime: [09](09-anime-pipeline.md).
- Messaggi della ricerca: `lib/features/search/presentation/widgets/search_error_message.dart`.
  Non interpolare eccezioni tecniche direttamente nelle nuove schermate.

## Test di confine

`test/core/network/tmdb_http_client_test.dart`,
`test/features/series/{tmdb_service,anilist_service,anilist_queue,yuna_service}_test.dart`,
`test/features/games/rawg_service_test.dart`, `test/features/update/github_release_service_test.dart`.
Usare client simulati; non servono richieste reali per verificare questi contratti.

Le risposte/URL e le eccezioni grezze non vengono loggati. AppInterceptor.close
chiude il client sottostante e rifiuta nuovi invii dopo la chiusura. I client
auth richiedono HTTPS/443 anche se usati fuori da apiRequest.
