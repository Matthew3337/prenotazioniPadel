import 'package:thepadel/domainLayer/enetity/dettaglioPartita.dart';

abstract class RegistraRisultatoState {}

class RegistraRisultatoInitial extends RegistraRisultatoState {}
class RegistraRisultatoLoading extends RegistraRisultatoState {}

class RisultatoRegistrato extends RegistraRisultatoState {
  final DettaglioPartita dettaglio;
  RisultatoRegistrato({required this.dettaglio});
}

class RegistraRisultatoErrore extends RegistraRisultatoState {
  final String messaggio;
  RegistraRisultatoErrore({required this.messaggio});
}
