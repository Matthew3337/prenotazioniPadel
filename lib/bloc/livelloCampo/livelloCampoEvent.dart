abstract class LivelloCampoEvent {
  const LivelloCampoEvent();
}

class LivelloCampoRichiesto extends LivelloCampoEvent {
  const LivelloCampoRichiesto();
}

class CambiaLivelloCampoRichiesto extends LivelloCampoEvent {
  final double livello;
  const CambiaLivelloCampoRichiesto({required this.livello});
}
