import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../core/auth/auth_state.dart';
import '../../../core/constants.dart';
import '../../../core/theme/app_theme.dart';

class TmdbAccountSection extends ConsumerWidget {
  const TmdbAccountSection({super.key});

  Future<void> _logout(WidgetRef ref, BuildContext context, AuthState state) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    if (state is AuthenticatedWithSession) {
      try {
        final url = Uri.parse('https://api.themoviedb.org/3/authentication/session?api_key=$kTmdbApiKey');
        await http.delete(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'session_id': state.sessionId}),
        );
      } catch (e) {
        // Ignoriamo l'errore di rete se siamo offline, vogliamo comunque pulire lo storage locale.
      }
    }
    
    await ref.read(authControllerProvider.notifier).logout();
    scaffoldMessenger.showSnackBar(
      const SnackBar(content: Text('Account disconnesso.')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authStateAsync = ref.watch(authControllerProvider);

    return authStateAsync.when(
      data: (state) {
        String statusText = 'Non connesso';
        String subtitle = '';
        bool isConnected = false;

        switch (state) {
          case Unauthenticated():
            statusText = 'Non connesso';
            isConnected = false;
            break;
          case AuthenticatedWithSession():
            statusText = 'Connesso tramite account';
            isConnected = true;
            break;
          case AuthenticatedWithManualKey():
            statusText = 'Connesso (API Key manuale)';
            isConnected = true;
            break;
        }

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
                            color: isConnected ? const Color(0xFF01B4E4) : AppColors.background,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isConnected ? const Color(0xFF01B4E4) : AppColors.textSecondary,
                              width: 2,
                            ),
                          ),
                          child: Text(
                            'TMDB',
                            style: TextStyle(
                              color: isConnected ? Colors.white : AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'TMDB',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                statusText,
                                style: TextStyle(
                                  color: isConnected ? Colors.green : AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isConnected) ...[
                    const Divider(height: 1, color: AppColors.divider),
                    InkWell(
                      onTap: () {
                         showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Disconnettere l\'account?'),
                            content: const Text(
                              'Disconnettendo l\'account non potrai più cercare nuovi titoli TMDB, ma il tuo database locale rimarrà intatto.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Annulla'),
                              ),
                              TextButton(
                                onPressed: () {
                                  _logout(ref, context, state);
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
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
