abstract class PartiteGiornoEvent {
  const PartiteGiornoEvent();
}

class PartiteGiornoRichieste extends PartiteGiornoEvent {
  final DateTime data;
  const PartiteGiornoRichieste({required this.data});
}
