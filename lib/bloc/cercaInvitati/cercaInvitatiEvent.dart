abstract class CercaInvitatiEvent {
  const CercaInvitatiEvent();
}

//serve sia per il primo caricamento (cerca vuoto) sia per ogni ricerca; il debounce lo fa la pagina
class CercaInvitatiRichiesta extends CercaInvitatiEvent {
  final String cerca;
  const CercaInvitatiRichiesta({required this.cerca});
}
