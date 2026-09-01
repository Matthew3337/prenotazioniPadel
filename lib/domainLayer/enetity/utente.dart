class Utente {

  //attributi 
  final int id;
  final String telefono;
  final String nome;
  final String cognome;
  final String password;
  final DateTime dataNasctia;
  final bool isAdmin;
  final double livello;

  Utente({required this.id, required this.telefono, required this.nome, required this.cognome, required this.password, required this.dataNasctia, required this.isAdmin, required this.livello});

}
