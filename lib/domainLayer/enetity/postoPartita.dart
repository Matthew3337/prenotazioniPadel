//un posto occupato della partita: se tipo e "CAMPO" e un giocatore del campo e i dati dell'utente sono tutti null
class PostoPartita {
  //attributi
  final int? idPosto; //id della partecipazione, serve per comporre le squadre del risultato
  final String tipo; //"UTENTE" o "CAMPO"
  final String? telefono;
  final String? nome;
  final String? cognome;
  final double? livello;
  final bool confermata;
  final int? squadra; //1 o 2, null finche il risultato non e registrato
  final bool eliminato; //true se e il posto di un utente che ha eliminato l'account: tipo UTENTE ma dati tutti null

  //eliminato ha un default: i posti costruiti a mano nell'app e nei test restano validi senza passarlo
  PostoPartita({required this.idPosto, required this.tipo, required this.telefono, required this.nome, required this.cognome, required this.livello, required this.confermata, required this.squadra, this.eliminato = false});
}
