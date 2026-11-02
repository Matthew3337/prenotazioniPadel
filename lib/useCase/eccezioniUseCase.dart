//file diverso da quello delle ecce<ioni in quanto esse sono quelle verificabili prima di comunicare con il server 

class FormatoTelefonoNonValido implements Exception{
  final String message = "formato del telefono non valido,  10 cifre";
}

class PwMancante implements Exception{
  final String message = "compilare il campo password";
}

class NomeMancante implements Exception{
  final String message = "compilare il campo nome";

}

class CognomeMancante implements Exception{
  final String message = "compilare il campo cognome";

}

class DataNascitaMancante implements Exception{
  final String message = "compilare il campo data di nascita";

}

class TipoPartitaMancante implements Exception{
  final String message = "scegliere se la partita è pubblica o privata";

}


class SquadraIncompleta implements Exception{
  final String message = "ogni squadra deve avere 2 giocatori";

}

class GiocatoriRipetuti implements Exception{
  final String message = "ogni giocatore deve stare in una sola squadra";

}

class NumeroSetNonValido implements Exception{
  final String message = "il risultato deve avere 2 o 3 set";

}

class SetNonValido implements Exception{
  final String message = "i game di ogni set vanno da 0 a 6 e il set non può finire in parità";

}
