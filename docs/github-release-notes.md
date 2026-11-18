# Bozza note della prossima release GitHub

Versione e data da assegnare alla candidata; **non pubblicata**.

## Sincronizzazione locale più protetta

I trasferimenti LAN di stati e progressi sono ora cifrati con AES-GCM e hanno
una durata massima di cinque minuti. Per usarli, **aggiorna ShowTracker su entrambi
i dispositivi**, poi genera un nuovo QR. Una versione precedente e una aggiornata
non possono scambiarsi snapshot via LAN: il trasferimento fallisce senza import
parziali. La vecchia app può mostrare un errore generico.

I QR che contengono direttamente i dati, generati per librerie piccole, restano
compatibili con il formato precedente entro i limiti di sicurezza. Sono diversi
dai QR con indirizzo LAN e sono leggibili da chi li acquisisce. La sync trasferisce
ID, stati e progressi, non note, voti o credenziali: non è un backup completo.

Il QR LAN contiene la chiave: condividilo solo con il destinatario fidato. La
cifratura protegge il contenuto ma non verifica l’identità dei dispositivi;
indirizzi IP e metadati di rete restano visibili. Nessun fallback automatico al
vecchio trasporto LAN non cifrato.

## Affidabilità e utilizzo

- Migliorate validazione dei QR e degli import, gestione di token/sessioni e
  cambio credenziali, protezione dei log e delle richieste di rete.
- Corretti casi di aggiornamento metadati anime che potevano interferire con
  dati personali o usare coordinate stagione non mappate.
- Migliorati testo ingrandito, form chiavi, messaggi di errore e gestione fotocamera.
- Aggiornamento APK da GitHub ancora disponibile in **Profilo → Cerca
  aggiornamenti**, esclusivamente su tap, con conferma e permesso Android.

Per aggiornare conserva la normale installazione: non disinstallare l’app per
risolvere un errore di firma/versione. Le prove native e la validazione della
candidata devono essere concluse prima di pubblicare queste note.
