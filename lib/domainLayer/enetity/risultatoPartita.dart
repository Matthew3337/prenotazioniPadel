import 'package:thepadel/domainLayer/enetity/setPartita.dart';

//il risultato di una partita giocata, visto dall'utente che lo chiede
class RisultatoPartita {
  //attributi
  final List<SetPartita> set; //solo i set giocati: 2 o 3
  final int? squadraUtente; //1 o 2, null se l'utente non ha una squadra
  final String? esito; //VINTA o PERSA, null se l'utente non ha una squadra
  final int? puntiAssegnati; //null finche i punti non sono calcolati

  RisultatoPartita({required this.set, required this.squadraUtente, required this.esito, required this.puntiAssegnati});
}
