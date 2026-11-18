import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
        title: const Text('Privacy e fonti dati',
            style: TextStyle(fontWeight: FontWeight.w600)),
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
                'Progressi, stati, voti e note sono conservati nel database locale. Le richieste ai cataloghi, le immagini e i trailer contattano fornitori esterni, che ricevono il tuo indirizzo IP e i dati della richiesta. Non è una garanzia di anonimato.',
          ),
          const SizedBox(height: 12),
          const _InfoCard(
            icon: Icons.sync_lock,
            title: 'Perché TMDB?',
            body:
                'Il login al tuo account TMDB serve esclusivamente come "ponte" per recuperare in sola lettura le copertine, '
                'le trame e le date di uscita. TMDB riceve ricerche, ID dei titoli richiesti e credenziali TMDB. Anche gli ID usati per i consigli possono rivelare interessi; progressi, note e voti personali non vengono sincronizzati su TMDB.',
            note:
                'This product uses the TMDB API but is not endorsed or certified by TMDB.',
          ),
          const SizedBox(height: 12),
          Semantics(
              label: 'The Movie Database',
              image: true,
              child: Align(
                  alignment: Alignment.centerLeft,
                  child: SvgPicture.asset('assets/images/tmdb_logo.svg',
                      width: 160))),
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
              onNoteTap: () => launchUrl(Uri.parse('https://rawg.io/'),
                  mode: LaunchMode.externalApplication),
            ),
          ],
          const SizedBox(height: 12),
          const _InfoCard(
              icon: Icons.wifi,
              title: 'Trasferimento locale',
              body:
                  'Il QR può contenere direttamente ID, stati e progressi oppure aprire una sessione LAN temporanea cifrata con AES-GCM. La chiave resta nel QR: condividilo soltanto con destinatari fidati. Entrambi i dispositivi devono essere aggiornati. IP e metadati di rete restano visibili; il token scade dopo cinque minuti. I QR diretti sono leggibili da chi li acquisisce. Note, voti e credenziali non sono trasferiti.'),
          const SizedBox(height: 12),
          const _InfoCard(
              icon: Icons.perm_camera_mic_outlined,
              title: 'Permessi e contenuti esterni',
              body:
                'La fotocamera legge i QR sul dispositivo. ML Kit non invia immagini o risultati della scansione a Google, ma invia via HTTPS informazioni sul dispositivo e sull’app, identificatori di installazione e metriche diagnostiche e di utilizzo. Le notifiche e i widget possono mostrare titoli sul dispositivo bloccato. Yuna e AniList ricevono ID e ricerche anime; RAWG e Steam forniscono dati, immagini e trailer. Non sono integrati SDK pubblicitari.'),
          const SizedBox(height: 12),
          const _InfoCard(
              icon: Icons.delete_outline,
              title: 'Disconnessione e cancellazione',
              body:
                  'Disconnettere TMDB o RAWG rimuove le credenziali locali e conserva la libreria. Per eliminare tutti i dati locali usa le impostazioni Android dell’app → Spazio di archiviazione → Cancella dati, oppure disinstalla l’app. Questa operazione è irreversibile. Gli account TMDB/RAWG appartengono ai rispettivi fornitori: gestisci account e sessioni nei loro siti. La revoca remota TMDB richiede rete e può fallire offline.'),
          const SizedBox(height: 12),
          TextButton(
              onPressed: () => showLicensePage(
                  context: context, applicationName: 'ShowTracker'),
              child: const Text('Licenze open source')),
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
