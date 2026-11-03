//file diverso da quello delle ecce<ioni in quanto esse sono quelle verificabili prima di comunicare con il server 

class FormatoTelefonoNonValido implements Exception{
  final String message = "Il numero deve avere 10 cifre";
}

class PwMancante implements Exception{
  final String message = "Inserisci una password";
}

class NomeMancante implements Exception{
  final String message = "Inserisci il nome";

}

class CognomeMancante implements Exception{
  final String message = "Inserisci il cognome";

}

class DataNascitaMancante implements Exception{
  final String message = "Inserisci la data di nascita";

}

class TipoPartitaMancante implements Exception{
  final String message = "Scegli se la partita è pubblica o privata";

}


class SquadraIncompleta implements Exception{
  final String message = "Ogni squadra deve avere 2 giocatori.";

}

class GiocatoriRipetuti implements Exception{
  final String message = "Ogni giocatore può stare in una sola squadra.";

}

class NumeroSetNonValido implements Exception{
  final String message = "Il risultato deve avere 2 o 3 set.";

}

class SetNonValido implements Exception{
  final String message = "Un set non può finire in parità, e i game vanno da 0 a 6.";

}
