import 'package:thepadel/domainLayer/enetity/partitaStorico.dart';

abstract class MiePartiteState {}

class MiePartiteInitial extends MiePartiteState {}
class MiePartiteLoading extends MiePartiteState {}

//la lista puo essere vuota: l'utente non ha partite in programma (per l'admin e sempre vuota).
//Le partite sono in ordine di inizio, dalla piu vicina
class MiePartiteCaricate extends MiePartiteState {
  final List<PartitaStorico> partite;
  MiePartiteCaricate({required this.partite});
}

class MiePartiteErrore extends MiePartiteState {
  final String messaggio;
  MiePartiteErrore({required this.messaggio});
}
