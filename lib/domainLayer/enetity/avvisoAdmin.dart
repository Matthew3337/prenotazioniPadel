import 'package:flutter/material.dart';

//un avviso della bacheca admin: una partita non ancora iniziata che ha bisogno di attenzione
class AvvisoAdmin {
  //attributi
  final int id;
  final int idPartita;
  final String nomeCampo;
  final DateTime dataPartita;
  final TimeOfDay oraInizio;
  final TimeOfDay oraFine;
  final int postiLiberi;

  AvvisoAdmin({required this.id, required this.idPartita, required this.nomeCampo, required this.dataPartita, required this.oraInizio, required this.oraFine, required this.postiLiberi});
}
