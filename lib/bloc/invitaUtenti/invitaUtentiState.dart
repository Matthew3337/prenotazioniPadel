import 'package:thepadel/domainLayer/enetity/dettaglioPartita.dart';
import 'package:thepadel/domainLayer/enetity/utenteInvitabile.dart';

abstract class InvitaUtentiState {}

class InvitaUtentiInitial extends InvitaUtentiState {}
class InvitaUtentiLoading extends InvitaUtentiState {}

//la lista puo essere vuota: nessun utente corrisponde alla ricerca o sono gia tutti in partita
class InvitabiliCaricati extends InvitaUtentiState {
  final List<UtenteInvitabile> utenti;
  final int postiLiberi;
  InvitabiliCaricati({required this.utenti, required this.postiLiberi});

  //se un altro giocatore ha occupato l'ultimo posto la pagina deve tornare al dettaglio
  bool get alCompleto => postiLiberi == 0;
}

class InvitabiliErrore extends InvitaUtentiState {
  final String messaggio;
  InvitabiliErrore({required this.messaggio});
}

//gli stati dell'invito si portano dietro la lista, cosi la pagina puo continuare a mostrarla
class InvitoInCorso extends InvitaUtentiState {
  final List<UtenteInvitabile> utenti;
  final String telefono; //l'utente che si sta invitando, per mostrare il caricamento solo sul suo bottone
  InvitoInCorso({required this.utenti, required this.telefono});
}

//la lista qui e gia senza l'utente appena invitato
class InvitoRiuscito extends InvitaUtentiState {
  final List<UtenteInvitabile> utenti;
  final DettaglioPartita dettaglio;
  InvitoRiuscito({required this.utenti, required this.dettaglio});

  int get postiLiberi => dettaglio.postiLiberi;

  //con l'ultimo posto occupato non si puo invitare altro: la pagina torna al dettaglio
  bool get alCompleto => dettaglio.postiLiberi == 0;
}

class InvitoErrore extends InvitaUtentiState {
  final List<UtenteInvitabile> utenti;
  final String messaggio;
  InvitoErrore({required this.utenti, required this.messaggio});
}
