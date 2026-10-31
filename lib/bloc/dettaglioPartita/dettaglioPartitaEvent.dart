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
