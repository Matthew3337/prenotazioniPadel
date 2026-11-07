import 'package:flutter/material.dart';

//una partita della bacheca pubbliche: e un riassunto, il dettaglio completo si chiede quando l'utente entra
class PartitaPubblica {
  //attributi
  final int id;
  final int idCampo;
  final String nomeCampo;
  final DateTime dataPartita;
  final TimeOfDay oraInizio;
  final TimeOfDay oraFine;
  //null se il creatore ha eliminato l'account e la partita non e passata a un admin
  final String? nomeCreatore;
  final String? cognomeCreatore;
  //null quando il creatore della partita e un admin
  final double? livelloCreatore;
  final int postiLiberi;

  PartitaPubblica({required this.id, required this.idCampo, required this.nomeCampo, required this.dataPartita, required this.oraInizio, required this.oraFine, required this.nomeCreatore, required this.cognomeCreatore, required this.livelloCreatore, required this.postiLiberi});
}
