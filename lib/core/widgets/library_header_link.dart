import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Blocco "icona + titolo + sottotitolo" in cima alle schede Serie, Film e
/// Giochi, che porta all'elenco completo dei contenuti seguiti.
///
/// Tutto il blocco è un unico bersaglio di tocco (ripple compreso): la
/// tessera piena in accento e la freccia accanto al titolo servono a farlo
/// riconoscere come cliccabile. Va messo dentro un `Expanded`.
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
      alignment: Alignment.centerLeft,
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
              padding: const EdgeInsets.only(right: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.14),
                      border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.45),
                        width: 1.5,
                      ),
                      borderRadius: radius,
                    ),
                    child: Icon(icon, color: AppColors.accent, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.accent,
                              size: 26,
                            ),
                          ],
                        ),
                        subtitle,
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
