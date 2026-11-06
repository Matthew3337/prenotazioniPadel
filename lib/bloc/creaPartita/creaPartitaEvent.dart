import 'package:thepadel/domainLayer/enetity/slotOrario.dart';

abstract class CreaPartitaEvent {
  const CreaPartitaEvent();
}

class CreaPartitaRichiesta extends CreaPartitaEvent {
  final SlotOrario slot;
  final DateTime data;
  final String tipo; //"PUBBLICA" o "PRIVATA", stringa vuota se l'utente non ha ancora scelto
  final List<String> invitati; //i telefoni degli utenti scelti nel riepilogo, al massimo 3; vuota se non si invita nessuno
  const CreaPartitaRichiesta({required this.slot, required this.data, required this.tipo, this.invitati = const []});
}
