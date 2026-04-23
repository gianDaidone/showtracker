import 'package:flutter/material.dart';
import '../../core/services/notification_service.dart';
import '../../core/theme/app_theme.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  int _delaySeconds = 10;
  late Future<List<ScheduledNotifInfo>> _pendingFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _pendingFuture = NotificationService.getPendingNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug'),
        backgroundColor: AppColors.surface,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // ── Azioni notifiche ──────────────────────────────────────────────
          Text(
            'Notifiche',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: AppColors.accent),
          ),
          const SizedBox(height: 16),
          _ActionTile(
            icon: Icons.notifications,
            label: 'Manda subito',
            onTap: () => NotificationService.showImmediate(
              title: 'Test ShowTracker',
              body: 'S01E01 – Episodio pilota è disponibile oggi!',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ActionTile(
                  icon: Icons.schedule,
                  label: 'Tra $_delaySeconds secondi',
                  onTap: () => NotificationService.scheduleInSeconds(
                    seconds: _delaySeconds,
                    title: 'Test ShowTracker',
                    body: 'S01E01 – Episodio pilota è disponibile oggi!',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _StepButton(
                icon: Icons.remove,
                onTap: () => setState(
                  () => _delaySeconds = (_delaySeconds - 5).clamp(5, 60),
                ),
              ),
              const SizedBox(width: 4),
              _StepButton(
                icon: Icons.add,
                onTap: () => setState(
                  () => _delaySeconds = (_delaySeconds + 5).clamp(5, 60),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ActionTile(
            icon: Icons.notifications_off,
            label: 'Cancella tutte',
            onTap: () async {
              await NotificationService.cancelAll();
              _refresh();
            },
            destructive: true,
          ),

          // ── Notifiche programmate ─────────────────────────────────────────
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Programmate',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: AppColors.accent),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
                onPressed: _refresh,
                tooltip: 'Aggiorna',
              ),
            ],
          ),
          const SizedBox(height: 8),
          FutureBuilder<List<ScheduledNotifInfo>>(
            future: _pendingFuture,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(color: AppColors.accent),
                  ),
                );
              }
              final items = snap.data ?? [];
              if (items.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Nessuna notifica programmata.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                );
              }
              return Column(
                children: [
                  for (final info in items)
                    _NotifCard(info: info, onCancel: () async {
                      await NotificationService.cancel(info.id);
                      _refresh();
                    }),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = destructive ? Colors.redAccent : AppColors.accent;
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 12),
              Text(label, style: TextStyle(color: color)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _StepButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: AppColors.textSecondary, size: 20),
        ),
      ),
    );
  }
}

class _NotifCard extends StatelessWidget {
  final ScheduledNotifInfo info;
  final VoidCallback onCancel;

  const _NotifCard({required this.info, required this.onCancel});

  String get _timeLabel {
    if (info.scheduledAt.year == 0) return 'Orario non disponibile (avviare l\'app prima della programmazione)';
    final dt = info.scheduledAt;
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${dt.day}/${pad(dt.month)}/${dt.year}  ${pad(dt.hour)}:${pad(dt.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final hasTime = info.scheduledAt.year != 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: hasTime ? AppColors.accent.withAlpha(60) : AppColors.divider,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.notifications_active_outlined,
            color: hasTime ? AppColors.accent : AppColors.textSecondary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info.showTitle,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  info.body,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 12,
                      color: hasTime ? AppColors.accent : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _timeLabel,
                        style: TextStyle(
                          color: hasTime ? AppColors.accent : AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: hasTime ? FontWeight.w600 : FontWeight.normal,
                          fontStyle: hasTime ? FontStyle.normal : FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: Colors.redAccent),
            onPressed: onCancel,
            tooltip: 'Cancella',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
