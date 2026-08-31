/// Unica sorgente delle chiavi API. I valori arrivano dai `--dart-define`
/// (compile-time), mai da costanti hard-coded: `lib/core/constants.dart` è
/// tracciato da git e non deve contenere segreti.
///
/// Uso:
///   flutter run --dart-define=TMDB_KEY=... --dart-define=RAWG_KEY=...
///
/// Più comodo, con il file locale ignorato da git
/// (parti da `dart_defines/dev.example.json`):
///   flutter run --dart-define-from-file=dart_defines/dev.json
///
/// Attenzione: `--dart-define` tiene le chiavi fuori dal repository, ma NON
/// le nasconde in un APK distribuito — vengono compilate come costanti nel
/// binario ed estraibili. Per una build pubblica va rigenerata una chiave
/// dedicata, trattandola come pubblica.
abstract class ApiKeys {
  static const tmdb = String.fromEnvironment('TMDB_KEY', defaultValue: '');
  static const rawg = String.fromEnvironment('RAWG_KEY', defaultValue: '');
  // Google Books and Open Library are free/keyless
}
