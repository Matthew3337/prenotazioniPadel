//un posto occupato della partita: se tipo e "CAMPO" e un giocatore del campo e i dati dell'utente sono tutti null
class PostoPartita {
  //attributi
  final String tipo; //"UTENTE" o "CAMPO"
  final String? telefono;
  final String? nome;
  final String? cognome;
  final double? livello;
  final bool confermata;

  PostoPartita({required this.tipo, required this.telefono, required this.nome, required this.cognome, required this.livello, required this.confermata});
}
