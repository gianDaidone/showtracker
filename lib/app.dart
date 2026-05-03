import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'features/series/providers/series_providers.dart';

class ShowTrackerApp extends ConsumerStatefulWidget {
  const ShowTrackerApp({super.key});

  @override
  ConsumerState<ShowTrackerApp> createState() => _ShowTrackerAppState();
}

class _ShowTrackerAppState extends ConsumerState<ShowTrackerApp> {
  @override
  void initState() {
    super.initState();
    // Re-schedule notifications for all actively-tracked shows once at
    // startup. Mark-watched and similar events only schedule if TMDB's
    // next_episode_to_air points to a future date, but that field can lag
    // by ~1 day so individual schedule attempts may silently skip. Running
    // here ensures stale state is corrected the next time the app opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(trackedShowsNotifierProvider.notifier)
          .rescheduleAllNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Show Tracker',
      theme: AppTheme.dark(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
