# ShowTracker — Project Context

## Overview

**ShowTracker** is a local-first media tracker for TV shows, movies, and games built with Flutter. All data persists on-device in SQLite via Drift. The UI language is **Italian** (e.g., "Serie", "Film", "Giochi", "In Uscita") — all new user-facing strings must follow this convention.

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (Dart ≥ 3.3.0) |
| State Management | Riverpod 2 (`flutter_riverpod` + `riverpod_annotation` + `riverpod_generator`) |
| Local Database | Drift 2 (SQLite via `drift_flutter` + `sqlite3_flutter_libs`) |
| Navigation | GoRouter 14 (`StatefulShellRoute`) |
| HTTP | `http` package |
| Image Caching | `cached_network_image` |
| Notifications | `flutter_local_notifications` + `timezone` / `flutter_timezone` |
| Code Generation | `build_runner`, `drift_dev`, `riverpod_generator` |
| Theme | Material 3, dark-only (`AppTheme.dark()`) |
| Assets | SVGs (`flutter_svg`), images under `assets/images/` |

### External APIs

| API | Purpose |
|---|---|
| **TMDB** | Primary metadata source for shows & movies (REST) |
| **RAWG** | Game metadata (REST) |
| **Yuna.moe** | Maps TMDB IDs → AniList IDs (cached 7 days) |
| **AniList** | Accurate anime episode counts & airing timestamps (GraphQL) |

---

## Architecture

### Layer Model (per feature)

```
features/<name>/
  data/           ← API services, raw API models
  presentation/   ← Screens & widgets
  providers/      ← Riverpod providers (generated via @riverpod)
```

- **Services** make raw HTTP calls and return typed models.
- **Providers** wrap services; mutable state uses `StateNotifier` subclasses that write through to Drift.
- **Screens/Widgets** consume providers via `ConsumerWidget` / `ConsumerStatefulWidget`.

### State Management Rules

- All state goes through **Riverpod**. No `setState` for shared/global state.
- Services are singletons exposed as `@riverpod` generators (e.g., `tmdbServiceProvider`).
- Async data fetching uses `FutureProvider` / `AsyncNotifier`.
- Mutable tracked collections use `StateNotifier` → writes through to the Drift DAO.
- Generated files end in **`.g.dart`** — never edit them manually.

### Database — Drift (SQLite)

- Single database class: `AppDatabase` (singleton pattern) at `lib/core/database/app_database.dart`.
- **Current schema version: 9**.
- When adding a table or column, **bump the schema version** and add a migration step in `MigrationStrategy.onUpgrade`.

**Tables:**

| Table | Purpose |
|---|---|
| `TrackedShows` | User's tracked TV series |
| `TrackedEpisodes` | Per-episode watch state |
| `TrackedSeasons` | Per-season watch state |
| `CachedEpisodes` | Episode metadata cache from TMDB/AniList |
| `TrackedMovies` | User's tracked movies |
| `TrackedGames` | User's tracked games (uses RAWG IDs) |
| `YunaCache` | TMDB ID → AniList ID mapping (TTL 7 days) |
| `AnimeSeasonCache` | Normalised AniList season data cache |

**DAOs:** `ShowsDao`, `MoviesDao`, `GamesDao`, `CacheDao`, `AnimeCacheDao` — exposed as Riverpod providers from `lib/core/database/database_provider.dart`.

### Routing — GoRouter

Defined in `lib/core/router/app_router.dart`. Uses `StatefulShellRoute.indexedStack` with **5 branches** (state preserved across tab switches):

| Branch | Path | Nav Bar |
|---|---|---|
| Series | `/series` | ✅ Visible |
| Movies | `/movies` | ✅ Visible |
| Games | `/games` | ✅ Visible |
| Search | `/search` | ❌ Hidden |
| Debug | `/debug` | ❌ Debug builds only (`kDebugMode`) |

Detail screens are full-screen pushes **outside** the shell:

- `/series/list`, `/series/detail/:id`
- `/movies/list`, `/movies/detail/:id`
- `/games/list`, `/games/search`, `/games/detail/:id`

### Anime Support (Multi-API Pipeline)

Anime detection: a show is anime when it has the **Animation** genre **and** an origin country in `{JP, KR, CN, TW, HK}`.

Pipeline:
1. **TMDB** — primary show/episode metadata
2. **Yuna.moe** → maps TMDB ID to AniList ID (7-day cache in `YunaCache`)
3. **AniList** (GraphQL) → accurate episode counts, season boundaries, precise airing timestamps
4. **`AnimeDataMerger`** → normalises TMDB + AniList into a unified model for the UI

Cache TTLs: ended anime → 30 days; currently-airing → 1–7 days.

For anime, notification scheduling uses AniList's exact airing time; for regular shows it defaults to **09:00**.

### Notifications

Managed by `lib/core/services/notification_service.dart`. Notifications are cancelled and rescheduled whenever episode data is refreshed. On app startup, `rescheduleAllNotifications()` runs to correct any stale scheduled state.

---

## Folder Structure

