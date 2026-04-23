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
            onTap: NotificationService.cancelAll,
            destructive: true,
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
