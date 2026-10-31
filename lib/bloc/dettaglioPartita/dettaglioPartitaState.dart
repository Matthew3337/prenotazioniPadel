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
