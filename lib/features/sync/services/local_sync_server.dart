import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:network_info_plus/network_info_plus.dart';
import '../utils/sync_limits.dart';
import '../utils/sync_encryption.dart';
import 'sync_receiver.dart';

/// Handler separato dal socket per verificare il protocollo senza usare la LAN.
Handler createSyncHandler(
    {required String token,
    required String base64Payload,
    DateTime? expiresAt,
    DateTime Function()? clock}) {
  final now = clock ?? DateTime.now;
  final deadline = expiresAt ?? now().add(SyncLimits.sessionDuration);
  final router = Router();
  router.get('/sync', (Request request) {
    final Map<String, List<String>> query;
    try {
      query = request.url.queryParametersAll;
    } on FormatException {
      return Response.forbidden('Invalid token');
    }
    if (!now().isBefore(deadline) ||
        request.headers.containsKey('origin') ||
        query.length != 1 ||
        query['token']?.length != 1 ||
        query['token']?.single != token) {
      return Response.forbidden('Invalid token');
    }
    return Response.ok(base64Payload, headers: {
      'Content-Type': 'text/plain',
      'Cache-Control': 'no-store',
      'X-Content-Type-Options': 'nosniff',
    });
  });
  return router.call;
}

class LocalSyncServer {
  HttpServer? _server;
  Timer? _expiry;
  int _generation = 0;
  final void Function()? onExpired;
  final Future<String?> Function()? _resolveAddress;
  final Future<HttpServer> Function(Handler, InternetAddress, int) _bind;
  LocalSyncServer({
    this.onExpired,
    Future<String?> Function()? resolveAddress,
    Future<HttpServer> Function(Handler, InternetAddress, int)? bind,
  })  : _resolveAddress = resolveAddress,
        _bind = bind ?? io.serve;

  bool get isRunning => _server != null;

  /// Starts the server and returns the endpoint URI (e.g. http://192.168.1.5:8080/sync?token=XYZ).
  /// If it cannot determine the IP, returns null.
  Future<String?> start(String base64Payload) async {
    final generation = ++_generation;
    await _close();
    if (generation != _generation) return null;
    if (base64Payload.length > SyncLimits.encodedBytes) {
      throw const FormatException('Trasferimento troppo grande.');
    }
    try {
      final ip = await (_resolveAddress ?? _getWifiIP)();
      if (generation != _generation ||
          ip == null ||
          !isPrivateSyncAddress(ip)) {
        return null;
      }
      final token = _generateToken();
      final encrypted = await SyncEncryption.encrypt(base64Payload, token);
      if (generation != _generation) return null;
      final server = await _bind(
          createSyncHandler(token: token, base64Payload: encrypted.body),
          InternetAddress(ip),
          8080);
      if (generation != _generation) {
        await server.close(force: true);
        return null;
      }
      server.idleTimeout = const Duration(seconds: 15);
      _server = server;
      _expiry = Timer(SyncLimits.sessionDuration, () {
        unawaited(stop());
        onExpired?.call();
      });
      return Uri(
              scheme: 'http',
              host: ip,
              port: server.port,
              path: '/sync',
              queryParameters: {'token': token},
              fragment: 'k=${encrypted.key}')
          .toString();
    } catch (_) {
      if (generation == _generation) await _close();
      debugPrint('Avvio server sync non riuscito.');
      return null;
    }
  }

  Future<void> stop() async {
    _generation++;
    await _close();
  }

  Future<void> _close() async {
    _expiry?.cancel();
    _expiry = null;
    final server = _server;
    _server = null;
    await server?.close(force: true);
  }

  String _generateToken() {
    final random = Random.secure();
    final values = List<int>.generate(16, (i) => random.nextInt(256));
    return base64UrlEncode(values).replaceAll('=', '');
  }

  Future<String?> _getWifiIP() async {
    try {
      final info = NetworkInfo();
      var ip = await info.getWifiIP();

      // Fallback per simulatori o casi particolari
      if (ip == null || !isPrivateSyncAddress(ip)) {
        final interfaces = await NetworkInterface.list(
          type: InternetAddressType.IPv4,
        );
        for (final interface in interfaces) {
          if (interface.name.contains('wlan') ||
              interface.name.contains('en')) {
            for (final address in interface.addresses) {
              if (isPrivateSyncAddress(address.address)) return address.address;
            }
          }
        }
      }
      return ip;
    } catch (e) {
      return null;
    }
  }
}
