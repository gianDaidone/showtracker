import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Permesso Android «Installa app sconosciute» (REQUEST_INSTALL_PACKAGES).
///
/// `ota_update` non lo controlla: lancia l'intent di installazione e basta, e
/// se il permesso manca Android blocca l'installazione *dopo* il download.
/// Lo verifichiamo prima tramite il canale nativo in `MainActivity.kt`.
class InstallPermission {
  static const _channel = MethodChannel('showtracker/install_permission');

  /// `true` se l'app può già aprire l'installer di sistema.
  static Future<bool> isGranted() async {
    try {
      return await _channel.invokeMethod<bool>('canRequestPackageInstalls') ??
          false;
    } on MissingPluginException {
      // Piattaforma senza il canale nativo: lascia decidere ad Android.
      return true;
    }
  }

  /// Apre la schermata di sistema del permesso e attende che l'utente torni
  /// nell'app; restituisce lo stato del permesso a quel punto.
  static Future<bool> requestViaSettings() async {
    final resumed = Completer<void>();
    final listener = AppLifecycleListener(
      onResume: () {
        if (!resumed.isCompleted) resumed.complete();
      },
    );
    try {
      final opened =
          await _channel.invokeMethod<bool>('openInstallSettings') ?? false;
      if (!opened) return false;
      await resumed.future;
    } finally {
      listener.dispose();
    }
    return isGranted();
  }
}
