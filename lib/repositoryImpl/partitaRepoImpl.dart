import 'package:thepadel/dataLayer/dataSource/dataSourcePartita.dart';
import 'package:thepadel/domainLayer/enetity/dettaglioPartita.dart';
import 'package:thepadel/domainLayer/enetity/partitaInvito.dart';
import 'package:thepadel/domainLayer/enetity/partitaPubblica.dart';
import 'package:thepadel/domainLayer/enetity/partitaStorico.dart';
import 'package:thepadel/domainLayer/enetity/utenteInvitabile.dart';
import 'package:thepadel/domainLayer/repositoryInterface/partitaRepo.dart';

class PartitaRepoImpl implements PartitaRepo {

  final DataSourcePartita dsPartita;

  PartitaRepoImpl({required this.dsPartita});

  @override
  Future<DettaglioPartita> getDettaglioPartita(int idPartita) {
    return dsPartita.getDettaglioPartita(idPartita);
  }

  @override
  Future<List<PartitaPubblica>> getPartitePubbliche() {
    return dsPartita.getPartitePubbliche();
  }

  @override
  Future<DettaglioPartita> entraInPartita(int idPartita) {
    return dsPartita.entraInPartita(idPartita);
  }

  @override
  Future<void> eliminaPartita(int idPartita) {
    return dsPartita.eliminaPartita(idPartita);
  }

  @override
  Future<void> esciDaPartita(int idPartita) {
    return dsPartita.esciDaPartita(idPartita);
  }

  @override
  Future<List<PartitaStorico>> getStorico() {
    return dsPartita.getStorico();
  }

  @override
  Future<List<UtenteInvitabile>> getInvitabili(int idPartita, String cerca) {
    return dsPartita.getInvitabili(idPartita, cerca);
  }

  @override
  Future<DettaglioPartita> invitaUtente(int idPartita, String telefono) {
    return dsPartita.invitaUtente(idPartita, telefono);
  }

  @override
  Future<List<PartitaInvito>> getInviti() {
    return dsPartita.getInviti();
  }

  @override
  Future<DettaglioPartita> confermaPartita(int idPartita) {
    return dsPartita.confermaPartita(idPartita);
  }

}
