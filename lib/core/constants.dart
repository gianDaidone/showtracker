// Le chiavi API non vivono più qui: vedi `constants/api_keys.dart`, che le
// legge dai `--dart-define` (TMDB_KEY, RAWG_KEY). Non reintrodurre segreti in
// questo file — è tracciato da git.

/// Base URL per le immagini TMDB.
const kTmdbImageBase = 'https://image.tmdb.org/t/p';

/// Feature flag per abilitare/disabilitare i videogiochi.
/// Di default è disabilitato (false) finché non sarà pronta un'infrastruttura sicura.
/// Compila con: --dart-define=ENABLE_GAMES=true per attivarlo.
const kEnableGames = true;

/// Repository GitHub (pubblico) da cui "Cerca aggiornamenti" legge l'ultima
/// release e scarica l'APK. Formato `owner/repo`.
const kGithubRepo = 'gianDaidone/showtracker';
