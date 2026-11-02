import 'package:thepadel/domainLayer/enetity/setPartita.dart';

abstract class RegistraRisultatoEvent {
  const RegistraRisultatoEvent();
}

class RegistraRisultatoRichiesto extends RegistraRisultatoEvent {
  final int idPartita;
  final List<int> squadra1; //idPosto dei due giocatori della squadra 1
  final List<int> squadra2; //idPosto dei due giocatori della squadra 2
  final List<SetPartita> set; //solo i set giocati, nell'ordine
  const RegistraRisultatoRichiesto({required this.idPartita, required this.squadra1, required this.squadra2, required this.set});
}
