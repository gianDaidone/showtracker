import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/app_toast.dart';
import '../../../core/theme/app_theme.dart';
import '../../settings/presentation/widgets/settings_widgets.dart';
import '../data/app_version.dart';
import '../data/github_release_service.dart';
import '../data/install_permission.dart';
import '../data/update_exception.dart';
import '../providers/update_providers.dart';
import 'update_dialogs.dart';

/// Riga "Cerca aggiornamenti" del tab Profilo.
///
/// Il controllo parte **solo** dal tocco: nessuna verifica all'avvio o in
/// background.
class AppUpdateTile extends ConsumerStatefulWidget {
  const AppUpdateTile({super.key});

  @override
  ConsumerState<AppUpdateTile> createState() => _AppUpdateTileState();
}

class _AppUpdateTileState extends ConsumerState<AppUpdateTile> {
  /// Vale sia per il controllo sia per la preparazione al download: il
  /// pulsante resta disabilitato finché il flusso non torna all'utente.
  bool _busy = false;

  /// I messaggi d'errore del flusso sono lunghi: restano visibili di più.
  static void _showError(String message) => AppToast.show(
        message,
        duration: const Duration(seconds: 4),
      );

  Future<void> _checkForUpdates() async {
    if (!Platform.isAndroid) {
      _showError('Gli aggiornamenti in-app sono disponibili solo su Android.');
      return;
    }

    setState(() => _busy = true);
    final GithubRelease release;
    final AppVersion installed;
    try {
      final info = await ref.read(packageInfoProvider.future);
      final parsed = AppVersion.tryParse(info.version);
      if (parsed == null) {
        _showError('Impossibile leggere la versione installata (${info.version}).');
        return;
      }
      installed = parsed;
      release = await ref.read(githubReleaseServiceProvider).fetchLatest();
    } on UpdateException catch (e) {
      _showError(e.message);
      return;
    } catch (e) {
      debugPrint('[Update] controllo fallito: $e');
      _showError('Impossibile verificare gli aggiornamenti. Riprova più tardi.');
      return;
    } finally {
      if (mounted) setState(() => _busy = false);
    }

    if (!mounted) return;
    if (!(release.version > installed)) {
      AppToast.show(
        'Sei già aggiornato (versione $installed).',
        type: ToastType.success,
        duration: const Duration(milliseconds: 2500),
      );
      return;
    }

    final wantsUpdate = await showDialog<bool>(
      context: context,
      builder: (_) => UpdateAvailableDialog(release: release, installed: installed),
    );
    if (wantsUpdate != true || !mounted) return;

    await _downloadAndInstall(release);
  }

  Future<void> _downloadAndInstall(GithubRelease release) async {
    setState(() => _busy = true);
    try {
      // Verificato prima del download: altrimenti Android blocca
      // l'installazione solo dopo aver scaricato tutto l'APK.
      if (!await InstallPermission.isGranted()) {
        if (!mounted) return;
        final openSettings = await showDialog<bool>(
          context: context,
          builder: (_) => const InstallPermissionDialog(),
        );
        if (openSettings != true) {
          _showError(installPermissionDeniedMessage);
          return;
        }
        if (!await InstallPermission.requestViaSettings()) {
          _showError(installPermissionDeniedMessage);
          return;
        }
      }

      if (!mounted) return;
      final error = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (_) => UpdateDownloadDialog(release: release),
      );
      if (error != null) _showError(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // La versione installata è nel footer del Profilo.
    return SettingsTile(
      enabled: !_busy,
      leading: const SettingsIconBox(Icons.system_update_rounded),
      title: 'Cerca aggiornamenti',
      subtitle: _busy ? 'Verifica in corso…' : 'Scarica l\'ultima versione da GitHub',
      trailing: _busy
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.accent),
            )
          : null,
      onTap: _busy ? null : _checkForUpdates,
    );
  }
}
