import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'section_header_title.dart';

/// L'icona, il titolo, il conteggio e la freccia aprono insieme la libreria.
class LibraryHeaderLink extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget subtitle;
  final String tooltip;
  final VoidCallback onTap;

  const LibraryHeaderLink({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.transparent,
          borderRadius: radius,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            splashColor: AppColors.accent.withValues(alpha: 0.16),
            highlightColor: AppColors.accent.withValues(alpha: 0.08),
            child: Padding(
              padding: const EdgeInsetsDirectional.only(end: 6),
              child: SectionHeaderTitle(
                icon: icon,
                title: title,
                subtitle: subtitle,
                titleAction: const DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.all(Radius.circular(6)),
                  ),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.accent,
                    size: 23,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LibrarySearchButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String tooltip;

  const LibrarySearchButton({
    super.key,
    required this.onPressed,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) => IconButton.filled(
        style: IconButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.background,
          fixedSize: const Size.square(50),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: const Icon(Icons.search_rounded, size: 30),
        onPressed: onPressed,
        tooltip: tooltip,
      );
}
