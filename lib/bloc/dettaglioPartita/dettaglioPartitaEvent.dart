abstract class DettaglioPartitaEvent {
  const DettaglioPartitaEvent();
}

class DettaglioPartitaRichiesto extends DettaglioPartitaEvent {
  final int idPartita;
  const DettaglioPartitaRichiesto({required this.idPartita});
}

class EliminaPartitaRichiesta extends DettaglioPartitaEvent {
  final int idPartita;
  const EliminaPartitaRichiesta({required this.idPartita});
}

class EsciDaPartitaRichiesta extends DettaglioPartitaEvent {
  final int idPartita;
  const EsciDaPartitaRichiesta({required this.idPartita});
}

class ConfermaPartitaRichiesta extends DettaglioPartitaEvent {
  final int idPartita;
  const ConfermaPartitaRichiesta({required this.idPartita});
}

//tipo e "PUBBLICA" o "PRIVATA": quello che la partita deve diventare, non quello che ha adesso
class CambiaTipoRichiesto extends DettaglioPartitaEvent {
  final int idPartita;
  final String tipo;
  const CambiaTipoRichiesto({required this.idPartita, required this.tipo});
}
