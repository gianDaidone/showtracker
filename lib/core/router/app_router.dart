import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/series/presentation/next_episodes_screen.dart';
import '../../features/series/presentation/series_screen.dart';
import '../../features/series/presentation/show_detail_screen.dart';
import '../../features/movies/presentation/movies_screen.dart';
import '../../features/movies/presentation/movies_list_screen.dart';
import '../../features/movies/presentation/movie_detail_screen.dart';
import '../../features/games/presentation/games_screen.dart';
import '../../features/games/presentation/games_list_screen.dart';
import '../../features/games/presentation/search_games_screen.dart';
import '../../features/games/presentation/game_detail_screen.dart';
import '../../features/search/presentation/search_screen.dart';
import '../../features/debug/debug_screen.dart';
import '../shell/main_shell.dart';
import '../services/app_toast.dart';

import '../../core/auth/auth_state.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/sync/presentation/sync_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authStateAsync = ref.watch(authControllerProvider);

  return GoRouter(
    navigatorKey: AppToast.navigatorKey,
    initialLocation: '/series',
    redirect: (context, state) {
      if (authStateAsync.isLoading) return null;

      final isGoingToOnboarding = state.matchedLocation == '/onboarding';
      
      final authState = authStateAsync.valueOrNull;
      final isAuthenticated = authState != null && authState is! Unauthenticated;

      if (!isAuthenticated && !isGoingToOnboarding) {
        return '/onboarding';
      }
      
      if (isAuthenticated && isGoingToOnboarding) {
        return '/series';
      }

      if (state.uri.path == '/') {
        return '/series';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      // ── Shell con bottom nav (stato preservato) ──────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/series',
                builder: (context, state) {
                  final tabStr = state.uri.queryParameters['tab'];
                  final tabIndex = int.tryParse(tabStr ?? '0') ?? 0;
                  return NextEpisodesScreen(initialTab: tabIndex);
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/movies',
                builder: (context, state) => const MoviesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/games',
                builder: (context, state) => const GamesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
          // ── 5° branch: Cerca (dentro la shell, senza voce nel nav bar) ──
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/search',
                builder: (context, state) => SearchScreen(
                  initialFilter: state.uri.queryParameters['filter'],
                ),
              ),
            ],
          ),
          // ── 5° branch: Debug (solo in debug mode) ────────────────────────
          if (kDebugMode)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/debug',
                  builder: (context, state) => const DebugScreen(),
                ),
              ],
            ),
        ],
      ),

      // ── Schermate full-screen Film (senza bottom nav) ────────────────────
      GoRoute(
        path: '/movies/list',
        builder: (context, state) => const MoviesListScreen(),
      ),
      GoRoute(
        path: '/movies/detail/:id',
        builder: (context, state) {
          final tmdbId = int.parse(state.pathParameters['id']!);
          return MovieDetailScreen(tmdbId: tmdbId);
        },
      ),

      // ── Schermate full-screen Serie (senza bottom nav) ───────────────────
      GoRoute(
        path: '/series/list',
        builder: (context, state) => const SeriesListScreen(),
      ),
      GoRoute(
        path: '/series/detail/:id',
        builder: (context, state) {
          final tmdbId = int.parse(state.pathParameters['id']!);
          return ShowDetailScreen(tmdbId: tmdbId);
        },
      ),

      // ── Schermate full-screen Giochi (senza bottom nav) ──────────────────
      GoRoute(
        path: '/games/list',
        builder: (context, state) => const GamesListScreen(),
      ),
      GoRoute(
        path: '/games/search',
        builder: (context, state) => const SearchGamesScreen(),
      ),
      GoRoute(
        path: '/games/detail/:id',
        builder: (context, state) {
          final rawgId = int.parse(state.pathParameters['id']!);
          return GameDetailScreen(rawgId: rawgId);
        },
      ),
      GoRoute(
        path: '/sync',
        builder: (context, state) => const SyncScreen(),
      ),
    ],
  );
});
