import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/app_toast.dart';
import '../providers/sync_controller.dart';
import '../providers/sync_panel_controller.dart';

/// Banner fluttuante: non ridimensiona il navigator e non blocca lo sfondo.
class SyncProgressHost extends ConsumerWidget {
  const SyncProgressHost({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(syncControllerProvider, (previous, next) {
      final panel = ref.read(syncPanelOpenProvider.notifier);
      if ((!(previous?.active ?? false) && next.active) ||
          (!(previous?.needsGameAcknowledgement ?? false) &&
              next.needsGameAcknowledgement)) {
        panel.show();
      } else if (!next.hasActivity) {
        panel.hide();
        if (previous?.hasActivity ?? false) {
          AppToast.show(
              next.failed == 0 && next.errors.isEmpty
                  ? 'Sincronizzazione completata'
                  : 'Alcuni elementi non sono stati sincronizzati.',
              type: next.failed == 0 && next.errors.isEmpty
                  ? ToastType.success
                  : ToastType.error);
        }
      }
    });
    final progress = ref.watch(syncControllerProvider);
    final open = ref.watch(syncPanelOpenProvider);
    return Overlay.wrap(
        child: Stack(fit: StackFit.expand, children: [
      child,
      if (open && progress.hasActivity)
        Positioned(
          top: MediaQuery.paddingOf(context).top + 12,
          left: 12,
          right: 12,
          child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                    maxWidth: 560,
                    maxHeight: (MediaQuery.sizeOf(context).height -
                            MediaQuery.paddingOf(context).vertical) *
                        .7),
                child: Material(
                    color: AppColors.surface,
                    elevation: 12,
                    shadowColor: AppColors.background,
                    borderRadius: BorderRadius.circular(18),
                    clipBehavior: Clip.antiAlias,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(18, 8, 10, 16),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(children: [
                              const Icon(Icons.sync_rounded,
                                  color: AppColors.accent, size: 22),
                              const SizedBox(width: 10),
                              Expanded(
                                  child: Text(progress.heading,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600))),
                              IconButton(
                                  tooltip: 'Riduci sincronizzazione',
                                  onPressed: () => ref
                                      .read(syncPanelOpenProvider.notifier)
                                      .hide(),
                                  icon: const Icon(Icons.close_rounded,
                                      color: AppColors.textSecondary)),
                            ]),
                            if (progress.needsGameAcknowledgement) ...[
                              const Text(
                                  'Configura la chiave API per completare i tuoi giochi',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              const Text(
                                  'Il tuo elenco di giochi è stato salvato. Per ora saltiamo il recupero dei dettagli: verranno sincronizzati quando aggiungerai la chiave API nelle impostazioni.'),
                              const SizedBox(height: 12),
                              Align(
                                  alignment: Alignment.centerRight,
                                  child: FilledButton(
                                      onPressed: () => ref
                                          .read(syncControllerProvider.notifier)
                                          .acknowledgeGames(),
                                      child: const Text('Ho capito'))),
                            ] else ...[
                              const SizedBox(height: 6),
                              LinearProgressIndicator(
                                  value: progress.fraction,
                                  color: AppColors.accent,
                                  semanticsLabel:
                                      'Avanzamento sincronizzazione'),
                              const SizedBox(height: 10),
                              Text(progress.counter,
                                  style: const TextStyle(
                                      color: AppColors.textSecondary)),
                              const SizedBox(height: 4),
                              Text(progress.scopeLabel,
                                  style: const TextStyle(
                                      color: AppColors.textSecondary)),
                              if (progress.activityLabel != progress.scopeLabel)
                                Text(progress.activityLabel,
                                    style: const TextStyle(
                                        color: AppColors.textSecondary)),
                              if (!progress.backgroundAvailable)
                                const Padding(
                                    padding: EdgeInsets.only(top: 6),
                                    child: Text(
                                        'Tieni l’app aperta per continuare.',
                                        style: TextStyle(
                                            color: AppColors.textSecondary))),
                            ],
                          ]),
                    )),
              )),
        ),
    ]));
  }
}
