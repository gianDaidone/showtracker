import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Le eccezioni di trasporto contengono dettagli tecnici (e talvolta URL):
/// restano nei log, non nel testo della ricerca/discovery.
String searchErrorMessage(Object error) {
  if (error is http.ClientException ||
      error is SocketException ||
      error is TimeoutException) {
    return 'Impossibile caricare i contenuti. Controlla la connessione e riprova.';
  }
  return 'Impossibile caricare i contenuti. Riprova più tardi.';
}
