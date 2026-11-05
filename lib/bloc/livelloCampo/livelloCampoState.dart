abstract class LivelloCampoState {}

class LivelloCampoInitial extends LivelloCampoState {}

//durante un cambio porta l'ultimo livello noto, cosi il selettore puo restare a schermo
class LivelloCampoLoading extends LivelloCampoState {
  final double? livello; //null durante il primo caricamento
  LivelloCampoLoading({this.livello});
}

class LivelloCampoCaricato extends LivelloCampoState {
  final double livello;
  LivelloCampoCaricato({required this.livello});
}

class LivelloCampoErrore extends LivelloCampoState {
  final double? livello; //l'ultimo livello noto, cosi il selettore torna al valore giusto; null se non e mai stato caricato
  final String messaggio;
  LivelloCampoErrore({required this.livello, required this.messaggio});
}
