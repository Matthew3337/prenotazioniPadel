import 'package:thepadel/domainLayer/enetity/partiteCampoAdmin.dart';

abstract class PartiteGiornoState {}

class PartiteGiornoInitial extends PartiteGiornoState {}
class PartiteGiornoLoading extends PartiteGiornoState {}

//c'e un elemento per ogni campo: quello senza partite ha la lista interna vuota
class PartiteGiornoCaricate extends PartiteGiornoState {
  final List<PartiteCampoAdmin> campi;
  PartiteGiornoCaricate({required this.campi});
}

class PartiteGiornoErrore extends PartiteGiornoState {
  final String messaggio;
  PartiteGiornoErrore({required this.messaggio});
}
