# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Run the app
flutter run

# Run tests
flutter test

# Regenerate code (Riverpod + Drift) — required after changing annotated providers or DB tables
flutter pub run build_runner build --delete-conflicting-outputs

# Watch mode during development
flutter pub run build_runner watch --delete-conflicting-outputs
```

## Architecture

### Feature structure

Code lives in `lib/features/` with three content domains: **series** (TV shows), **movies**, **games**. Each feature follows `data/ → presentation/ → providers/` — services handle raw API calls, providers expose data to UI, screens/widgets consume providers.

A shared **search** feature handles cross-content discovery, and a **debug** feature is only mounted in debug builds.

### State management — Riverpod

All state is Riverpod. Services are singletons exposed via `@riverpod` generators (e.g., `tmdbServiceProvider`). Data fetching uses `FutureProvider`/`AsyncNotifier`. Mutable tracked content (shows, movies, games) uses `StateNotifier` subclasses that write through to the Drift database.

Generated files end in `.g.dart` — never edit them directly.

### Database — Drift (SQLite)

`lib/core/database/app_database.dart` is the single Drift database, currently at schema **v9**. Tables: `TrackedShows`, `TrackedEpisodes`, `TrackedSeasons`, `TrackedMovies`, `TrackedGames`, `CachedEpisodes`, `YunaCache`, `AnimeSeasonCache`. DAOs (ShowsDao, MoviesDao, GamesDao, CacheDao, AnimeCacheDao) are exposed as Riverpod providers in `lib/core/database/database_provider.dart`.

When adding a new table or column, bump the schema version and add a migration step.

### Routing — GoRouter

`lib/core/router/app_router.dart` uses `StatefulShellRoute` with five branches: Series, Movies, Games, Search (hidden from nav), Debug (debug only). Detail routes are full-screen pushes on top of their branch.

### Anime support (multi-API pipeline)

The Series feature has layered API integration:

1. **TMDB** — primary source for show metadata and episodes
2. **Yuna.moe** — maps TMDB IDs → AniList IDs (cached 7 days in `YunaCache`)
3. **AniList** (GraphQL) — provides accurate episode counts, season boundaries, and precise airing timestamps for anime
4. **AnimeDataMerger** — normalises TMDB + AniList data into a unified model consumed by the UI

A show is treated as anime when it has the Animation genre **and** an origin country in `{JP, KR, CN, TW, HK}`. For anime, notification scheduling uses AniList's exact airing time; for regular shows it defaults to 09:00.

Cache TTLs are content-aware: ended anime → 30 days, currently-airing → 1–7 days.

### Notifications

`lib/core/services/notification_service.dart` schedules local notifications. Episode notifications are cancelled and rescheduled whenever episode data is refreshed.

### UI language

All user-facing strings are in **Italian** (e.g., "Serie", "Film", "Giochi", "In Uscita"). Keep new UI text consistent with this.
