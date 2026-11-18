import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../providers/sync_controller.dart';
import '../providers/sync_panel_controller.dart';

class SyncStatusAction extends ConsumerWidget {
  const SyncStatusAction({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(syncControllerProvider);
    if (!progress.hasActivity) return const SizedBox.shrink();
    return IconButton(
      tooltip: progress.needsGameAcknowledgement
          ? 'Sincronizzazione: conferma richiesta'
          : 'Sincronizzazione',
      onPressed: () => ref.read(syncPanelOpenProvider.notifier).show(),
      icon: SizedBox(
          width: 26,
          height: 26,
          child: Stack(children: [
            const Center(
                child: Icon(Icons.sync_rounded, color: AppColors.accent)),
            Positioned(
                right: 0,
                bottom: 0,
                child: progress.needsGameAcknowledgement
                    ? const Icon(Icons.info, size: 12, color: AppColors.accent)
                    : const SizedBox(
                        width: 9,
                        height: 9,
                        child: CircularProgressIndicator(
                            strokeWidth: 1.5, color: AppColors.accent))),
          ])),
    );
  }
}
