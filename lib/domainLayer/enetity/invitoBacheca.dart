import 'package:thepadel/domainLayer/enetity/partitaInvito.dart';

//una voce della bacheca inviti: la partita piu quello che l'utente puo farci.
//Se il dettaglio della partita non e arrivato, entrambi i campi sono false
class InvitoBacheca {
  //attributi
  final PartitaInvito partita;
  final bool puoConfermare;
  final bool giaConfermato;

  InvitoBacheca({required this.partita, required this.puoConfermare, required this.giaConfermato});
}
