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
            subtitle = 'Accedi per sincronizzare i dati.';
            isConnected = false;
            break;
          case AuthenticatedWithSession():
            statusText = 'Connesso';
            subtitle = 'Connesso tramite account TMDB.';
            isConnected = true;
            break;
          case AuthenticatedWithManualKey():
            statusText = 'Connesso (Avanzato)';
            subtitle = 'Connesso tramite API Key manuale.';
            isConnected = true;
            break;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                'ACCOUNT TMDB',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.account_circle, color: AppColors.textPrimary),
              title: Text(statusText),
              subtitle: Text(subtitle),
              trailing: isConnected
                  ? IconButton(
                      icon: const Icon(Icons.logout, color: Colors.red),
                      onPressed: () => _logout(ref, context, state),
                    )
                  : null,
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
