import 'package:thepadel/domainLayer/enetity/avvisoAdmin.dart';

abstract class BachecaAvvisiState {}

class BachecaAvvisiInitial extends BachecaAvvisiState {}
class BachecaAvvisiLoading extends BachecaAvvisiState {}

//la lista puo essere vuota; la sua lunghezza e anche il numero di avvisi mostrato nella home admin
class BachecaAvvisiCaricata extends BachecaAvvisiState {
  final List<AvvisoAdmin> avvisi;
  BachecaAvvisiCaricata({required this.avvisi});
}

class BachecaAvvisiErrore extends BachecaAvvisiState {
  final String messaggio;
  BachecaAvvisiErrore({required this.messaggio});
}