```
showtracker/
├── lib/
│   ├── main.dart                        # Entry point
│   ├── app.dart                         # ShowTrackerApp (ConsumerStatefulWidget)
│   ├── core/
│   │   ├── constants/
│   │   │   ├── api_endpoints.dart       # TmdbEndpoints, RawgEndpoints
│   │   │   └── api_keys.dart            # API key constants
│   │   ├── database/
│   │   │   ├── app_database.dart        # @DriftDatabase, schema, migrations
│   │   │   ├── database_provider.dart   # Riverpod providers for DAOs
│   │   │   ├── tables/                  # Drift table definitions
│   │   │   └── daos/                    # DAO implementations
│   │   ├── network/
│   │   │   └── http_client.dart         # Shared HTTP client
│   │   ├── router/
│   │   │   └── app_router.dart          # GoRouter config
│   │   ├── services/
│   │   │   ├── notification_service.dart
│   │   │   └── app_toast.dart
│   │   ├── shell/
│   │   │   └── main_shell.dart          # Bottom nav shell widget
│   │   └── theme/
│   │       └── app_theme.dart           # AppTheme.dark(), AppColors
│   ├── features/
│   │   ├── series/
│   │   │   ├── data/
│   │   │   │   ├── tmdb_service.dart
│   │   │   │   ├── anilist_service.dart
│   │   │   │   ├── yuna_service.dart
│   │   │   │   ├── anilist_queue.dart
│   │   │   │   ├── anime_data_merger.dart
│   │   │   │   └── models/              # TmdbShow, TmdbShowDetail, TmdbEpisode,
│   │   │   │                            # TmdbSeason, AnilistMedia, NormalizedAnimeSeason
│   │   │   ├── presentation/
│   │   │   │   ├── next_episodes_screen.dart
│   │   │   │   ├── series_screen.dart
│   │   │   │   ├── show_detail_screen.dart
│   │   │   │   ├── search_shows_screen.dart
│   │   │   │   └── widgets/             # ShowCard, EpisodeTile, SeasonSection,
│   │   │   │                            # EpisodeDetailSheet, NextEpisodeCard,
│   │   │   │                            # UpcomingEpisodeCard
│   │   │   └── providers/
│   │   │       ├── series_providers.dart
│   │   │       └── series_providers.g.dart
│   │   ├── movies/
│   │   │   ├── data/models/
│   │   │   ├── presentation/            # MoviesScreen, MoviesListScreen,
│   │   │   │                            # MovieDetailScreen, SearchMoviesScreen
│   │   │   └── providers/
│   │   ├── games/
│   │   │   ├── data/
│   │   │   │   ├── rawg_service.dart
│   │   │   │   └── models/
│   │   │   ├── presentation/            # GamesScreen, GamesListScreen,
│   │   │   │                            # GameDetailScreen, SearchGamesScreen
│   │   │   └── providers/
│   │   ├── search/
│   │   │   ├── presentation/            # SearchScreen (cross-content)
│   │   │   └── providers/
│   │   └── debug/
│   │       └── debug_screen.dart        # Debug-only screen
│   ├── models/                          # (reserved)
│   ├── services/                        # (reserved)
│   └── shared/
│       └── widgets/                     # (reserved for cross-feature widgets)
├── assets/
│   └── images/
├── pubspec.yaml
├── analysis_options.yaml
└── CLAUDE.md                            # Agent guidance file
```

---

## Key Conventions

### Code Generation

Run after changing any `@riverpod` provider or Drift table definition:

```bash
# One-shot regeneration
flutter pub run build_runner build --delete-conflicting-outputs

# Watch mode during development
flutter pub run build_runner watch --delete-conflicting-outputs
```

Never edit `*.g.dart` files manually.

### Theming

- Dark mode only — use `AppTheme.dark()` and `AppColors` constants from `lib/core/theme/app_theme.dart`.
- Color palette:
  - Background: `#161622`
  - Surface: `#1E1E2E`
  - Accent: `#E68A00` (amber)
  - Text primary: `#FFFFFF`
  - Text secondary: `#9A9AB0`
  - Divider: `#2C2C3E`
- Material 3 (`useMaterial3: true`).

### UI Language

All user-facing strings are in **Italian**. New strings must follow existing patterns:
- "Serie" (TV Shows)
- "Film" (Movies)
- "Giochi" (Games)
- "In Uscita" (Upcoming)

### Adding a New Content Domain

1. Create `lib/features/<name>/data/`, `presentation/`, `providers/`.
2. Add any new DB tables to `lib/core/database/tables/`, bump `schemaVersion`, add migration.
3. Create a DAO in `lib/core/database/daos/` and register it in `@DriftDatabase` and `database_provider.dart`.
4. Add routes to `app_router.dart` and a new branch in `StatefulShellRoute`.
5. Re-run `build_runner`.

### Adding a New DB Column / Table

1. Edit the table definition in `lib/core/database/tables/`.
2. Increment `schemaVersion` in `app_database.dart`.
3. Add the migration step inside `MigrationStrategy.onUpgrade` guarded by `if (from < N)`.
4. Regenerate: `flutter pub run build_runner build --delete-conflicting-outputs`.

### Running the App

```bash
flutter run     # Run on connected device/emulator
flutter test    # Run all tests
```
