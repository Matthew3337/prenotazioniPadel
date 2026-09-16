import 'package:thepadel/domainLayer/enetity/prenotazione.dart';

abstract class PrenotazioneRepo {

  Future<Prenotazione?> getProssimaPartita();
}