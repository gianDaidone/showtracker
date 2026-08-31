import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/services/notification_service.dart';
import 'widgets_manager.dart';
import 'features/series/providers/series_providers.dart';
import 'core/constants/api_keys.dart';

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
    final container = ProviderContainer();

    // Inizializza i widget nativi e le callback di background
    await ShowTrackerWidgetsManager.setup();
    
    // Popola i widget all'avvio dell'app usando il container (così non viene chiuso il DB)
    // Rimosso await per non bloccare il caricamento dell'interfaccia con richieste di rete
    ShowTrackerWidgetsManager.updateWidgets(container: container);
    
    // Mantieni i widget aggiornati in tempo reale quando il DB cambia
    container.listen(
      watchingShowsWithEpisodesProvider,
      (previous, next) {
        // Ignora gli stati di caricamento temporanei per evitare chiamate multiple
        if (!next.isLoading && next.hasValue) {
          ShowTrackerWidgetsManager.updateWidgets(container: container, watchingList: next.value);
        }
      },
    );
    container.listen(
      upcomingEpisodesProvider,
      (previous, next) {
        if (!next.isLoading && next.hasValue) {
          ShowTrackerWidgetsManager.updateWidgets(container: container);
        }
      },
    );
    // Avvia la sincronizzazione in background in modo silente (Offline-First sync)
    unawaited(container.read(trackedShowsNotifierProvider.notifier).rescheduleAllNotifications());

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
