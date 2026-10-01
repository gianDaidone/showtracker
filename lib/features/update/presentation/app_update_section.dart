import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../data/app_version.dart';
import '../data/github_release_service.dart';
import '../data/install_permission.dart';
import '../data/update_exception.dart';
import '../providers/update_providers.dart';
import 'update_dialogs.dart';

/// Card "Cerca aggiornamenti" del tab Profilo.
///
/// Il controllo parte **solo** dal tocco: nessuna verifica all'avvio o in
/// background.
class AppUpdateSection extends ConsumerStatefulWidget {
  const AppUpdateSection({super.key});

  @override
  ConsumerState<AppUpdateSection> createState() => _AppUpdateSectionState();
}

class _AppUpdateSectionState extends ConsumerState<AppUpdateSection> {
  /// Vale sia per il controllo sia per la preparazione al download: il
  /// pulsante resta disabilitato finché il flusso non torna all'utente.
  bool _busy = false;

  Future<void> _checkForUpdates() async {
    final messenger = ScaffoldMessenger.of(context);
    void show(String message) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }

    if (!Platform.isAndroid) {
      show('Gli aggiornamenti in-app sono disponibili solo su Android.');
      return;
    }

    setState(() => _busy = true);
    final GithubRelease release;
    final AppVersion installed;
    try {
      final info = await ref.read(packageInfoProvider.future);
      final parsed = AppVersion.tryParse(info.version);
      if (parsed == null) {
        show('Impossibile leggere la versione installata (${info.version}).');
        return;
      }
      installed = parsed;
      release = await ref.read(githubReleaseServiceProvider).fetchLatest();
    } on UpdateException catch (e) {
      show(e.message);
      return;
    } catch (e) {
      debugPrint('[Update] controllo fallito: $e');
      show('Impossibile verificare gli aggiornamenti. Riprova più tardi.');
      return;
    } finally {
      if (mounted) setState(() => _busy = false);
    }

    if (!mounted) return;
    if (!(release.version > installed)) {
      show('Sei già aggiornato (versione $installed).');
      return;
    }

    final wantsUpdate = await showDialog<bool>(
      context: context,
      builder: (_) => UpdateAvailableDialog(release: release, installed: installed),
    );
    if (wantsUpdate != true || !mounted) return;

    await _downloadAndInstall(release, show);
  }

  Future<void> _downloadAndInstall(
    GithubRelease release,
    void Function(String) show,
  ) async {
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
          show(installPermissionDeniedMessage);
          return;
        }
        if (!await InstallPermission.requestViaSettings()) {
          show(installPermissionDeniedMessage);
          return;
        }
      }

      if (!mounted) return;
      final error = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (_) => UpdateDownloadDialog(release: release),
      );
      if (error != null) show(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final version = ref.watch(packageInfoProvider).whenOrNull(
          data: (info) => info.version,
        );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        enabled: !_busy,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.system_update_rounded, color: AppColors.textPrimary, size: 24),
        ),
        title: const Text(
          'Cerca aggiornamenti',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          version != null ? 'Versione $version' : 'Versione …',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
        trailing: _busy
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.accent),
              )
            : const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        onTap: _busy ? null : _checkForUpdates,
      ),
    );
  }
}
