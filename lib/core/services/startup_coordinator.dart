import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_state.dart';
import '../riverpod_utils.dart';
import '../../features/series/providers/series_providers.dart';
import '../../features/sync/providers/metadata_recovery_provider.dart';
import '../../widgets_manager.dart';
import 'notification_service.dart';

/// Un solo proprietario del lavoro differibile. Il container appartiene all'app,
/// non al bootstrap: deve restare vivo per i listener dei widget Android.
class StartupCoordinator {
  StartupCoordinator(
    this.container, {
    Future<void> Function()? setupWidgets,
    Future<void> Function()? requestPermission,
    Future<void> Function()? refreshWidgets,
    Future<void> Function()? refreshMetadata,
  })  : _setupWidgets = setupWidgets ?? ShowTrackerWidgetsManager.setup,
        _requestPermission =
            requestPermission ?? NotificationService.requestPermission,
        _refreshWidgets = refreshWidgets ??
            (() =>
                ShowTrackerWidgetsManager.updateWidgets(container: container)),
        _refreshMetadata = refreshMetadata ??
            (() => container
                .read(trackedShowsProvider.notifier)
                .rescheduleAllNotifications());

  final ProviderContainer container;
  final Future<void> Function() _setupWidgets;
  final Future<void> Function() _requestPermission;
  final Future<void> Function() _refreshWidgets;
  final Future<void> Function() _refreshMetadata;
  Future<void>? _started;
  bool _metadataStarted = false;

  Future<void> start() => _started ??= _start();

  Future<void> _start() async {
    // Installa i listener delle credenziali senza aspettare permessi notifiche.
    container.read(metadataRecoveryProvider);
    await Future.wait([_startWidgets(), _startMaintenance()]);
  }

  Future<void> _startWidgets() async {
    try {
      await _setupWidgets();
      await container.readFuture(authControllerProvider.future);
      container.listen(visibleWatchingShowsProvider, (_, next) {
        if (!next.isLoading && next.hasValue) _queueWidgets();
      }, fireImmediately: true);
      container.listen(upcomingEpisodesProvider, (_, next) {
        if (!next.isLoading && next.hasValue) _queueWidgets();
      }, fireImmediately: true);
      // Le prime emissioni avviano il refresh. Niente terzo passaggio esplicito.
    } catch (error) {
      debugPrint('Bootstrap widget non disponibile: $error');
    }
  }

  void _queueWidgets() {
    unawaited(_refreshWidgets().catchError((Object error) {
      debugPrint('Aggiornamento widget fallito: $error');
    }));
  }

  Future<void> _startMaintenance() async {
    try {
      await _requestPermission();
    } catch (error) {
      debugPrint('Richiesta permesso notifiche fallita: $error');
    }
    // Anche un primo login dopo onboarding deve avviare la manutenzione, ma
    // nessuna richiesta di metadata deve anticipare il ripristino credenziali.
    container.listen(authControllerProvider, (_, next) {
      final auth = next.value;
      if (!_metadataStarted && auth != null && auth is! Unauthenticated) {
        _metadataStarted = true;
        unawaited(_refreshMetadata().catchError((Object error) {
          debugPrint('Manutenzione di avvio fallita: $error');
        }));
      }
    }, fireImmediately: true);
  }
}
