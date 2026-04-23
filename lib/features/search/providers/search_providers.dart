import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Tipo di risultato ─────────────────────────────────────────────────────────

enum SearchResultType { series, movie, game }

// ── Modello risultato unificato ───────────────────────────────────────────────

class SearchResult {
  final SearchResultType type;
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final int? mediaId; // tmdbId per serie/film, rawgId per giochi
  final int? sortYear;

  const SearchResult({
    required this.type,
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.mediaId,
    this.sortYear,
  });
}

// ── Provider reset ────────────────────────────────────────────────────────────

/// Incrementato ogni volta che il tab Cerca viene selezionato.
/// SearchScreen usa questo valore come ValueKey per resettare il proprio stato.
final searchTabResetProvider = StateProvider<int>((ref) => 0);
