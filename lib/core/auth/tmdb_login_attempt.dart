/// Request token locale, monouso e a scadenza. Nessun token viene persistito.
class TmdbLoginAttempt {
  String? _token;
  DateTime? _expires;

  void begin(String token, {DateTime? now}) {
    if (token.isEmpty || token.length > 512) {
      throw const FormatException('Token non valido.');
    }
    _token = token;
    _expires = (now ?? DateTime.now()).add(const Duration(minutes: 10));
  }

  void cancel() {
    _token = null;
    _expires = null;
  }

  String? consume(Uri uri, {DateTime? now}) {
    final Map<String, List<String>> query;
    try {
      query = uri.queryParametersAll;
    } on FormatException {
      return null;
    }
    if (_token == null ||
        !(now ?? DateTime.now()).isBefore(_expires!) ||
        uri.scheme != 'showtracker' ||
        uri.host != 'auth' ||
        uri.hasPort ||
        uri.userInfo.isNotEmpty ||
        uri.path.isNotEmpty ||
        uri.hasFragment ||
        query.length != 2 ||
        query.values.any((values) => values.length != 1) ||
        query['request_token']?.single != _token) {
      return null;
    }
    final token = _token;
    cancel();
    return query['approved']?.single == 'true' ? token : null;
  }
}
