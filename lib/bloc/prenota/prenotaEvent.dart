abstract class PrenotaEvent {
  const PrenotaEvent();
}

//carica o ricarica il giorno gia selezionato: serve all'apertura della pagina, per Riprova e al ritorno da una prenotazione
class PrenotaRichiesta extends PrenotaEvent {
  const PrenotaRichiesta();
}

class PrenotaGiornoCambiato extends PrenotaEvent {
  final DateTime giorno;
  const PrenotaGiornoCambiato({required this.giorno});
}
