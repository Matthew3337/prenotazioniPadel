import 'package:thepadel/dataLayer/dataSource/dataSourcePrenotazione.dart';
import 'package:thepadel/domainLayer/enetity/prenotazione.dart';
import 'package:thepadel/domainLayer/repositoryInterface/prenotazioneRepo.dart';

class PrenotazioneRepoImpl implements PrenotazioneRepo {

  final DataSourcePrenotazione dsPrenotazione;

  PrenotazioneRepoImpl({required this.dsPrenotazione});

  @override
  Future<Prenotazione?> getProssimaPartita() {
    return dsPrenotazione.getProssimaPartita();
  }

  @override
  Future<Prenotazione> creaPartita(int idCampo, DateTime data, String oraInizio, String tipo) {
    return dsPrenotazione.creaPartita(idCampo, data, oraInizio, tipo);
  }
 
}