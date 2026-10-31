import 'package:thepadel/domainLayer/enetity/dettaglioPartita.dart';

abstract class PartitaRepo {

  Future<DettaglioPartita> getDettaglioPartita(int idPartita);
}
