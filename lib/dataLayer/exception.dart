class TelefonoDuplicatoException implements Exception {
  final String messaggio = "il numero di telefono è gia registrato";
}

class ErroreGenericoServer implements Exception{
  final String messaggio = "errore generico del server, riprova piu tardi";
}