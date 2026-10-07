# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Run the app (games are gated by kEnableGames in lib/core/constants.dart)
flutter run

# With app-level API keys — needed for the TMDB browser login flow and as
# fallback when the user hasn't supplied their own key (see "Auth & API keys")
flutter run --dart-define-from-file=dart_defines/dev.json
flutter run --dart-define=TMDB_KEY=... --dart-define=RAWG_KEY=...

# Tests — a smoke test in test/widget_test.dart plus unit tests in test/features/
flutter test
flutter test test/widget_test.dart --plain-name 'App smoke test'   # single test

# Static analysis (flutter_lints + extra rules in analysis_options.yaml)
flutter analyze

# Regenerate code (Riverpod + Drift) — required after changing annotated
# providers or DB tables
flutter pub run build_runner build --delete-conflicting-outputs
flutter pub run build_runner watch --delete-conflicting-outputs
```

Generated files end in `.g.dart` — never edit them directly.

## Architecture

Local-first media tracker (TV shows, movies, games). All user data lives on-device in SQLite via Drift; remote APIs supply only metadata and are cached in the same database.

### Feature structure

Code lives in `lib/features/` with three content domains — **series**, **movies**, **games** — plus **search** (cross-content), **settings**, **onboarding**, **sync**, **update** (in-app APK updates), and **debug** (mounted only in debug builds). Each follows `data/ → providers/ → presentation/`: services make raw API calls and return typed models, providers wrap services and DAOs, screens/widgets consume providers via `ConsumerWidget`/`ConsumerStatefulWidget`.

`lib/models/`, `lib/services/`, `lib/shared/` are empty placeholders — don't put new code there.

### State management — Riverpod

All shared state is Riverpod; no `setState` beyond local widget state. Services are exposed via `@riverpod` generators (e.g. `tmdbServiceProvider`). Async reads use `FutureProvider`/`StreamProvider`; mutable tracked content uses notifier subclasses that write through to the Drift DAO, and the notifier's `build()` returns the DAO's `watch*` stream — so UI updates flow back from the database rather than from in-memory mutation.

`lib/features/series/providers/series_providers.dart` (~880 lines) is the centre of gravity: it owns `TrackedShowsNotifier` (add/remove/status/`syncMetadata` + notification scheduling) plus the cached `showDetail`/`seasonDetail`/`animeData` chain. Read it before changing series behaviour.

**The "Da Vedere" list has exactly one authority.** `visibleWatchingShowsProvider` (same file) decides which watching shows have something to watch; the list *and* the "Da Vedere (n)" header are the same value, and `NextEpisodeCard` applies the same rules — `lib/features/series/data/watch_next_rules.dart`, shared by both — so a card can never hide itself while the header still counts it. When the card ends up with fresher TMDB data than the provider had and hides anyway, it invalidates the provider once to let the count catch up. Never reimplement "which episode is next" or "has it aired" in either place; change the rules file.

Related: the denormalised `TrackedShows.nextEpisode*` pointer must never lag behind an already-aired episode — `TrackedShowsNotifier._resolveNextEpisode` advances past it, because TMDB's `next_episode_to_air` keeps pointing at the just-aired episode for hours. A stale pointer suppresses the notification, lists an aired episode under "In Uscita", and breaks the offline "has it aired?" fallback.

### Database — Drift (SQLite)

`lib/core/database/app_database.dart` — single `AppDatabase` singleton (`AppDatabase.instance`), schema **v14**. Tables: `TrackedShows`, `TrackedEpisodes`, `TrackedSeasons`, `TrackedMovies`, `TrackedGames`, `CachedEpisodes`, `YunaCache`, `AnimeSeasonCache`. DAOs (`ShowsDao`, `MoviesDao`, `GamesDao`, `CacheDao`, `AnimeCacheDao`) are exposed as Riverpod providers from `lib/core/database/database_provider.dart`.

To add a column or table: edit `tables/`, bump `schemaVersion`, add an `if (from < N)` step in `MigrationStrategy.onUpgrade`, regenerate. Existing migrations show the patterns for table rebuilds (v8) and backfills (v13, v14).

Two denormalisations matter:

- `TrackedShows.nextEpisode{Number,Season,Name,AirDate}` cache the next airing episode so the "In Uscita" screen and the home widgets render offline without hitting TMDB. Refreshed by `syncMetadata`.
- `updatedAt` on shows/episodes/movies/games exists for sync conflict resolution (added in v13).

### Routing — GoRouter

`lib/core/router/app_router.dart`. A top-level `redirect` gates everything on `authControllerProvider`: unauthenticated users go to `/onboarding`, authenticated users are bounced off it.

`StatefulShellRoute.indexedStack` has six branches, and **branch indices are hardcoded in `MainShell`'s tab table** — adding or reordering a branch means updating `lib/core/shell/main_shell.dart` too:

| index | path | nav bar |
|---|---|---|
| 0 | `/series` | Serie |
| 1 | `/movies` | Film |
| 2 | `/games` | Giochi (only if `kEnableGames`) |
| 3 | `/settings` | Profilo |
| 4 | `/search` | hidden |
| 5 | `/debug` | debug builds only |

Detail/list screens (`/series/detail/:id`, `/movies/list`, `/games/search`, `/sync`, …) are full-screen pushes outside the shell.

### Auth & API keys

`lib/core/auth/auth_state.dart` and `rawg_auth_state.dart` hold sealed `AuthState`/`RawgAuthState` hierarchies persisted in `flutter_secure_storage`. TMDB supports either a real session (flow in `OnboardingScreen`: request token → browser → `showtracker://auth` deep link via `app_links`) or a user-supplied API key. RAWG is API-key only.

