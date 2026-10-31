import 'package:thepadel/domainLayer/enetity/dettaglioPartita.dart';
import 'package:thepadel/domainLayer/enetity/partitaPubblica.dart';

abstract class BachecaPubblicheState {}

class BachecaPubblicheInitial extends BachecaPubblicheState {}
class BachecaPubblicheLoading extends BachecaPubblicheState {}

//la lista puo essere vuota: vuol dire che non ci sono partite a cui l'utente puo entrare
class BachecaPubblicheCaricata extends BachecaPubblicheState {
  final List<PartitaPubblica> partite;
  BachecaPubblicheCaricata({required this.partite});
}

class BachecaPubblicheErrore extends BachecaPubblicheState {
  final String messaggio;
  BachecaPubblicheErrore({required this.messaggio});
}

//gli stati dell'ingresso si portano dietro la lista, cosi la pagina puo continuare a mostrarla
class IngressoInCorso extends BachecaPubblicheState {
  final List<PartitaPubblica> partite;
  final int idPartita;
  IngressoInCorso({required this.partite, required this.idPartita});
}

class IngressoRiuscito extends BachecaPubblicheState {
  final List<PartitaPubblica> partite;
  final DettaglioPartita dettaglio;
  IngressoRiuscito({required this.partite, required this.dettaglio});
}

class IngressoErrore extends BachecaPubblicheState {
  final List<PartitaPubblica> partite;
  final String messaggio;
  IngressoErrore({required this.partite, required this.messaggio});
}
