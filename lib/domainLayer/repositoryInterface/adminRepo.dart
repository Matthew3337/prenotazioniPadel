import 'package:thepadel/domainLayer/enetity/avvisoAdmin.dart';
import 'package:thepadel/domainLayer/enetity/dettaglioPartita.dart';
import 'package:thepadel/domainLayer/enetity/partiteCampoAdmin.dart';
import 'package:thepadel/domainLayer/enetity/setPartita.dart';
import 'package:thepadel/domainLayer/enetity/utenteAdmin.dart';

abstract class AdminRepo {

  Future<List<PartiteCampoAdmin>> getPartiteDelGiorno(DateTime data);

  Future<List<AvvisoAdmin>> getAvvisi();

  Future<List<UtenteAdmin>> getUtenti(String cerca);

  Future<UtenteAdmin> cambiaLivello(String telefono, double livello);

  Future<DettaglioPartita> modificaPartecipanti(int idPartita, List<String> telefoni);

  Future<DettaglioPartita> modificaRisultato(int idPartita, List<int> squadra1, List<int> squadra2, List<SetPartita> set);

  Future<DettaglioPartita> modificaStato(int idPartita, String stato);

  Future<DettaglioPartita> annullaPartita(int idPartita);
}
