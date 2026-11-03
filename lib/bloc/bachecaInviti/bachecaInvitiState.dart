import 'package:thepadel/domainLayer/enetity/dettaglioPartita.dart';
import 'package:thepadel/domainLayer/enetity/invitoBacheca.dart';
import 'package:thepadel/domainLayer/enetity/partitaInvito.dart';

abstract class BachecaInvitiState {}

class BachecaInvitiInitial extends BachecaInvitiState {}
class BachecaInvitiLoading extends BachecaInvitiState {}

//la lista puo essere vuota: l'utente non e stato invitato in nessuna partita ancora aperta (per l'admin e sempre vuota)
class BachecaInvitiCaricata extends BachecaInvitiState {
  final List<InvitoBacheca> voci;
  BachecaInvitiCaricata({required this.voci});

  //le sole partite, senza lo stato della conferma
  List<PartitaInvito> get partite
  {
    List<PartitaInvito> risultato = [];
    for(final voce in voci)
    {
      risultato.add(voce.partita);
    }
    return risultato;
  }
}

class BachecaInvitiErrore extends BachecaInvitiState {
  final String messaggio;
  BachecaInvitiErrore({required this.messaggio});
}

//gli stati della conferma sono anche dei Caricata, cosi la pagina continua a mostrare la lista
class ConfermaInvitoInCorso extends BachecaInvitiCaricata {
  final int idPartita;
  ConfermaInvitoInCorso({required super.voci, required this.idPartita});
}

//l'invito resta in lista, con giaConfermato true e puoConfermare false
class ConfermaInvitoRiuscita extends BachecaInvitiCaricata {
  final DettaglioPartita dettaglio;
  ConfermaInvitoRiuscita({required super.voci, required this.dettaglio});
}

class ConfermaInvitoErrore extends BachecaInvitiCaricata {
  final String messaggio;
  ConfermaInvitoErrore({required super.voci, required this.messaggio});
}
