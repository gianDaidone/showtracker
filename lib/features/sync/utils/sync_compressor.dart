export 'range_utils.dart';

import 'dart:convert';
import 'dart:io';

class SyncCompressor {
  /// Compresses a JSON map to a base64 string using zlib.
  static String compressPayload(Map<String, dynamic> jsonPayload) {
    final jsonString = jsonEncode(jsonPayload);
    final bytes = utf8.encode(jsonString);
    final compressed = zlib.encode(bytes);
    return base64Encode(compressed);
  }

  /// Decompresses a base64 string back to a JSON map.
  static Map<String, dynamic> decompressPayload(String base64String) {
    try {
      final compressed = base64Decode(base64String);
      final bytes = zlib.decode(compressed);
      final jsonString = utf8.decode(bytes);
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      throw FormatException('Failed to decompress payload: $e');
    }
  }
}
