import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final isCustomKey = authState.customApiKey != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      border: Border.all(color: AppColors.divider, width: 1.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: AppColors.accent,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Profilo',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Gestisci connessioni e privacy',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // ── Content ───────────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const Text(
                    'ACCOUNT TMDB',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isCustomKey ? Icons.key : Icons.person,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          title: Text(
                            isCustomKey ? 'API Key Manuale' : 'Connesso tramite Login TMDB',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              isCustomKey ? 'Le chiamate usano la chiave custom.' : 'Le chiamate usano la sessione sicura.',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ),
                        const Divider(height: 1, color: AppColors.divider),
                        if (isCustomKey)
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                            leading: const Icon(Icons.edit, color: AppColors.textSecondary),
                            title: const Text('Aggiorna API Key'),
                            onTap: () {
                              _showCustomKeyDialog(context, ref);
                            },
                          ),
                        if (isCustomKey) const Divider(height: 1, color: AppColors.divider),
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                          leading: const Icon(Icons.logout, color: Colors.redAccent),
                          title: const Text('Disconnetti', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w500)),
                          onTap: () {
                            _showLogoutConfirmation(context, ref);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'INFORMAZIONI SULL\'APP',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.divider),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.shield_outlined, color: AppColors.textPrimary, size: 18),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Cos\'è ShowTracker?',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'ShowTracker è la tua app privata e offline-first per tracciare serie TV, film e videogiochi. '
                          'I tuoi progressi e i tuoi dati sono salvati esclusivamente sul tuo dispositivo, garantendoti una privacy assoluta del 100%.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Divider(height: 1, color: AppColors.divider),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.sync_lock, color: AppColors.textPrimary, size: 18),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Perché TMDB?',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Il login al tuo account TMDB serve esclusivamente come "ponte" per recuperare in sola lettura le copertine, '
                          'le trame e le date di uscita. Nessun dato sulle tue visioni o attività viene inviato ai server di TMDB.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomKeyDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Aggiorna API Key v3'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'La tua nuova TMDB API Key',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annulla'),
            ),
            ElevatedButton(
              onPressed: () {
                final key = controller.text.trim();
                if (key.isNotEmpty) {
                  ref.read(authProvider.notifier).saveCustomApiKey(key);
                  Navigator.pop(context);
                }
              },
              child: const Text('Salva'),
            ),
          ],
        );
      },
    );
  }

  void _showLogoutConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Disconnetti'),
          content: const Text('Sei sicuro di voler disconnettere il tuo account? L\'app si bloccherà finché non rieffettuerai l\'accesso.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annulla'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
              onPressed: () {
                Navigator.pop(context); // chiudi dialog
                ref.read(authProvider.notifier).logout(); // disconnette e GoRouter reindirizzerà
              },
              child: const Text('Disconnetti'),
            ),
          ],
        );
      },
    );
  }
}
