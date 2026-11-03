//quanto manca all'utente per salire in classifica: entrambi i campi sono null se l'utente e primo.
//La posizione sopra non e sempre la sua meno uno, perche chi ha gli stessi punti ha la stessa posizione (1, 2, 2, 4)
class DistaccoClassifica {
  //attributi
  final int? punti;
  final int? posizioneSopra;

  DistaccoClassifica({required this.punti, required this.posizioneSopra});
}
