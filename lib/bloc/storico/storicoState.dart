import 'package:thepadel/domainLayer/enetity/partitaStorico.dart';

abstract class StoricoState {}

class StoricoInitial extends StoricoState {}
class StoricoLoading extends StoricoState {}

//la lista puo essere vuota: l'utente non ha ancora partite (per l'admin e sempre vuota)
class StoricoCaricato extends StoricoState {
  final List<PartitaStorico> partite;
  StoricoCaricato({required this.partite});
}

class StoricoErrore extends StoricoState {
  final String messaggio;
  StoricoErrore({required this.messaggio});
}
