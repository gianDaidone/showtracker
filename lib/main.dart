import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/services/notification_service.dart';
import 'core/services/startup_coordinator.dart';
import 'core/constants/api_keys.dart';
import 'core/riverpod_utils.dart';

void main() async {
  runZoned(() async {
    WidgetsFlutterBinding.ensureInitialized();

    if (kReleaseMode) {
      debugPrint = (String? message, {int? wrapWidth}) {};
    }

    // I --dart-define sono compile-time: se l'app viene avviata senza passarli,
    // ApiKeys.tmdb resta vuota e OGNI chiamata a TMDB risponde 401. Senza
    // questo avviso il sintomo è una schermata vuota senza spiegazione.
    if (kDebugMode && ApiKeys.tmdb.isEmpty) {
      debugPrint(
        '⚠️  TMDB_KEY non definita: le chiamate a TMDB falliranno con 401.\n'
        '    Avvia con: flutter run --dart-define-from-file=dart_defines/dev.json\n'
        '    In Android Studio: Run > Edit Configurations > Additional run args.',
      );
    }

    await NotificationService.init();

    // Crea un container globale per poterlo passare ai widget
    final container = ProviderContainer(retry: noProviderRetry);

    final startup = StartupCoordinator(container);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(startup.start());
    });

    runApp(
      UncontrolledProviderScope(
        container: container,
        child: const ShowTrackerApp(),
      ),
    );
  }, zoneSpecification: ZoneSpecification(
    print: (Zone self, ZoneDelegate parent, Zone zone, String line) {
      if (!kReleaseMode) {
        parent.print(zone, line);
      }
    },
  ));
}
