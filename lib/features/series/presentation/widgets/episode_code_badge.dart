import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class EpisodeCodeBadge extends StatelessWidget {
  final int season;
  final int episode;
  final String? seasonName;
  const EpisodeCodeBadge(
      {super.key,
      required this.season,
      required this.episode,
      this.seasonName});

  @override
  Widget build(BuildContext context) {
    String label;
    if (seasonName != null) {
      final baseName = seasonName!.split(' · ').first.trim();
      var abbr = baseName.replaceAll(
          RegExp(r'^(Stagione|Season)\s*', caseSensitive: false), 'S');
      abbr =
          abbr.replaceAll(RegExp(r'\s*Parte\s*', caseSensitive: false), ' P');
      // Aggiungi padding alla stagione se a una sola cifra (S1 -> S01)
      abbr = abbr.replaceAllMapped(RegExp(r'(S)(\d)(?!\d)'), (match) {
        return '${match.group(1)}0${match.group(2)}';
      });
      label = '$abbr E${episode.toString().padLeft(2, '0')}';
    } else {
      label =
          'S${season.toString().padLeft(2, '0')} E${episode.toString().padLeft(2, '0')}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.divider.withAlpha(80),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
          fontSize: 11,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
