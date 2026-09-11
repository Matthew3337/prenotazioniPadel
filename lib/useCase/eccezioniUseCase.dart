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