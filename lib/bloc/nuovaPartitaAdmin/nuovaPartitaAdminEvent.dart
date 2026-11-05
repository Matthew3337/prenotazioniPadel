abstract class NuovaPartitaAdminEvent {
  const NuovaPartitaAdminEvent();
}

class CreaPartitaAdminRichiesta extends NuovaPartitaAdminEvent {
  final int idCampo;
  final DateTime data;
  final String oraInizio;
  final String tipo; //"PUBBLICA" o "PRIVATA"
  final List<String> telefoni; //gli utenti che giocano, almeno uno: l'admin non occupa un posto
  final int giocatoriCampo; //da 0 a 3
  const CreaPartitaAdminRichiesta({required this.idCampo, required this.data, required this.oraInizio, required this.tipo, required this.telefoni, required this.giocatoriCampo});
}
