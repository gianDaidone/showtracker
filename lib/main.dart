import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/services/notification_service.dart';
import 'widgets_manager.dart';
import 'features/series/providers/series_providers.dart';

void main() async {
  runZoned(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    if (kReleaseMode) {
      debugPrint = (String? message, {int? wrapWidth}) {};
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
