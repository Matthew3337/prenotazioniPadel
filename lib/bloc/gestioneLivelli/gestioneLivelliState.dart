import 'package:thepadel/domainLayer/enetity/utenteAdmin.dart';

abstract class GestioneLivelliState {}

class GestioneLivelliInitial extends GestioneLivelliState {}
class GestioneLivelliLoading extends GestioneLivelliState {}

//la lista puo essere vuota: nessun utente corrisponde alla ricerca
class UtentiCaricati extends GestioneLivelliState {
  final List<UtenteAdmin> utenti;
  UtentiCaricati({required this.utenti});
}

class UtentiErrore extends GestioneLivelliState {
  final String messaggio;
  UtentiErrore({required this.messaggio});
}

//gli stati del cambio di livello si portano dietro la lista, cosi la pagina puo continuare a mostrarla
class CambioLivelloInCorso extends GestioneLivelliState {
  final List<UtenteAdmin> utenti;
  final String telefono; //l'utente che si sta salvando, per mostrare il caricamento solo sulla sua riga
  CambioLivelloInCorso({required this.utenti, required this.telefono});
}

//la lista qui contiene gia il livello nuovo
class CambioLivelloRiuscito extends GestioneLivelliState {
  final List<UtenteAdmin> utenti;
  final UtenteAdmin utente;
  CambioLivelloRiuscito({required this.utenti, required this.utente});
}

class CambioLivelloErrore extends GestioneLivelliState {
  final List<UtenteAdmin> utenti;
  final String messaggio;
  CambioLivelloErrore({required this.utenti, required this.messaggio});
}