`AppInterceptor` (`lib/core/network/tmdb_http_client.dart`) is an `http.BaseClient` that rewrites outgoing query params per host, injecting `api_key`/`session_id` for `api.themoviedb.org` and `key` for `api.rawg.io`. Services never handle keys themselves — construct them with an interceptor-wrapped client, as `tmdbServiceProvider` does.

App-level fallback keys come **only** from `lib/core/constants/api_keys.dart` (`ApiKeys.tmdb`, `ApiKeys.rawg` — `String.fromEnvironment`, empty by default). Pass them at build time:

```bash
flutter run --dart-define-from-file=dart_defines/dev.json   # gitignored; copy dart_defines/dev.example.json
```

`lib/core/constants.dart` keeps only non-secret values (`kTmdbImageBase`, `kEnableGames`) — never put a key back there, it's tracked by git. Besides the interceptor, `ApiKeys.tmdb` is needed by the three TMDB auth calls that can't use a session: request-token and session creation in `OnboardingScreen`, and session deletion in `TmdbAccountSection`. With no key defined those return 401, which surfaces as a message pointing at `--dart-define`.

Note that `--dart-define` keeps keys out of the repo but **not** out of a shipped APK — they compile to string constants in the binary. Any key shipped to users should be treated as public.

### Anime support (multi-API pipeline)

A show is anime when `TmdbShowDetail.isAnime`: Animation genre (matched in English *or* Italian) **and** an origin country in `{JP, KR, CN, TW, HK}`.

