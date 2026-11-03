import 'package:thepadel/domainLayer/enetity/dettaglioPartita.dart';

abstract class DettaglioAdminState {}

class DettaglioAdminInitial extends DettaglioAdminState {}
class DettaglioAdminLoading extends DettaglioAdminState {}

class DettaglioAdminCaricato extends DettaglioAdminState {
  final DettaglioPartita dettaglio;
  DettaglioAdminCaricato({required this.dettaglio});
}

class DettaglioAdminErrore extends DettaglioAdminState {
  final String messaggio;
  DettaglioAdminErrore({required this.messaggio});
}

//gli stati delle operazioni si portano dietro il dettaglio, cosi la pagina puo continuare a mostrarlo
class OperazioneAdminInCorso extends DettaglioAdminState {
  final DettaglioPartita dettaglio;
  OperazioneAdminInCorso({required this.dettaglio});
}

//qui il dettaglio e quello aggiornato arrivato dal server
class OperazioneAdminRiuscita extends DettaglioAdminState {
  final DettaglioPartita dettaglio;
  final String messaggio;
  OperazioneAdminRiuscita({required this.dettaglio, required this.messaggio});
}

class OperazioneAdminErrore extends DettaglioAdminState {
  final DettaglioPartita dettaglio;
  final String messaggio;
  OperazioneAdminErrore({required this.dettaglio, required this.messaggio});
}
