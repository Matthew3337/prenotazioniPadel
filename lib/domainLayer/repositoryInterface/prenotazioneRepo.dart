import 'package:thepadel/domainLayer/enetity/prenotazione.dart';

abstract class PrenotazioneRepo {

  Future<Prenotazione?> getProssimaPartita();

  Future<Prenotazione> creaPartita(int idCampo, DateTime data, String oraInizio, String tipo, {List<String> invitati = const []});
}