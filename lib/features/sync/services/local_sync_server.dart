import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:network_info_plus/network_info_plus.dart';

/// Handler separato dal socket per verificare il protocollo senza usare la LAN.
Handler createSyncHandler(
    {required String token, required String base64Payload}) {
  final router = Router();
  router.get('/sync', (Request request) {
    if (request.url.queryParameters['token'] != token) {
      return Response.forbidden('Invalid token');
    }
    return Response.ok(base64Payload, headers: {
      'Content-Type': 'text/plain',
      'Access-Control-Allow-Origin': '*',
    });
  });
  return router.call;
}

class LocalSyncServer {
  HttpServer? _server;
  String? _token;
  String? _payloadBase64;

  bool get isRunning => _server != null;

  /// Starts the server and returns the endpoint URI (e.g. http://192.168.1.5:8080/sync?token=XYZ).
  /// If it cannot determine the IP, returns null.
  Future<String?> start(String base64Payload) async {
    await stop();

    _payloadBase64 = base64Payload;
    _token = _generateToken();

    final handler = const Pipeline()
        .addMiddleware(logRequests())
        .addHandler(createSyncHandler(
          token: _token!,
          base64Payload: _payloadBase64!,
        ));

    try {
      _server = await io.serve(handler, InternetAddress.anyIPv4, 8080);

      final ip = await _getWifiIP();
      if (ip == null) {
        await stop();
        return null;
      }

      return 'http://$ip:${_server!.port}/sync?token=$_token';
    } catch (e) {
      debugPrint('Failed to start local sync server: $e');
      return null;
    }
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
    _token = null;
    _payloadBase64 = null;
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
      if (ip == null || ip == '127.0.0.1') {
        final interfaces = await NetworkInterface.list(
          type: InternetAddressType.IPv4,
        );
        for (final interface in interfaces) {
          if (interface.name.contains('wlan') ||
              interface.name.contains('en')) {
            ip = interface.addresses.first.address;
            break;
          }
        }
      }
      return ip;
    } catch (e) {
      return null;
    }
  }
}
