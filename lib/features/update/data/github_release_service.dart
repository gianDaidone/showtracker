import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/constants.dart';
import 'app_version.dart';
import 'update_exception.dart';

/// L'ultima release pubblicata su GitHub, ridotta a ciò che serve
/// all'aggiornamento in-app.
class GithubRelease {
  const GithubRelease({
    required this.version,
    required this.tagName,
    required this.apkUrl,
    required this.apkName,
    this.notes,
  });

  final AppVersion version;
  final String tagName;
  final String apkUrl;
  final String apkName;

  /// Il `body` della release; `null` se vuoto.
  final String? notes;
}

/// Legge `releases/latest` dall'API pubblica di GitHub (nessun token: 60
/// richieste/ora per IP). Non passa da `AppInterceptor` — GitHub non vuole
/// chiavi TMDB/RAWG.
class GithubReleaseService {
  GithubReleaseService(this._client, {this.repo = kGithubRepo});

  final http.Client _client;
  final String repo;

  static const _timeout = Duration(seconds: 15);

  Future<GithubRelease> fetchLatest() async {
    final uri = Uri.https('api.github.com', '/repos/$repo/releases/latest');

    final http.Response response;
    try {
      response = await _client.get(uri, headers: const {
        'Accept': 'application/vnd.github+json',
        'X-GitHub-Api-Version': '2022-11-28',
        'User-Agent': 'ShowTracker',
      }).timeout(_timeout);
    } on Exception catch (e) {
      // SocketException, TlsException/HandshakeException, HttpException,
      // http.ClientException, TimeoutException… Il messaggio per l'utente è
      // generico: la causa reale resta nel log.
      if (e is IOException || e is http.ClientException || e is TimeoutException) {
        debugPrint('[Update] richiesta GitHub fallita: ${e.runtimeType}: $e');
        throw const UpdateNoConnection();
      }
      rethrow;
    }

    switch (response.statusCode) {
      case 200:
        break;
      case 404:
        // `releases/latest` ignora bozze e pre-release: 404 = nessuna release
        // pubblicata (o repo inesistente/privato).
        throw const UpdateNoReleases();
      case 403 || 429 when _isRateLimited(response):
        throw UpdateRateLimited(resetAt: _rateLimitReset(response));
      default:
        throw UpdateInvalidResponse('HTTP ${response.statusCode}');
    }

    return parseRelease(response.body);
  }

  /// Separato da [fetchLatest] per poterlo testare sul solo JSON.
  static GithubRelease parseRelease(String body) {
    final Object? json;
    try {
      json = jsonDecode(body);
    } on FormatException {
      throw const UpdateInvalidResponse('JSON non leggibile');
    }
    if (json is! Map<String, dynamic>) {
      throw const UpdateInvalidResponse('formato inatteso');
    }

    final tagName = json['tag_name'];
    if (tagName is! String || tagName.trim().isEmpty) {
      throw const UpdateInvalidResponse('tag_name mancante');
    }
    final version = AppVersion.tryParse(tagName);
    if (version == null) {
      throw UpdateInvalidResponse('versione "$tagName" non riconosciuta');
    }

    String? apkUrl;
    String? apkName;
    final assets = json['assets'];
    if (assets is List) {
      for (final asset in assets) {
        if (asset is! Map<String, dynamic>) continue;
        final name = asset['name'];
        final url = asset['browser_download_url'];
        if (name is String &&
            name.toLowerCase().endsWith('.apk') &&
            url is String &&
            url.isNotEmpty) {
          apkUrl = url;
          apkName = name;
          break;
        }
      }
    }
    if (apkUrl == null || apkName == null) throw UpdateNoApk(tagName);

    final rawNotes = json['body'];
    final notes =
        rawNotes is String && rawNotes.trim().isNotEmpty ? rawNotes.trim() : null;

    return GithubRelease(
      version: version,
      tagName: tagName,
      apkUrl: apkUrl,
      apkName: apkName,
      notes: notes,
    );
  }

  /// GitHub risponde 403 sia per il rate limit sia per altri divieti: è rate
  /// limit solo se le richieste rimaste sono 0 (o se è un 429).
  static bool _isRateLimited(http.Response response) {
    if (response.statusCode == 429) return true;
    if (response.headers['x-ratelimit-remaining'] == '0') return true;
    return response.body.toLowerCase().contains('rate limit');
  }

  static DateTime? _rateLimitReset(http.Response response) {
    final reset = int.tryParse(response.headers['x-ratelimit-reset'] ?? '');
    if (reset != null) {
      return DateTime.fromMillisecondsSinceEpoch(reset * 1000);
    }
    final retryAfter = int.tryParse(response.headers['retry-after'] ?? '');
    if (retryAfter != null) {
      return DateTime.now().add(Duration(seconds: retryAfter));
    }
    return null;
  }
}
