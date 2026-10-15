import 'package:flutter_riverpod/legacy.dart';

import '../../games/data/models/rawg_game.dart';
import '../../movies/data/models/tmdb_movie.dart';
import '../../series/data/models/tmdb_show.dart';

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

  SearchResult.fromShow(TmdbShow s)
      : this(
          type: SearchResultType.series,
          title: s.name,
          subtitle: s.year?.toString(),
          imageUrl: s.posterUrl,
          mediaId: s.id,
          sortYear: s.year,
        );

  SearchResult.fromMovie(TmdbMovie m)
      : this(
          type: SearchResultType.movie,
          title: m.title,
          subtitle: m.year?.toString(),
          imageUrl: m.posterUrl,
          mediaId: m.id,
          sortYear: m.year,
        );

  SearchResult.fromGame(RawgGame g)
      : this(
          type: SearchResultType.game,
          title: g.name,
          subtitle: g.year?.toString(),
          imageUrl: g.coverUrl,
          mediaId: g.id,
          sortYear: g.year,
        );
}

// ── Provider reset ────────────────────────────────────────────────────────────

/// Incrementato ogni volta che il tab Cerca viene selezionato.
/// SearchScreen usa questo valore come ValueKey per resettare il proprio stato.
final searchTabResetProvider = StateProvider<int>((ref) => 0);
