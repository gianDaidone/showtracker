import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'sync_limits.dart';

class EncryptedSyncSnapshot {
  const EncryptedSyncSnapshot(this.body, this.key);
  final String body;

  /// Secret key for the QR fragment only: never put it in an HTTP request.
  final String key;
}

/// Versioned envelope using the library AES-256-GCM implementation, not a
/// custom cipher. Each export gets a fresh key and nonce; AAD binds the token.
abstract final class SyncEncryption {
  static const prefix = 'STSYNC2:';
  static const wireBytes = SyncLimits.encodedBytes + 128;
  static final _algorithm = AesGcm.with256bits();
  static List<int> _aad(String token) =>
      utf8.encode('ShowTracker/sync/v2:$token');

  static Future<EncryptedSyncSnapshot> encrypt(
      String payload, String token) async {
    if (payload.length > SyncLimits.encodedBytes) {
      throw const FormatException('Trasferimento troppo grande.');
    }
    final key = await _algorithm.newSecretKey();
    final box = await _algorithm.encrypt(base64Decode(payload),
        secretKey: key, nonce: _algorithm.newNonce(), aad: _aad(token));
    final body = prefix +
        base64Encode([...box.nonce, ...box.cipherText, ...box.mac.bytes]);
    if (body.length > wireBytes) {
      throw const FormatException('Trasferimento troppo grande.');
    }
    return EncryptedSyncSnapshot(
        body, base64UrlEncode(await key.extractBytes()).replaceAll('=', ''));
  }

  static Future<String> decrypt(String body, String key, String token) async {
    try {
      if (!body.startsWith(prefix) ||
          body.length > wireBytes ||
          !RegExp(r'^[A-Za-z0-9_-]{43}$').hasMatch(key)) {
        throw const FormatException();
      }
      final bytes = base64Decode(body.substring(prefix.length));
      final secret = base64Url.decode(base64Url.normalize(key));
      if (secret.length != 32 || bytes.length < 28) {
        throw const FormatException();
      }
      final result = await _algorithm.decrypt(
          SecretBox(bytes.sublist(12, bytes.length - 16),
              nonce: bytes.sublist(0, 12),
              mac: Mac(bytes.sublist(bytes.length - 16))),
          secretKey: SecretKey(secret),
          aad: _aad(token));
      final payload = base64Encode(result);
      if (payload.length > SyncLimits.encodedBytes) {
        throw const FormatException();
      }
      return payload;
    } catch (_) {
      throw const FormatException(
          'Trasferimento non valido, alterato o di una versione incompatibile. Aggiorna ShowTracker su entrambi i dispositivi e genera un nuovo QR.');
    }
  }
}
