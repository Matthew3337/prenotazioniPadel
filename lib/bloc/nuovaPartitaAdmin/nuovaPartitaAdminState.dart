import 'package:thepadel/domainLayer/enetity/dettaglioPartita.dart';

abstract class NuovaPartitaAdminState {}

class NuovaPartitaAdminInitial extends NuovaPartitaAdminState {}
class NuovaPartitaAdminLoading extends NuovaPartitaAdminState {}

class PartitaAdminCreata extends NuovaPartitaAdminState {
  final DettaglioPartita dettaglio;
  PartitaAdminCreata({required this.dettaglio});
}

class NuovaPartitaAdminErrore extends NuovaPartitaAdminState {
  final String messaggio;
  NuovaPartitaAdminErrore({required this.messaggio});
}
