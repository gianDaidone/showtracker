import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

// Mattoncini del tab Profilo: titolo di sezione, gruppo di righe, riga.
// Ricalcano lo stile di Serie/Film (titoli con barretta laterale, card
// `surface` con raggio 14).

/// Larghezza del leading delle righe, usata anche per allineare i divider.
const double _leadingSize = 40;

// ── Titolo di sezione ─────────────────────────────────────────────────────────

class SettingsSectionTitle extends StatelessWidget {
  final String title;
  const SettingsSectionTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
      child: Container(
        decoration: const BoxDecoration(
          border: Border(left: BorderSide(color: AppColors.accent, width: 4)),
        ),
        padding: const EdgeInsets.only(left: 8),
        child: Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// ── Gruppo di righe ───────────────────────────────────────────────────────────

/// Card unica con le righe separate da divider allineati al testo.
class SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  const SettingsGroup({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              const Divider(
                height: 1,
                indent: 16 + _leadingSize + 16,
                color: AppColors.divider,
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

// ── Riga ──────────────────────────────────────────────────────────────────────

class SettingsTile extends StatelessWidget {
  final Widget leading;
  final String title;
  final String? subtitle;

  /// Se valorizzato, il sottotitolo diventa uno stato: pallino + testo
  /// di questo colore.
  final Color? statusColor;

  /// Di default una freccia quando la riga è toccabile.
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool enabled;

  const SettingsTile({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.statusColor,
    this.trailing,
    this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      horizontalTitleGap: 16,
      enabled: enabled,
      leading: leading,
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Padding(
              padding: const EdgeInsets.only(top: 2),
              child: statusColor == null
                  ? Text(
                      subtitle!,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    )
                  : _StatusLabel(text: subtitle!, color: statusColor!),
            ),
      trailing: trailing ??
          (onTap != null
              ? const Icon(Icons.chevron_right, color: AppColors.textSecondary)
              : null),
      onTap: onTap,
    );
  }
}

class _StatusLabel extends StatelessWidget {
  final String text;
  final Color color;
  const _StatusLabel({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: TextStyle(color: color, fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ── Leading ───────────────────────────────────────────────────────────────────

/// Icona su quadrato arrotondato, leading standard delle righe.
class SettingsIconBox extends StatelessWidget {
  final IconData icon;
  final double size;
  const SettingsIconBox(this.icon, {super.key, this.size = _leadingSize});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(size / 4),
      ),
      child: Icon(icon, color: AppColors.textPrimary, size: size * 0.55),
    );
  }
}

/// Logo testuale circolare di un servizio (TMDB, RAWG): pieno del colore
/// del brand se connesso, solo bordo altrimenti.
class ServiceBadge extends StatelessWidget {
  final String label;
  final Color brandColor;
  final bool active;
  final double size;

  const ServiceBadge({
    super.key,
    required this.label,
    required this.brandColor,
    required this.active,
    this.size = _leadingSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? brandColor : AppColors.background,
        shape: BoxShape.circle,
        border: Border.all(
          color: active ? brandColor : AppColors.textSecondary,
          width: 1.5,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active ? Colors.white : AppColors.textSecondary,
          fontSize: size * 0.26,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}

// ── Riga account ──────────────────────────────────────────────────────────────

/// Riga di un servizio collegabile. Il tocco apre un bottom sheet con la
/// spiegazione e l'azione (disconnetti, con conferma, o collega): così
/// "Disconnetti" non resta sempre in vista nella pagina.
class ServiceAccountTile extends StatelessWidget {
  final String name;
  final Color brandColor;
  final bool isConnected;
  final String statusText;
  final String description;
  final String disconnectWarning;
  final Future<void> Function() onDisconnect;
  final String? connectLabel;
  final VoidCallback? onConnect;

  const ServiceAccountTile({
    super.key,
    required this.name,
    required this.brandColor,
    required this.isConnected,
    required this.statusText,
    required this.description,
    required this.disconnectWarning,
    required this.onDisconnect,
    this.connectLabel,
    this.onConnect,
  });

  void _openSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _AccountSheet(
        tile: this,
        onDisconnectPressed: () {
          Navigator.pop(sheetContext);
          _confirmDisconnect(context);
        },
        onConnectPressed: onConnect == null
            ? null
            : () {
                Navigator.pop(sheetContext);
                onConnect!();
              },
      ),
    );
  }

  void _confirmDisconnect(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Disconnettere l\'account?',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          disconnectWarning,
          style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Annulla',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              onDisconnect();
            },
            child: const Text(
              'Disconnetti',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SettingsTile(
      leading: ServiceBadge(
        label: name,
        brandColor: brandColor,
        active: isConnected,
      ),
      title: name,
      subtitle: statusText,
      statusColor: isConnected ? Colors.green : AppColors.textSecondary,
      onTap: () => _openSheet(context),
    );
  }
}

class _AccountSheet extends StatelessWidget {
  final ServiceAccountTile tile;
  final VoidCallback onDisconnectPressed;
  final VoidCallback? onConnectPressed;

  const _AccountSheet({
    required this.tile,
    required this.onDisconnectPressed,
    required this.onConnectPressed,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPad + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              ServiceBadge(
                label: tile.name,
                brandColor: tile.brandColor,
                active: tile.isConnected,
                size: 48,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tile.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _StatusLabel(
                      text: tile.statusText,
                      color: tile.isConnected
                          ? Colors.green
                          : AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            tile.description,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          if (tile.isConnected) ...[
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: onDisconnectPressed,
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text(
                'Disconnetti account',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                side: BorderSide(color: Colors.redAccent.withAlpha(120)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ] else if (onConnectPressed != null) ...[
            const SizedBox(height: 24),
            FilledButton(
              onPressed: onConnectPressed,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                tile.connectLabel ?? 'Collega',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
