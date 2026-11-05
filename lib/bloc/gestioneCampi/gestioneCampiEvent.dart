import 'package:flutter/material.dart';

abstract class GestioneCampiEvent {
  const GestioneCampiEvent();
}

class CampiRichiesti extends GestioneCampiEvent {
  const CampiRichiesti();
}

class SalvaCampoRichiesto extends GestioneCampiEvent {
  final int? id; //null se il campo e nuovo
  final String nome;
  final bool alCoperto;
  final TimeOfDay oraApertura;
  final TimeOfDay oraChiusura;
  const SalvaCampoRichiesto({required this.id, required this.nome, required this.alCoperto, required this.oraApertura, required this.oraChiusura});
}

class EliminaCampoRichiesto extends GestioneCampiEvent {
  final int id;
  const EliminaCampoRichiesto({required this.id});
}
