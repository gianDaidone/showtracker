import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/auth/rawg_auth_state.dart';

class RawgAccountSection extends ConsumerWidget {
  const RawgAccountSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rawgStateAsync = ref.watch(rawgAuthControllerProvider);
    final isAuthed = rawgStateAsync.valueOrNull is RawgAuthenticated;

    return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isAuthed ? const Color(0xFF202020) : AppColors.background,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isAuthed ? const Color(0xFF202020) : AppColors.textSecondary,
                          width: 2,
                        ),
                      ),
                      child: Text(
                        'RAWG',
                        style: TextStyle(
                          color: isAuthed ? Colors.white : AppColors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'RAWG',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isAuthed ? 'Connesso (API Key configurata)' : 'Non connesso',
                            style: TextStyle(
                              color: isAuthed ? Colors.green : AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (isAuthed) ...[
                const Divider(height: 1, color: AppColors.divider),
                InkWell(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Disconnettere l\'account?'),
                        content: const Text(
                          'Disconnettendo l\'account non potrai più cercare nuovi titoli RAWG, ma il tuo database locale rimarrà intatto.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Annulla'),
                          ),
                          TextButton(
                            onPressed: () {
                              ref.read(rawgAuthControllerProvider.notifier).logout();
                              Navigator.pop(context);
                            },
                            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                            child: const Text('Disconnetti'),
                          ),
                        ],
                      ),
                    );
                  },
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text(
                        'Disconnetti Account',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
    );
  }
}
