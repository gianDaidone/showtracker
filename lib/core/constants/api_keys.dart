/// API keys — store sensitive values in a local `.env` file or
/// compile-time defines (`--dart-define`) rather than hard-coding them.
///
/// Usage:
///   flutter run --dart-define=TMDB_KEY=your_key_here
abstract class ApiKeys {
  static const tmdb = String.fromEnvironment('TMDB_KEY', defaultValue: '');
  static const rawg = String.fromEnvironment('RAWG_KEY', defaultValue: '');
  // Google Books and Open Library are free/keyless
}
