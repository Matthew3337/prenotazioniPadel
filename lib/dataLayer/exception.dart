//AUTH EXCEPTION

class TelefonoDuplicatoException implements Exception {
  final String messaggio = "il numero di telefono è gia registrato";
}

class ErroreGenericoServer implements Exception{
  final String messaggio = "errore generico del server, riprova piu tardi";
}

class TelOPasswordErrata implements Exception{
  final String messaggio = "telefono o password errati";
}

class DataNonValida implements Exception{
  final String messaggio = "la data di nascita non è valida";
}

//PRENOTAZIONE EXCEPTION
//qui il messaggio non e fisso ma arriva dal campo "errore" del server, cosi l'utente vede la regola violata

class PrenotazioneNonValida implements Exception{ //400
  final String messaggio;
  PrenotazioneNonValida({required this.messaggio});
}

class CampoInesistente implements Exception{ //404
  final String messaggio;
  CampoInesistente({required this.messaggio});
}

class SlotNonDisponibile implements Exception{ //409: slot occupato, fuori orario o data/ora gia passata
  final String messaggio;
  SlotNonDisponibile({required this.messaggio});
}

//PARTITA EXCEPTION

class PartitaNonTrovata implements Exception{ //404: la partita non esiste o l'utente non puo vederla
  final String messaggio;
  PartitaNonTrovata({required this.messaggio});
}

class IngressoRifiutato implements Exception{ //409: partita al completo, ingresso chiuso, gia partecipante o partita non piu aperta
  final String messaggio;
  IngressoRifiutato({required this.messaggio});
}
