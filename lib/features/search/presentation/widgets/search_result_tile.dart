import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../providers/search_providers.dart';

/// Apre il dettaglio di [result] (serie, film o gioco).
void openSearchResult(BuildContext context, SearchResult result) {
  switch (result.type) {
    case SearchResultType.series:
      context.push('/series/detail/${result.mediaId}');
    case SearchResultType.movie:
      context.push('/movies/detail/${result.mediaId}');
    case SearchResultType.game:
      context.push('/games/detail/${result.mediaId}');
  }
}

// ── Tile singolo risultato ────────────────────────────────────────────────────

class SearchResultTile extends StatelessWidget {
  final SearchResult result;
  const SearchResultTile({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: () => openSearchResult(context, result),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SearchResultThumbnail(
                url: result.imageUrl,
                type: result.type,
                width: 64,
                height: 96,
                borderRadius: 8,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    if (result.subtitle?.isNotEmpty == true) ...[
                      Text(
                        result.subtitle!,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                    ],
                    _TypeBadge(type: result.type),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Badge tipo ────────────────────────────────────────────────────────────────

class _TypeBadge extends StatelessWidget {
  final SearchResultType type;
  const _TypeBadge({required this.type});

  String get _label => switch (type) {
        SearchResultType.series => 'Serie TV',
        SearchResultType.movie => 'Film',
        SearchResultType.game => 'Gioco',
      };

  Color get _color => switch (type) {
        SearchResultType.series => AppColors.accent,
        SearchResultType.movie => const Color(0xFF4FC3F7),
        SearchResultType.game => const Color(0xFF81C784),
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _color.withAlpha(30),
        border: Border.all(color: _color.withAlpha(120)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        _label,
        style: TextStyle(
          color: _color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ── Thumbnail ─────────────────────────────────────────────────────────────────

/// Copertina di un risultato. [url] è già completo: `posterUrl` di
/// TmdbShow/TmdbMovie include il base URL, RAWG restituisce URL diretti.
class SearchResultThumbnail extends StatelessWidget {
  final String? url;
  final SearchResultType type;
  final double width;
  final double height;
  final double borderRadius;

  const SearchResultThumbnail({
    super.key,
    required this.url,
    required this.type,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  IconData get _fallbackIcon => switch (type) {
        SearchResultType.series => Icons.tv,
        SearchResultType.movie => Icons.movie,
        SearchResultType.game => Icons.videogame_asset,
      };

  @override
  Widget build(BuildContext context) {
    final fallback = ColoredBox(
      color: AppColors.divider,
      child: Center(
        child: Icon(_fallbackIcon, color: AppColors.textSecondary, size: 20),
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: width,
        height: height,
        child: url != null
            ? CachedNetworkImage(
                imageUrl: url!,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    const ColoredBox(color: AppColors.divider),
                errorWidget: (_, __, ___) => fallback,
              )
            : fallback,
      ),
    );
  }
}
