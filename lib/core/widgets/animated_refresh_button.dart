import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum RefreshState { idle, refreshing, success, error }

class AnimatedRefreshButton extends StatelessWidget {
  final RefreshState state;
  final VoidCallback? onPressed;
  final Color idleBackgroundColor;

  const AnimatedRefreshButton({
    super.key,
    required this.state,
    this.onPressed,
    this.idleBackgroundColor = Colors.transparent,
  });

  @override
  Widget build(BuildContext context) {
    final bool isExpanded = state != RefreshState.idle;

    Widget iconWidget;
    Color borderColor;

    switch (state) {
      case RefreshState.idle:
        iconWidget = const Icon(
          Icons.refresh_rounded,
          color: Colors.white,
          size: 20,
          key: ValueKey('idle'),
        );
        borderColor = Colors.transparent;
        break;
      case RefreshState.refreshing:
        iconWidget = const SizedBox(
          key: ValueKey('refreshing'),
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.accent,
          ),
        );
        borderColor = AppColors.accent;
        break;
      case RefreshState.success:
        iconWidget = const Icon(
          Icons.check_circle_outline,
          color: AppColors.accent,
          size: 20,
          key: ValueKey('success'),
        );
        borderColor = AppColors.accent;
        break;
      case RefreshState.error:
        iconWidget = const Icon(
          Icons.error_outline,
          color: Colors.redAccent,
          size: 20,
          key: ValueKey('error'),
        );
        borderColor = Colors.redAccent;
        break;
    }

    String label = '';
    switch (state) {
      case RefreshState.idle:
        label = '';
        break;
      case RefreshState.refreshing:
        label = 'Aggiornamento';
        break;
      case RefreshState.success:
        label = 'Completato';
        break;
      case RefreshState.error:
        label = 'Errore';
        break;
    }

    return GestureDetector(
      onTap: state == RefreshState.idle ? onPressed : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        padding: isExpanded
            ? const EdgeInsets.symmetric(horizontal: 12, vertical: 6)
            : const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isExpanded ? AppColors.surface : idleBackgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: isExpanded
              ? Border(left: BorderSide(color: borderColor, width: 3))
              : null,
          boxShadow: isExpanded
              ? [
                  BoxShadow(
                    color: Colors.black.withAlpha(50),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icona animata fissa a sinistra
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: SizedBox(
                key: ValueKey(state),
                width: 20,
                height: 20,
                child: Center(child: iconWidget),
              ),
            ),
            // Testo animato in larghezza
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              alignment: Alignment.centerLeft,
              child: isExpanded
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(width: 8),
                        Stack(
                          alignment: Alignment.centerLeft,
                          children: [
                            // Usiamo il testo più lungo nascosto per mantenere fissa la larghezza
                            const Opacity(
                              opacity: 0.0,
                              child: Text(
                                'Aggiornamento',
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.2,
                                ),
                              ),
                            ),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              layoutBuilder: (currentChild, previousChildren) {
                                return Stack(
                                  alignment: Alignment.centerLeft,
                                  children: [
                                    ...previousChildren,
                                    if (currentChild != null) currentChild,
                                  ],
                                );
                              },
                              child: Text(
                                label,
                                key: ValueKey(label),
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 13,
                                  height: 1.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
