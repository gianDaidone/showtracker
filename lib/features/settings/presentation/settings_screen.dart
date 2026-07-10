import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'tmdb_account_section.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                  const TmdbAccountSection(),
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
                        const SizedBox(height: 20),
                        const Divider(height: 1, color: AppColors.divider),
                        const SizedBox(height: 12),
                        const Text(
                          'This product uses the TMDB API but is not endorsed or certified by TMDB.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
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
                              child: const Icon(Icons.hub_outlined, color: AppColors.textPrimary, size: 18),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Ecosistema Dati',
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
                          'Per offrirti un catalogo ricco e globale, l\'app si appoggia a servizi pubblici di eccellenza. Usiamo TMDB per scovare film e serie occidentali. Per gli Anime, invece, attingiamo al database di AniList per avere date e orari di uscita precisissimi, sfruttando i collegamenti del progetto open-source Yuna per far parlare "magicamente" i due mondi.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1, color: AppColors.divider),
                        const SizedBox(height: 12),
                        const Text(
                          'A causa di questa unione di dati, la suddivisione e la nomenclatura delle stagioni e degli episodi potrebbero in alcuni casi non rispecchiare fedelmente le release ufficiali.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
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
}
