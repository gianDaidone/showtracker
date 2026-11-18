export 'range_utils.dart';

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'sync_limits.dart';

class SyncCompressor {
  /// Compresses a JSON map to a base64 string using zlib.
  static String compressPayload(Map<String, dynamic> jsonPayload) {
    final jsonString = jsonEncode(jsonPayload);
    final bytes = utf8.encode(jsonString);
    if (bytes.length > SyncLimits.inflatedBytes) {
      throw const FormatException(
          'Libreria troppo grande per un singolo trasferimento.');
    }
    final compressed = zlib.encode(bytes);
    final encoded = base64Encode(compressed);
    if (encoded.length > SyncLimits.encodedBytes) {
      throw const FormatException(
          'Libreria troppo grande per un singolo trasferimento.');
    }
    return encoded;
  }

  /// Decompresses a base64 string back to a JSON map.
  static Map<String, dynamic> decompressPayload(String base64String) {
    try {
      if (base64String.length > SyncLimits.encodedBytes) {
        throw const FormatException('Limite trasferimento superato.');
      }
      final compressed = base64Decode(base64String);
      final output = _BoundedInflateSink();
      final decoder = zlib.decoder.startChunkedConversion(output);
      for (var offset = 0; offset < compressed.length; offset += 1024) {
        decoder.add(Uint8List.sublistView(
            compressed, offset, (offset + 1024).clamp(0, compressed.length)));
      }
      decoder.close();
      final bytes = output.bytes.takeBytes();
      final jsonString = utf8.decode(bytes);
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (_) {
      throw const FormatException(
          'Codice di trasferimento non valido o troppo grande.');
    }
  }
}

class _BoundedInflateSink implements Sink<List<int>> {
  final bytes = BytesBuilder(copy: false);
  @override
  void add(List<int> data) {
    if (bytes.length + data.length > SyncLimits.inflatedBytes) {
      throw const FormatException('Limite decompressione superato.');
    }
    bytes.add(data);
  }

  @override
  void close() {}
}
