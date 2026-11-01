import 'package:thepadel/domainLayer/enetity/partitaInvito.dart';

abstract class BachecaInvitiState {}

class BachecaInvitiInitial extends BachecaInvitiState {}
class BachecaInvitiLoading extends BachecaInvitiState {}

//la lista puo essere vuota: l'utente non e stato invitato in nessuna partita ancora aperta (per l'admin e sempre vuota)
class BachecaInvitiCaricata extends BachecaInvitiState {
  final List<PartitaInvito> partite;
  BachecaInvitiCaricata({required this.partite});
}

class BachecaInvitiErrore extends BachecaInvitiState {
  final String messaggio;
  BachecaInvitiErrore({required this.messaggio});
}
