import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class LibraryMediaCard extends StatelessWidget {
  final String title;
  final Widget thumbnail;
  final Size thumbnailSize;
  final VoidCallback onTap;
  final Widget? details;
  final Widget? action;
  final EdgeInsetsGeometry margin;

  const LibraryMediaCard({
    super.key,
    required this.title,
    required this.thumbnail,
    required this.thumbnailSize,
    required this.onTap,
    this.details,
    this.action,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    final action = this.action;
    final details = this.details;
    final radius = BorderRadius.circular(14);
    return Card(
      margin: margin,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: thumbnailSize.height),
            child: Stack(
              fit: StackFit.passthrough,
              children: [
                PositionedDirectional(
                  start: 0,
                  top: 0,
                  bottom: 0,
                  width: thumbnailSize.width,
                  child: Align(
                    alignment: AlignmentDirectional.topStart,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 112),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox.expand(child: thumbnail),
                      ),
                    ),
                  ),
                ),
                Row(
                  children: [
                    SizedBox(width: thumbnailSize.width + 10),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          if (details != null) ...[
                            const SizedBox(height: 5),
                            details,
                          ],
                        ],
                      ),
                    ),
                    if (action != null) ...[
                      const SizedBox(width: 8),
                      action,
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
