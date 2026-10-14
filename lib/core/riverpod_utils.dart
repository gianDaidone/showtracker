import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;

/// Da passare come `retry:` a ogni `ProviderContainer`/`ProviderScope`.
///
/// Riverpod 3 ritenta da solo i provider falliti. Qui sarebbe dannoso: i
/// tentativi su AniList scavalcherebbero il token bucket di `AniListQueue`, e
/// i fallback anime (`getStaleAnimeSeasons`, il banner "AniList non
/// disponibile") contano sul fatto che l'errore arrivi subito alla UI.
Duration? noProviderRetry(int retryCount, Object error) => null;

// In Riverpod 3 `read(p.future)` su un provider autoDispose che nessuno
// ascolta non lo tiene in vita: viene eliminato durante il primo `await` e, se
// dopo usa `ref`, la future fallisce con "Cannot use the Ref … after it has
// been disposed". Con Riverpod 2 lo stesso codice completava. Un listener
// temporaneo lo tiene in vita finché il risultato non arriva.

extension ContainerReadFuture on ProviderContainer {
  Future<T> readFuture<T>(ProviderListenable<Future<T>> provider) async {
    final sub = listen(provider, (_, __) {});
    try {
      return await sub.read();
    } finally {
      sub.close();
    }
  }
}

extension RefReadFuture on Ref {
  Future<T> readFuture<T>(ProviderListenable<Future<T>> provider) async {
    final sub = listen(provider, (_, __) {});
    try {
      return await sub.read();
    } finally {
      sub.close();
    }
  }
}
