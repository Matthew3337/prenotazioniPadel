abstract class GestioneLivelliEvent {
  const GestioneLivelliEvent();
}

//serve sia per il primo caricamento (cerca vuoto) sia per ogni ricerca; il debounce lo fa la pagina
class UtentiRichiesti extends GestioneLivelliEvent {
  final String cerca;
  const UtentiRichiesti({required this.cerca});
}

class CambiaLivelloRichiesto extends GestioneLivelliEvent {
  final String telefono;
  final double livello;
  const CambiaLivelloRichiesto({required this.telefono, required this.livello});
}
