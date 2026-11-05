import 'package:thepadel/dataLayer/dataSource/dataSourceAdmin.dart';
import 'package:thepadel/domainLayer/enetity/avvisoAdmin.dart';
import 'package:thepadel/domainLayer/enetity/dettaglioPartita.dart';
import 'package:thepadel/domainLayer/enetity/partiteCampoAdmin.dart';
import 'package:thepadel/domainLayer/enetity/setPartita.dart';
import 'package:thepadel/domainLayer/enetity/utenteAdmin.dart';
import 'package:thepadel/domainLayer/repositoryInterface/adminRepo.dart';

class AdminRepoImpl implements AdminRepo {

  final DataSourceAdmin dsAdmin;

  AdminRepoImpl({required this.dsAdmin});

  @override
  Future<List<PartiteCampoAdmin>> getPartiteDelGiorno(DateTime data) {
    return dsAdmin.getPartiteDelGiorno(data);
  }

  @override
  Future<List<AvvisoAdmin>> getAvvisi() {
    return dsAdmin.getAvvisi();
  }

  @override
  Future<List<UtenteAdmin>> getUtenti(String cerca) {
    return dsAdmin.getUtenti(cerca);
  }

  @override
  Future<UtenteAdmin> cambiaLivello(String telefono, double livello) {
    return dsAdmin.cambiaLivello(telefono, livello);
  }

  @override
  Future<DettaglioPartita> modificaPartecipanti(int idPartita, List<String> telefoni) {
    return dsAdmin.modificaPartecipanti(idPartita, telefoni);
  }

  @override
  Future<DettaglioPartita> modificaRisultato(int idPartita, List<int> squadra1, List<int> squadra2, List<SetPartita> set) {
    return dsAdmin.modificaRisultato(idPartita, squadra1, squadra2, set);
  }

  @override
  Future<DettaglioPartita> modificaStato(int idPartita, String stato) {
    return dsAdmin.modificaStato(idPartita, stato);
  }

  @override
  Future<DettaglioPartita> annullaPartita(int idPartita) {
    return dsAdmin.annullaPartita(idPartita);
  }

  @override
  Future<double> getLivelloGiocatoriCampo() {
    return dsAdmin.getLivelloGiocatoriCampo();
  }

  @override
  Future<double> setLivelloGiocatoriCampo(double livello) {
    return dsAdmin.setLivelloGiocatoriCampo(livello);
  }

  @override
  Future<DettaglioPartita> aggiungiGiocatoriCampo(int idPartita, int numero) {
    return dsAdmin.aggiungiGiocatoriCampo(idPartita, numero);
  }

  @override
  Future<DettaglioPartita> rimuoviGiocatoreCampo(int idPartita, int idPosto) {
    return dsAdmin.rimuoviGiocatoreCampo(idPartita, idPosto);
  }

  @override
  Future<DettaglioPartita> creaPartitaAdmin(int idCampo, DateTime data, String oraInizio, String tipo, List<String> telefoni, int giocatoriCampo) {
    return dsAdmin.creaPartitaAdmin(idCampo, data, oraInizio, tipo, telefoni, giocatoriCampo);
  }

}
