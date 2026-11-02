//una riga della classifica: chi ha gli stessi punti ha la stessa posizione (1, 2, 2, 4)
class VoceClassifica {
  //attributi
  final int posizione;
  final String telefono;
  final String nome;
  final String cognome;
  final int punteggio;
  final bool utenteCorrente;

  VoceClassifica({required this.posizione, required this.telefono, required this.nome, required this.cognome, required this.punteggio, required this.utenteCorrente});
}
