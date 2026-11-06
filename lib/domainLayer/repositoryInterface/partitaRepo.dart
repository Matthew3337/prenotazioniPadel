import 'package:thepadel/domainLayer/enetity/dettaglioPartita.dart';
import 'package:thepadel/domainLayer/enetity/invitoBacheca.dart';
import 'package:thepadel/domainLayer/enetity/partitaInvito.dart';
import 'package:thepadel/domainLayer/enetity/partitaPubblica.dart';
import 'package:thepadel/domainLayer/enetity/partitaStorico.dart';
import 'package:thepadel/domainLayer/enetity/setPartita.dart';
import 'package:thepadel/domainLayer/enetity/utenteInvitabile.dart';

abstract class PartitaRepo {

  Future<DettaglioPartita> getDettaglioPartita(int idPartita);

  Future<List<PartitaPubblica>> getPartitePubbliche();

  Future<DettaglioPartita> entraInPartita(int idPartita);

  Future<void> eliminaPartita(int idPartita);

  Future<void> esciDaPartita(int idPartita);

  Future<List<PartitaStorico>> getStorico();

  Future<List<PartitaStorico>> getMiePartite();

  Future<List<UtenteInvitabile>> getInvitabili(int idPartita, String cerca);

  Future<List<UtenteInvitabile>> getUtentiInvitabili(String cerca);

  Future<DettaglioPartita> invitaUtente(int idPartita, String telefono);

  Future<List<PartitaInvito>> getInviti();

  Future<List<InvitoBacheca>> getInvitiConStato();

  String getTelefonoUtente();

  Future<DettaglioPartita> confermaPartita(int idPartita);

  Future<DettaglioPartita> cambiaTipoPartita(int idPartita, String tipo);

  Future<DettaglioPartita> registraRisultato(int idPartita, List<int> squadra1, List<int> squadra2, List<SetPartita> set);
}
