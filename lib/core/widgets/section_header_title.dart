import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class SectionHeaderTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget subtitle;
  final Widget? titleAction;

  const SectionHeaderTitle({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.titleAction,
  });

  @override
  Widget build(BuildContext context) {
    final titleAction = this.titleAction;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.14),
            border: Border.all(color: AppColors.accent, width: 1.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: AppColors.accent, size: 24),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Container(
            width: 1.5,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withAlpha(135),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (titleAction != null) ...[
                    const SizedBox(width: 7),
                    titleAction,
                  ],
                ],
              ),
              DefaultTextStyle.merge(
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                child: subtitle,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
