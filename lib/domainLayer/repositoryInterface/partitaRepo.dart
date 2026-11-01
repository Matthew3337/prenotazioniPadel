import 'package:thepadel/domainLayer/enetity/dettaglioPartita.dart';
import 'package:thepadel/domainLayer/enetity/partitaPubblica.dart';
import 'package:thepadel/domainLayer/enetity/partitaStorico.dart';

abstract class PartitaRepo {

  Future<DettaglioPartita> getDettaglioPartita(int idPartita);

  Future<List<PartitaPubblica>> getPartitePubbliche();

  Future<DettaglioPartita> entraInPartita(int idPartita);

  Future<void> eliminaPartita(int idPartita);

  Future<void> esciDaPartita(int idPartita);

  Future<List<PartitaStorico>> getStorico();
}
