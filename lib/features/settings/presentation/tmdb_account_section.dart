import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../core/auth/auth_state.dart';
import '../../../core/constants/api_keys.dart';
import '../../../core/network/api_request.dart';
import '../../../core/services/app_toast.dart';
import 'widgets/settings_widgets.dart';

class TmdbAccountTile extends ConsumerWidget {
  const TmdbAccountTile({super.key});

  Future<void> _logout(WidgetRef ref, AuthState state) async {
    // Invalida subito i client locali. Nessun uso di WidgetRef dopo il logout,
    // che può smontare questa schermata tramite il redirect del router.
    final controller = ref.read(authControllerProvider.notifier);
    await controller.logout();
    AppToast.show('Account disconnesso', type: ToastType.success);
    if (state is AuthenticatedWithSession) {
      final client = http.Client();
      try {
        final url = Uri.parse(
            'https://api.themoviedb.org/3/authentication/session?api_key=${ApiKeys.tmdb}');
        await apiRequest(
          client,
          'DELETE',
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'session_id': state.sessionId}),
        );
      } catch (e) {
        // Ignoriamo l'errore di rete se siamo offline, vogliamo comunque pulire lo storage locale.
      } finally {
        client.close();
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authStateAsync = ref.watch(authControllerProvider);
    final state = authStateAsync.value ?? const Unauthenticated();

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
          'Ricerche e ID dei titoli richiesti, anche per i consigli, raggiungono TMDB; progressi, note e voti personali restano locali.',
      disconnectWarning:
          'Disconnettendo l\'account non potrai più cercare nuovi titoli TMDB, ma il tuo database locale rimarrà intatto.',
      onDisconnect: () => _logout(ref, state),
    );
  }
}
