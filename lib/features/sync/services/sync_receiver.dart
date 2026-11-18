import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../utils/sync_limits.dart';
import '../utils/sync_encryption.dart';

bool isPrivateSyncAddress(String host) {
  final ip = InternetAddress.tryParse(host);
  if (ip == null || ip.type != InternetAddressType.IPv4 || ip.address != host) {
    return false;
  }
  final b = ip.rawAddress;
  return b[0] == 10 ||
      (b[0] == 172 && b[1] >= 16 && b[1] <= 31) ||
      (b[0] == 192 && b[1] == 168);
}

Uri validateSyncUri(String input) {
  final uri = Uri.tryParse(input);
  final Map<String, List<String>> query;
  try {
    query = uri?.queryParametersAll ?? {};
  } on FormatException {
    throw const FormatException('QR LAN non valido.');
  }
  if (uri == null ||
      uri.scheme != 'http' ||
      !isPrivateSyncAddress(uri.host) ||
      uri.port != 8080 ||
      uri.userInfo.isNotEmpty ||
      uri.path != '/sync' ||
      query.length != 1 ||
      query['token']?.length != 1 ||
      !RegExp(r'^[A-Za-z0-9_-]{22}$').hasMatch(query['token']?.single ?? '')) {
    throw const FormatException(
        'QR LAN non valido. Usa il codice generato da ShowTracker sulla stessa rete Wi-Fi.');
  }
  if (!uri.hasFragment) {
    throw const FormatException(
        'QR LAN di una versione precedente. Aggiorna ShowTracker su entrambi i dispositivi. I QR diretti restano compatibili.');
  }
  if (!RegExp(r'^k=[A-Za-z0-9_-]{43}$').hasMatch(uri.fragment)) {
    throw const FormatException(
        'Chiave QR LAN non valida. Genera un nuovo codice.');
  }
  return uri;
}

class SyncReceiver {
  SyncReceiver({http.Client Function()? createClient})
      : _createClient = createClient ?? http.Client.new;
  final http.Client Function() _createClient;

  Future<String> read(String data) async {
    if (data.length > SyncLimits.encodedBytes) {
      throw const FormatException('Trasferimento troppo grande.');
    }
    // A payload legacy is base64; any URI-like input must pass the LAN boundary.
    if (!data.contains(':')) return data;
    final uri = validateSyncUri(data);
    final client = _createClient();
    try {
      final body = await _download(client, uri.removeFragment())
          .timeout(const Duration(seconds: 10));
      return await SyncEncryption.decrypt(
          body, uri.fragment.substring(2), uri.queryParameters['token']!);
    } finally {
      client.close();
    }
  }

  Future<String> _download(http.Client client, Uri uri) async {
    final request = http.Request('GET', uri)
      ..followRedirects = false
      ..maxRedirects = 0;
    final response = await client.send(request);
    if (response.statusCode != 200) {
      throw const FormatException(
          'Il dispositivo mittente non è disponibile o il QR è scaduto.');
    }
    if ((response.contentLength ?? 0) > SyncEncryption.wireBytes) {
      throw const FormatException('Trasferimento troppo grande.');
    }
    final bytes = <int>[];
    await for (final chunk in response.stream) {
      if (bytes.length + chunk.length > SyncEncryption.wireBytes) {
        throw const FormatException('Trasferimento troppo grande.');
      }
      bytes.addAll(chunk);
    }
    return utf8.decode(bytes);
  }
}
