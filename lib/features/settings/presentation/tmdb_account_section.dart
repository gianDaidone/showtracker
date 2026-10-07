import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../core/auth/auth_state.dart';
import '../../../core/constants/api_keys.dart';
import '../../../core/services/app_toast.dart';
import 'widgets/settings_widgets.dart';

class TmdbAccountTile extends ConsumerWidget {
  const TmdbAccountTile({super.key});

  Future<void> _logout(WidgetRef ref, AuthState state) async {
    if (state is AuthenticatedWithSession) {
      try {
        final url = Uri.parse('https://api.themoviedb.org/3/authentication/session?api_key=${ApiKeys.tmdb}');
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
    // Il toast vive nell'overlay del router: resta visibile anche dopo il
    // redirect all'onboarding.
    AppToast.show('Account disconnesso', type: ToastType.success);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authStateAsync = ref.watch(authControllerProvider);
    final state = authStateAsync.valueOrNull ?? const Unauthenticated();

    final statusText = authStateAsync.isLoading
        ? 'Verifica in corso…'
        : switch (state) {
            Unauthenticated() => 'Non connesso',
            AuthenticatedWithSession() => 'Connesso tramite account',
            AuthenticatedWithManualKey() => 'Connesso con API Key',
          };

    return ServiceAccountTile(
      name: 'TMDB',
      brandColor: const Color(0xFF01B4E4),
      isConnected: state is! Unauthenticated,
      statusText: statusText,
      description:
          'Usato solo in lettura per copertine, trame e date di uscita di serie e film. '
          'Nessun dato sulle tue visioni viene inviato ai server di TMDB.',
      disconnectWarning:
          'Disconnettendo l\'account non potrai più cercare nuovi titoli TMDB, ma il tuo database locale rimarrà intatto.',
      onDisconnect: () => _logout(ref, state),
    );
  }
}
