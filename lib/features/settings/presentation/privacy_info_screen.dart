import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants.dart';
import '../../../core/theme/app_theme.dart';
import 'widgets/settings_widgets.dart';

/// Pagina "Privacy e fonti dati", aperta dal tab Profilo.
class PrivacyInfoScreen extends StatelessWidget {
  const PrivacyInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Privacy e fonti dati', style: TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          const _InfoCard(
            icon: Icons.shield_outlined,
            title: 'Cos\'è ShowTracker?',
            body:
                'ShowTracker è la tua app privata e offline-first per tracciare serie TV, film e videogiochi. '
                'I tuoi progressi e i tuoi dati sono salvati esclusivamente sul tuo dispositivo, garantendoti una privacy assoluta del 100%.',
          ),
          const SizedBox(height: 12),
          const _InfoCard(
            icon: Icons.sync_lock,
            title: 'Perché TMDB?',
            body:
                'Il login al tuo account TMDB serve esclusivamente come "ponte" per recuperare in sola lettura le copertine, '
                'le trame e le date di uscita. Nessun dato sulle tue visioni o attività viene inviato ai server di TMDB.',
            note: 'This product uses the TMDB API but is not endorsed or certified by TMDB.',
          ),
          const SizedBox(height: 12),
          const _InfoCard(
            icon: Icons.hub_outlined,
            title: 'Ecosistema Dati',
            body:
                'Per offrirti un catalogo ricco e globale, l\'app si appoggia a servizi pubblici di eccellenza. Usiamo TMDB per scovare film e serie occidentali. Per gli Anime, invece, attingiamo al database di AniList per avere date e orari di uscita precisissimi, sfruttando i collegamenti del progetto open-source Yuna per far parlare "magicamente" i due mondi.',
            note:
                'A causa di questa unione di dati, la suddivisione e la nomenclatura delle stagioni e degli episodi potrebbero in alcuni casi non rispecchiare fedelmente le release ufficiali.',
          ),
          if (kEnableGames) ...[
            const SizedBox(height: 12),
            _InfoCard(
              icon: Icons.videogame_asset,
              title: 'Perché RAWG?',
              body:
                  'L\'inserimento della chiave RAWG abilita la ricerca e il tracciamento dei videogiochi, scaricando in sola lettura copertine e dettagli. La tua libreria giochi rimane privata e salvata esclusivamente sul tuo dispositivo.',
              note: 'Video game data and information are sourced from RAWG.',
              onNoteTap: () => launchUrl(Uri.parse('https://rawg.io/'), mode: LaunchMode.externalApplication),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final String? note;
  final VoidCallback? onNoteTap;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.body,
    this.note,
    this.onNoteTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SettingsIconBox(icon, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            body,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          if (note != null) ...[
            const SizedBox(height: 14),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: onNoteTap,
              child: Text(
                note!,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
