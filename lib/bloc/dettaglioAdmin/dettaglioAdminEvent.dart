import 'package:thepadel/domainLayer/enetity/setPartita.dart';

abstract class DettaglioAdminEvent {
  const DettaglioAdminEvent();
}

class DettaglioAdminRichiesto extends DettaglioAdminEvent {
  final int id;
  const DettaglioAdminRichiesto({required this.id});
}

class ModificaPartecipantiRichiesta extends DettaglioAdminEvent {
  final int id;
  final List<String> telefoni; //elenco completo degli utenti dopo la modifica, i posti del campo restano come sono
  const ModificaPartecipantiRichiesta({required this.id, required this.telefoni});
}

class ModificaRisultatoRichiesta extends DettaglioAdminEvent {
  final int id;
  final List<int> squadra1; //idPosto dei due giocatori della squadra 1
  final List<int> squadra2; //idPosto dei due giocatori della squadra 2
  final List<SetPartita> set; //solo i set giocati, nell'ordine
  const ModificaRisultatoRichiesta({required this.id, required this.squadra1, required this.squadra2, required this.set});
}

class ModificaStatoRichiesta extends DettaglioAdminEvent {
  final int id;
  final String stato; //in minuscolo: creata, confermata, annullata, giocata
  const ModificaStatoRichiesta({required this.id, required this.stato});
}

class AnnullaPartitaRichiesta extends DettaglioAdminEvent {
  final int id;
  const AnnullaPartitaRichiesta({required this.id});
}

class AggiungiGiocatoriCampoRichiesta extends DettaglioAdminEvent {
  final int id;
  final int numero;
  const AggiungiGiocatoriCampoRichiesta({required this.id, required this.numero});
}

class RimuoviGiocatoreCampoRichiesta extends DettaglioAdminEvent {
  final int id;
  final int idPosto;
  const RimuoviGiocatoreCampoRichiesta({required this.id, required this.idPosto});
}
