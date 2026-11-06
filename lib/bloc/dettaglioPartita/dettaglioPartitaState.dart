import 'package:thepadel/domainLayer/enetity/dettaglioPartita.dart';

abstract class DettaglioPartitaState {}

class DettaglioPartitaInitial extends DettaglioPartitaState {}
class DettaglioPartitaLoading extends DettaglioPartitaState {}

class DettaglioPartitaCaricato extends DettaglioPartitaState {
  final DettaglioPartita dettaglio;
  DettaglioPartitaCaricato({required this.dettaglio});
}

class DettaglioPartitaErrore extends DettaglioPartitaState {
  final String messaggio;
  DettaglioPartitaErrore({required this.messaggio});
}

//gli stati di elimina, esci, conferma e cambio di visibilita si portano dietro il dettaglio, cosi la pagina puo continuare a mostrarlo
class OperazioneInCorso extends DettaglioPartitaState {
  final DettaglioPartita dettaglio;
  OperazioneInCorso({required this.dettaglio});
}

class PartitaEliminata extends DettaglioPartitaState {}

class UscitaCompletata extends DettaglioPartitaState {}

//dopo la conferma si resta sulla pagina: lo stato porta il dettaglio aggiornato arrivato dal server
class PartecipazioneConfermata extends DettaglioPartitaState {
  final DettaglioPartita dettaglio;
  PartecipazioneConfermata({required this.dettaglio});
}

//anche dopo il cambio di visibilita si resta sulla pagina, con il dettaglio aggiornato arrivato dal server
class TipoCambiato extends DettaglioPartitaState {
  final DettaglioPartita dettaglio;
  TipoCambiato({required this.dettaglio});
}

class OperazioneErrore extends DettaglioPartitaState {
  final DettaglioPartita dettaglio;
  final String messaggio;
  OperazioneErrore({required this.dettaglio, required this.messaggio});
}
