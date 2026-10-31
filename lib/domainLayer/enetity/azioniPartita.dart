//cosa puo fare l'utente sulla partita, lo calcola il server in base a chi e e allo stato della partita
class AzioniPartita {
  //attributi
  final bool puoInvitare;
  final bool puoEliminare;
  final bool puoUscire;
  final bool puoConfermare;
  final bool puoRegistrareRisultato;

  AzioniPartita({required this.puoInvitare, required this.puoEliminare, required this.puoUscire, required this.puoConfermare, required this.puoRegistrareRisultato});
}
