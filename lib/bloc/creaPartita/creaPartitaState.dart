import 'package:thepadel/domainLayer/enetity/prenotazione.dart';
import 'package:thepadel/domainLayer/enetity/slotOrario.dart';

abstract class CreaPartitaState {}

class CreaPartitaInitial extends CreaPartitaState {}
class CreaPartitaLoading extends CreaPartitaState {}

class CreaPartitaSuccess extends CreaPartitaState {
  final Prenotazione prenotazione;
  CreaPartitaSuccess({required this.prenotazione});
}

class CreaPartitaErrore extends CreaPartitaState {
  final String messaggio;
  CreaPartitaErrore({required this.messaggio});
}

//il 409 del server: e un errore a tutti gli effetti, ma porta con se le alternative da proporre.
//Essendo anche un CreaPartitaErrore, nella UI va controllato prima di quello
class CreaPartitaSlotPreso extends CreaPartitaErrore {
  final DateTime data;
  final List<SlotOrario> slotLiberi; //vuota se non ce ne sono o se non e stato possibile ricaricarli
  CreaPartitaSlotPreso({required super.messaggio, required this.data, required this.slotLiberi});
}
