/// Errori del controllo aggiornamenti. Ognuno porta già il messaggio italiano
/// da mostrare all'utente.
sealed class UpdateException implements Exception {
  const UpdateException();

  String get message;

  @override
  String toString() => 'UpdateException: $message';
}

class UpdateNoConnection extends UpdateException {
  const UpdateNoConnection();

  @override
  String get message =>
      'Nessuna connessione a Internet. Controlla la rete e riprova.';
}

/// GitHub concede 60 richieste/ora per IP alle chiamate senza token.
class UpdateRateLimited extends UpdateException {
  const UpdateRateLimited({this.resetAt, this.now});

  /// Quando GitHub riapre il limite (header `x-ratelimit-reset`).
  final DateTime? resetAt;

  /// Iniettabile nei test; di default `DateTime.now()`.
  final DateTime? now;

  @override
  String get message {
    const base = 'Troppe richieste a GitHub.';
    final reset = resetAt;
    if (reset == null) return '$base Riprova più tardi.';
    final minutes = (reset.difference(now ?? DateTime.now()).inSeconds / 60).ceil();
    if (minutes <= 1) return '$base Riprova tra un minuto.';
    return '$base Riprova tra $minutes minuti.';
  }
}

class UpdateNoReleases extends UpdateException {
  const UpdateNoReleases();

  @override
  String get message => 'Nessuna release pubblicata su GitHub.';
}

class UpdateInvalidResponse extends UpdateException {
  const UpdateInvalidResponse(this.detail);

  final String detail;

  @override
  String get message => 'Risposta non valida da GitHub ($detail).';
}

class UpdateNoApk extends UpdateException {
  const UpdateNoApk(this.tagName);

  final String tagName;

  @override
  String get message => 'La release $tagName non contiene un file APK.';
}
