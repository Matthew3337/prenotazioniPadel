import 'package:flutter/material.dart';

class Prenotazione {
  //attributi 
  final int id;
  final int idCampo;
  final String telefonoGiocatore1;
  final String? telefonoGiocatore2;
  final String? telefonoGiocatore3;
  final String? telefonoGiocatore4;
  final DateTime dataPrenotazione;
  final TimeOfDay oraInizio;
  final TimeOfDay oraFine;
  final String stato;

  Prenotazione({required this.dataPrenotazione, required this.id, required this.idCampo, required this.telefonoGiocatore1, required this.telefonoGiocatore2, required this.telefonoGiocatore3, required this.telefonoGiocatore4, required this.oraFine, required this.oraInizio, required this.stato});
}