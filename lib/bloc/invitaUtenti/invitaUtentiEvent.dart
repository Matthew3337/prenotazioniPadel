abstract class InvitaUtentiEvent {
  const InvitaUtentiEvent();
}

//serve sia per il primo caricamento (cerca vuoto) sia per ogni ricerca; il debounce lo fa la pagina
class InvitabiliRichiesti extends InvitaUtentiEvent {
  final int idPartita;
  final String cerca;
  const InvitabiliRichiesti({required this.idPartita, required this.cerca});
}

class InvitoRichiesto extends InvitaUtentiEvent {
  final int idPartita;
  final String telefono;
  const InvitoRichiesto({required this.idPartita, required this.telefono});
}
