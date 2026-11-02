import 'package:thepadel/domainLayer/enetity/voceClassifica.dart';

abstract class ClassificaState {}

class ClassificaInitial extends ClassificaState {}
class ClassificaLoading extends ClassificaState {}

//la lista e gia ordinata dal server e puo essere vuota se non ci sono utenti in classifica
class ClassificaCaricata extends ClassificaState {
  final List<VoceClassifica> voci;
  ClassificaCaricata({required this.voci});
}

class ClassificaErrore extends ClassificaState {
  final String messaggio;
  ClassificaErrore({required this.messaggio});
}
