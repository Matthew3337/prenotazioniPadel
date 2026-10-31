import 'package:thepadel/domainLayer/enetity/prenotazione.dart';

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
