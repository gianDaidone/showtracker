import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/rawg_auth_state.dart';
import 'widgets/settings_widgets.dart';

class RawgAccountTile extends ConsumerWidget {
  const RawgAccountTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rawgStateAsync = ref.watch(rawgAuthControllerProvider);
    final isAuthed = rawgStateAsync.valueOrNull is RawgAuthenticated;

    return ServiceAccountTile(
      name: 'RAWG',
      brandColor: const Color(0xFF202020),
      isConnected: isAuthed,
      statusText: rawgStateAsync.isLoading
          ? 'Verifica in corso…'
          : isAuthed
              ? 'Connesso con API Key'
              : 'Non connesso',
      description:
          'Abilita la ricerca e il tracciamento dei videogiochi, scaricando in sola lettura copertine e dettagli. '
          'La tua libreria giochi rimane salvata solo su questo dispositivo.',
      disconnectWarning:
          'Disconnettendo l\'account non potrai più cercare nuovi titoli RAWG, ma il tuo database locale rimarrà intatto.',
      onDisconnect: () => ref.read(rawgAuthControllerProvider.notifier).logout(),
      // Il tab Giochi, senza chiave, mostra già il form per inserirla.
      connectLabel: 'Inserisci API Key',
      onConnect: () => context.go('/games'),
    );
  }
}
