class Utente {

  //attributi 
  final int id;
  final String telefono;
  final String nome;
  final String cognome;
  final String password;
  final DateTime dataNasctia;
  final bool isAdmin;

  Utente({required this.id, required this.telefono, required this.nome, required this.cognome, required this.password, required this.dataNasctia, required this.isAdmin});

}
