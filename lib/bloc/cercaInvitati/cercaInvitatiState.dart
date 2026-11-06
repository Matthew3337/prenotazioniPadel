import 'package:thepadel/domainLayer/enetity/utenteInvitabile.dart';

abstract class CercaInvitatiState {}

class CercaInvitatiInitial extends CercaInvitatiState {}
class CercaInvitatiLoading extends CercaInvitatiState {}

//la lista puo essere vuota se nessun utente corrisponde alla ricerca.
//Contiene anche gli utenti gia scelti: e la pagina che sa chi ha selezionato
class CercaInvitatiCaricati extends CercaInvitatiState {
  final List<UtenteInvitabile> utenti;
  CercaInvitatiCaricati({required this.utenti});
}

class CercaInvitatiErrore extends CercaInvitatiState {
  final String messaggio;
  CercaInvitatiErrore({required this.messaggio});
}
