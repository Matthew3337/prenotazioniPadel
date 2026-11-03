import 'package:thepadel/dataLayer/dataSource/dataSourcePartita.dart';
import 'package:thepadel/domainLayer/enetity/dettaglioPartita.dart';
import 'package:thepadel/domainLayer/enetity/invitoBacheca.dart';
import 'package:thepadel/domainLayer/enetity/partitaInvito.dart';
import 'package:thepadel/domainLayer/enetity/partitaPubblica.dart';
import 'package:thepadel/domainLayer/enetity/partitaStorico.dart';
import 'package:thepadel/domainLayer/enetity/setPartita.dart';
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

  //la lista degli inviti non dice se si possono confermare: lo so solo leggendo il dettaglio di ognuno
  @override
  Future<List<InvitoBacheca>> getInvitiConStato() async {
    final inviti = await getInviti();
    final telefono = getTelefonoUtente();
    return Future.wait(inviti.map((invito) => _caricaStatoInvito(invito, telefono)));
  }

  Future<InvitoBacheca> _caricaStatoInvito(PartitaInvito invito, String telefono) async {
    try {
      final dettaglio = await getDettaglioPartita(invito.id);

      bool giaConfermato = false;
      for (final posto in dettaglio.posti) {
        if (posto.tipo == "UTENTE" && posto.telefono == telefono && posto.confermata) {
          giaConfermato = true;
        }
      }

      return InvitoBacheca(partita: invito, puoConfermare: dettaglio.azioni.puoConfermare, giaConfermato: giaConfermato);
    } on Exception {
      //un dettaglio che non arriva non deve far perdere l'intera lista: l'invito resta, ma senza azioni
      return InvitoBacheca(partita: invito, puoConfermare: false, giaConfermato: false);
    }
  }

  @override
  String getTelefonoUtente() {
    return dsPartita.getTelefonoUtente();
  }

  @override
  Future<DettaglioPartita> confermaPartita(int idPartita) {
    return dsPartita.confermaPartita(idPartita);
  }

  @override
  Future<DettaglioPartita> registraRisultato(int idPartita, List<int> squadra1, List<int> squadra2, List<SetPartita> set) {
    return dsPartita.registraRisultato(idPartita, squadra1, squadra2, set);
  }

}
