import 'package:thepadel/domainLayer/enetity/dettaglioPartita.dart';
import 'package:thepadel/domainLayer/enetity/partitaPubblica.dart';

abstract class PartitaRepo {

  Future<DettaglioPartita> getDettaglioPartita(int idPartita);

  Future<List<PartitaPubblica>> getPartitePubbliche();

  Future<DettaglioPartita> entraInPartita(int idPartita);
}
