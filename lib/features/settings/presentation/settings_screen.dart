import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../games/providers/games_providers.dart';
import '../../movies/providers/movies_providers.dart';
import '../../series/providers/series_providers.dart';
import '../../update/presentation/app_update_section.dart';
import '../../update/providers/update_providers.dart';
import 'rawg_account_section.dart';
import 'tmdb_account_section.dart';
import 'widgets/settings_widgets.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showsCount =
        ref.watch(trackedShowsNotifierProvider).valueOrNull?.length ?? 0;
    final moviesCount =
        ref.watch(trackedMoviesNotifierProvider).valueOrNull?.length ?? 0;
    final gamesCount = kEnableGames
        ? ref.watch(trackedGamesNotifierProvider).valueOrNull?.length ?? 0
        : 0;

    final summary = showsCount + moviesCount + gamesCount == 0
        ? 'Nessun titolo nella libreria'
        : [
            '$showsCount serie',
            '$moviesCount film',
            if (kEnableGames)
              '$gamesCount ${gamesCount == 1 ? 'gioco' : 'giochi'}',
          ].join(' · ');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
              child: _ProfileHeader(summary: summary),
            ),

            // ── Content ───────────────────────────────────────────────
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        const SettingsSectionTitle('Account'),
                        const SettingsGroup(
                          children: [
                            TmdbAccountTile(),
                            if (kEnableGames) RawgAccountTile(),
                          ],
                        ),
                        const SizedBox(height: 28),
                        const SettingsSectionTitle('App'),
                        SettingsGroup(
                          children: [
                            SettingsTile(
                              leading:
                                  const SettingsIconBox(Icons.qr_code_scanner),
                              title: 'Trasferimento / Sync',
                              subtitle: 'Sincronizza lo storico via QR Code',
                              onTap: () => context.push('/sync'),
                            ),
                            const AppUpdateTile(),
                            SettingsTile(
                              leading:
                                  const SettingsIconBox(Icons.shield_outlined),
                              title: 'Privacy e fonti dati',
                              subtitle: kEnableGames
                                  ? 'Come usiamo TMDB, AniList e RAWG'
                                  : 'Come usiamo TMDB e AniList',
                              onTap: () => context.push('/privacy'),
                            ),
                          ],
                        ),
                      ]),
                    ),
                  ),
                  // Occupa lo spazio rimasto: il footer sta in fondo allo
                  // schermo se il contenuto è corto, e scorre se è lungo.
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16, 32, 16, 24),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: _Footer(),
                      ),
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

// ── Header ────────────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final String summary;
  const _ProfileHeader({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Row(
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
              Text(
                summary,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Footer ────────────────────────────────────────────────────────────────────

class _Footer extends ConsumerWidget {
  const _Footer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final version = ref.watch(packageInfoProvider).whenOrNull(
          data: (info) => info.version,
        );

    return Text(
      version != null ? 'ShowTracker · v$version' : 'ShowTracker',
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
