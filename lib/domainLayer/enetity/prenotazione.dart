import 'package:flutter/material.dart';

class Prenotazione {
  //attributi 
  final int id;
  final int idCampo;
  final int idGiocatore1;
  final int? idGiocatore2;
  final int? idGiocatore3;
  final int? idGiocatore4;
  final DateTime dataPrenotazione;
  final TimeOfDay oraInizio;
  final TimeOfDay oraFine;

  Prenotazione({required this.dataPrenotazione, required this.id, required this.idCampo, required this.idGiocatore1, required this.idGiocatore2, required this.idGiocatore3, required this.idGiocatore4, required this.oraFine, required this.oraInizio});
}