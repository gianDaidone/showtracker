import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/sync_progress.dart';

final syncAndroidBridgeProvider = Provider<SyncAndroidBridge>((ref) {
  final bridge = SyncAndroidBridge();
  ref.onDispose(bridge.dispose);
  return bridge;
});

/// Un solo writer serializzato aggiorna la notifica posseduta dal servizio.
class SyncAndroidBridge {
  static const channel = MethodChannel('showtracker/sync');
  Future<void> _writes = Future.value();
  Timer? _timer;
  SyncProgress? _latest;
  bool _disposed = false;
  bool _canPublish = false;
  void Function()? onShow;

  void onStop(void Function() callback) {
    channel.setMethodCallHandler((call) async {
      if (call.method == 'timeout') callback();
      if (call.method == 'show') onShow?.call();
    });
  }

  Future<({bool available, bool notifications})> start() async {
    await _writes;
    try {
      final result = await channel.invokeMapMethod<String, dynamic>('start');
      _canPublish = result != null;
      return (
        available: result?['available'] == true,
        notifications: result?['notifications'] == true
      );
    } on PlatformException {
      return (available: false, notifications: false);
    } on MissingPluginException {
      return (available: false, notifications: false);
    }
  }

  Future<void> openNotificationSettings() async {
    try {
      await channel.invokeMethod<void>('settings');
    } on PlatformException {
      // Nessuna modifica ai dati se le impostazioni non sono disponibili.
    } on MissingPluginException {
      // Piattaforma senza Android.
    }
  }

  void publish(SyncProgress progress) {
    if (_disposed || !_canPublish) return;
    _latest = progress;
    if (!progress.active) {
      _timer?.cancel();
      _timer = null;
      _flush();
    } else {
      _timer ??= Timer(const Duration(seconds: 1), () {
        _timer = null;
        _flush();
      });
    }
  }

  void _flush() {
    final progress = _latest;
    _latest = null;
    if (progress == null || _disposed) return;
    _writes = _writes.then((_) async {
      if (_disposed) return;
      try {
        await channel.invokeMethod<void>('update', {
          'title': progress.heading,
          'body': progress.needsGameAcknowledgement
              ? 'Elenco giochi salvato. Apri l’app per continuare.'
              : progress.counter,
          'total': progress.total,
          'processed': progress.processed,
          'finished': !progress.active,
        });
      } on PlatformException {
        // La notifica non rende fallita un'importazione già commessa.
      } on MissingPluginException {
        // Runner desktop e test senza runtime Android.
      }
    });
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
    channel.setMethodCallHandler(null);
  }
}
