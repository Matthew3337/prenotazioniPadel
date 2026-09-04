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
