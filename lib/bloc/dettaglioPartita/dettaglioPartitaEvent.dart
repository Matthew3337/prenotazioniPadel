abstract class DettaglioPartitaEvent {
  const DettaglioPartitaEvent();
}

class DettaglioPartitaRichiesto extends DettaglioPartitaEvent {
  final int idPartita;
  const DettaglioPartitaRichiesto({required this.idPartita});
}