1. **TMDB** — primary show/episode metadata. TMDB can serve a stale, empty `/season/{n}` for days while the individual episodes already resolve (Black Clover 73223 S2 after its episodes moved from 336735; `max-age` doesn't count down), so `getSeasonDetails` falls back to fetching `/episode/{k}` in batches until a 404 — non-404 errors propagate so a partial list never gets cached
2. **Yuna.moe** — maps TMDB ID → AniList ID (cached 7 days in `YunaCache`). When Yuna has no mapping (common for sequels TMDB publishes as a separate entry, e.g. Black Clover S2 = TMDB 336735), `_searchAniListByTmdbTitles` searches AniList by title and `_pickAniListCandidate` picks the candidate whose `startDate` is closest to TMDB's first air date (±60 days) — never just the top hit, which for a sequel sharing the original's title is the original series. Yuna's mappings are curated by hand upstream and lag new seasons by days or weeks, so after merging, `_searchUnmappedSeasons` looks up any TMDB season left as a placeholder (`anilistId == -1`, no cour mapped) by title + that season's `air_date`, excluding IDs already known, and re-merges (e.g. Black Clover 2nd Season, AniList 195604, as TMDB 73223 S2 when Yuna knew only the 2017 series)
3. **AniList** (GraphQL) — accurate episode counts, season/cour boundaries, precise airing timestamps. All requests go through `AniListQueue`, a token bucket (12 tokens / 10 s, max 3 concurrent) — never call the AniList service outside it.
4. **`AnimeDataMerger`** — normalises TMDB seasons + AniList media into `NormalizedAnimeSeason`, preferring `TV`/`TV_SHORT` formats and falling back to `ONA` only when no TV entry exists.

`showDetailProvider` then synthesises a `TmdbSeason` list from the normalised data (splitting a TMDB season into "Parte N · cour label" entries) so the existing season UI works unchanged. TMDB often groups multiple cours into one season, so raw TMDB episode totals are wrong for anime — `addShow` deliberately awaits AniList data before persisting totals.

Cache TTLs are content-aware (`_seasonCacheTtl` + `NormalizedAnimeSeason.cacheTtl`): ended/cancelled → 30 days, current season → 1 day, older seasons → 7 days. A `RELEASING` cour's TTL expires *at the next episode's airing time*, so the expensive path runs exactly when the user opens the app to mark that episode watched.

**Anime data must never silently degrade to raw TMDB.** Cour numbers are synthetic (1..N) and watched episodes are stored against them, so raw TMDB seasons are a different, incompatible numbering — falling back to them shows nonsense ratios ("11/23"), 404s `seasonDetail` on cours TMDB doesn't have, and corrupts `TrackedSeasons` on the next sync. Hence: `animeData` falls back to `getStaleAnimeSeasons` (expired cache) rather than returning null; `seasonDetail` refuses to ask TMDB for a season number TMDB doesn't list; and `syncMetadata` is a no-op when `isAnime && animeSeasonsData == null`.

That fallback only works while the cache still holds something, so **the anime cache is expired, never deleted** — `AnimeCacheDao.expireAnimeCacheForShow` backdates `validUntil` (and the Yuna row) so a manual refresh forces a refetch without throwing away the only copy of the cour data. Since rows are never deleted, `saveAnimeSeasons` must upsert on the unique key `(tmdbShowId, seasonNumber)` — `insertOnConflictUpdate` targets the autoincrement `id` and fails with `UNIQUE constraint failed` on every save after the first (this froze every anime's cache from 2026-09-07 to 2026-10-01). The refresh button checks `getFreshAnimeSeasons` afterwards, so a refresh that silently fell back to the expired copy reports an error instead of success. AniList outages happen (on 2026-09-07 every query got a blanket 403, "temporarily disabled due to severe stability issues"); when one does, `NextEpisodeCard` keeps using the cour-based `TrackedSeasons` counts instead of `detail.seasons`, and the detail page shows a banner telling the user not to mark episodes against the raw TMDB numbering.

### Notifications

`lib/core/services/notification_service.dart` wraps `flutter_local_notifications` + `timezone` behind a static API with an in-memory registry of scheduled IDs. Episode notifications are cancelled and rescheduled whenever episode data is refreshed; anime use AniList's exact airing time, regular shows default to 09:00. `rescheduleAllNotifications()` runs at startup (from both `main.dart` and `ShowTrackerApp.initState`) because TMDB's `next_episode_to_air` can lag ~1 day, so individual schedule attempts silently skip past dates.

### Home screen widgets

`lib/widgets_manager.dart` drives two Android widgets (`MaratonaWidgetProvider`, `ProssimamenteWidgetProvider` in `android/app/src/main/java/com/example/showtracker/`) through `home_widget`. `main.dart` creates a **global `ProviderContainer`** (handed to `UncontrolledProviderScope`) and listens to `watchingShowsWithEpisodesProvider` / `upcomingEpisodesProvider` to push updates — that container must stay alive, so don't dispose it or the database closes under the widgets. The `@pragma('vm:entry-point') backgroundCallback` handles widget taps (e.g. `mark_watched`) in a separate isolate with its own short-lived container.

### P2P sync

`lib/features/sync/` exchanges tracked state between two devices on the same LAN, with no server. `SyncService.exportData()` builds a `SyncPayload` in which watched episodes are compacted to range strings (`RangeUtils`, `"1-3,5"`), `SyncCompressor` zlib+base64-encodes it, and `LocalSyncServer` (shelf, port 8080, random token) serves it at `/sync?token=…`. The receiving device scans a QR of that URL (`mobile_scanner`). Import runs in one transaction and resolves conflicts per item by `updatedAt` (last write wins).

### In-app update (GitHub Releases)

The app is distributed as an APK, not through a store. `lib/features/update/` adds a "Cerca aggiornamenti" row (`AppUpdateTile`, built on the shared `SettingsTile` in `lib/features/settings/presentation/widgets/`) to Profilo; the check runs **only** when tapped — never at startup or in the background. `GithubReleaseService` reads `releases/latest` for `kGithubRepo` (`lib/core/constants.dart`) without a token (60 req/h per IP; 403 + `x-ratelimit-remaining: 0` → `UpdateRateLimited`), picks the first asset ending in `.apk`, and `AppVersion` compares `major.minor.patch` only (ignores `v` and `+build`). Every failure is an `UpdateException` subclass carrying its Italian message.

`ota_update` downloads and fires the system installer, but it never checks Android's "Installa app sconosciute" permission — its `PERMISSION_NOT_GRANTED_ERROR` is effectively unreachable. So `InstallPermission` (MethodChannel `showtracker/install_permission`, handled in `MainActivity.kt`) checks `canRequestPackageInstalls()` *before* downloading and, if needed, opens the settings page and re-checks on resume.

To publish an update: bump **both** parts of `version:` in `pubspec.yaml` (the name is what the app compares; Android refuses an install whose `versionCode` isn't higher), sign with the same `key.properties` keystore (a different signature makes the install fail), and attach the APK to a non-draft, non-prerelease GitHub release tagged e.g. `v1.0.1`.

`package_info_plus` is pinned to 9.x: 10.x needs `win32` 6, which conflicts with `network_info_plus` 5 (sync). 9.x needs AGP ≥ 8.12.1.

## Conventions

- **UI language is Italian** — "Serie", "Film", "Giochi", "In Uscita", "Profilo". All new user-facing strings follow suit, including widget text and month abbreviations. Code comments are mixed Italian/English; match the surrounding file.
- **Dark theme only** — use `AppTheme.dark()` and `AppColors` from `lib/core/theme/app_theme.dart` (bg `#161622`, surface `#1E1E2E`, accent `#E68A00`), Material 3.
- `avoid_print` is enforced; use `debugPrint`, which `main.dart` silences in release via a custom zone.
- `scratch*.dart` and `db.sqlite` at the repo root are throwaway dev artifacts, not part of the app.
