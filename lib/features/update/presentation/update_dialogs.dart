import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ota_update/ota_update.dart';

import '../../../core/theme/app_theme.dart';
import '../data/app_version.dart';
import '../data/github_release_service.dart';

const installPermissionDeniedMessage =
    'Permesso di installazione negato. Abilita «Installa app sconosciute» per '
    'ShowTracker nelle impostazioni di Android e riprova.';

/// "Aggiornamento disponibile": restituisce `true` se l'utente sceglie
/// "Aggiorna".
class UpdateAvailableDialog extends StatelessWidget {
  const UpdateAvailableDialog({
    super.key,
    required this.release,
    required this.installed,
  });

  final GithubRelease release;
  final AppVersion installed;

  @override
  Widget build(BuildContext context) {
    final notes = release.notes;
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('Aggiornamento disponibile'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Versione ${release.version}',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Installata: $installed',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          if (notes != null) ...[
            const SizedBox(height: 16),
            const Text(
              'NOTE DI RILASCIO',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: SingleChildScrollView(
                  child: Text(
                    notes,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Più tardi'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
          ),
          child: const Text('Aggiorna'),
        ),
      ],
    );
  }
}

/// Spiega il permesso «Installa app sconosciute» prima di aprire le
/// impostazioni di sistema. Restituisce `true` se l'utente vuole aprirle.
class InstallPermissionDialog extends StatelessWidget {
  const InstallPermissionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('Permesso necessario'),
      content: const Text(
        'Per installare l\'aggiornamento, Android richiede di consentire a '
        'ShowTracker di installare app sconosciute.\n\n'
        'Attiva l\'opzione nella schermata che si aprirà, poi torna qui.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Annulla'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
          ),
          child: const Text('Apri impostazioni'),
        ),
      ],
    );
  }
}

/// Scarica l'APK con `ota_update` mostrando la percentuale, poi lascia il
/// posto all'installer di sistema.
///
/// Si chiude da solo: con `null` quando parte l'installazione o l'utente
/// annulla, con un messaggio d'errore (italiano) se qualcosa va storto.
class UpdateDownloadDialog extends StatefulWidget {
  const UpdateDownloadDialog({super.key, required this.release});

  final GithubRelease release;

  @override
  State<UpdateDownloadDialog> createState() => _UpdateDownloadDialogState();
}

class _UpdateDownloadDialogState extends State<UpdateDownloadDialog> {
  final _ota = OtaUpdate();
  StreamSubscription<OtaEvent>? _subscription;

  /// `null` finché il plugin non manda la prima percentuale (o se il server
  /// non dichiara `Content-Length`): la barra resta indeterminata.
  double? _progress;
  bool _cancelling = false;
  bool _closed = false;

  @override
  void initState() {
    super.initState();
    try {
      _subscription = _ota
          .execute(
            widget.release.apkUrl,
            destinationFilename: 'showtracker-${widget.release.version}.apk',
          )
          .listen(
            _onEvent,
            onError: (Object e) {
              debugPrint('[Update] errore download: $e');
              _close(_downloadFailedMessage);
            },
            onDone: () => _close(null),
          );
    } catch (e) {
      debugPrint('[Update] impossibile avviare il download: $e');
      WidgetsBinding.instance.addPostFrameCallback((_) => _close(_downloadFailedMessage));
    }
  }

  static const _downloadFailedMessage =
      'Download dell\'aggiornamento non riuscito. Controlla la connessione e riprova.';

  void _onEvent(OtaEvent event) {
    switch (event.status) {
      case OtaStatus.DOWNLOADING:
        final percent = double.tryParse(event.value ?? '');
        if (percent != null && mounted) {
          setState(() => _progress = (percent / 100).clamp(0.0, 1.0));
        }
      case OtaStatus.INSTALLING:
      case OtaStatus.INSTALLATION_DONE:
        // Da qui in poi è l'installer di sistema a gestire tutto.
        _close(null);
      case OtaStatus.CANCELED:
        _close(null);
      case OtaStatus.PERMISSION_NOT_GRANTED_ERROR:
        _close(installPermissionDeniedMessage);
      case OtaStatus.DOWNLOAD_ERROR:
        debugPrint('[Update] DOWNLOAD_ERROR: ${event.value}');
        _close(_cancelling ? null : _downloadFailedMessage);
      case OtaStatus.CHECKSUM_ERROR:
        _close('Il file scaricato è danneggiato. Riprova.');
      case OtaStatus.ALREADY_RUNNING_ERROR:
        _close('Un download dell\'aggiornamento è già in corso.');
      case OtaStatus.INSTALLATION_ERROR:
      case OtaStatus.INTERNAL_ERROR:
        debugPrint('[Update] ${event.status.name}: ${event.value}');
        _close(_cancelling
            ? null
            : 'Installazione dell\'aggiornamento non riuscita. Riprova.');
    }
  }

  void _close(String? errorMessage) {
    if (_closed || !mounted) return;
    _closed = true;
    Navigator.of(context).pop(errorMessage);
  }

  Future<void> _cancel() async {
    setState(() => _cancelling = true);
    try {
      await _ota.cancel();
    } catch (e) {
      debugPrint('[Update] cancel fallito: $e');
    }
    // Il plugin manda CANCELED solo se un download era davvero attivo.
    _close(null);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _progress;
    return PopScope(
      canPop: false,
      child: AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Download versione ${widget.release.version}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                color: AppColors.accent,
                backgroundColor: AppColors.background,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _cancelling
                  ? 'Annullamento…'
                  : progress == null
                      ? 'Download in corso…'
                      : '${(progress * 100).round()}%',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _cancelling ? null : _cancel,
            child: const Text('Annulla'),
          ),
        ],
      ),
    );
  }
}
