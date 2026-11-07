import 'package:flutter/material.dart';

//una partita della bacheca inviti, cioe una partita in cui l'utente e entrato perche invitato dal creatore
class PartitaInvito {
  //attributi
  final int id;
  final int idCampo;
  final String nomeCampo;
  final DateTime dataPartita;
  final TimeOfDay oraInizio;
  final TimeOfDay oraFine;
  final String stato; //in minuscolo: creata o confermata, le altre il server non le manda
  final String tipo; //PUBBLICA o PRIVATA
  //null se il creatore ha eliminato l'account e la partita non e passata a un admin
  final String? nomeCreatore;
  final String? cognomeCreatore;

  PartitaInvito({required this.id, required this.idCampo, required this.nomeCampo, required this.dataPartita, required this.oraInizio, required this.oraFine, required this.stato, required this.tipo, required this.nomeCreatore, required this.cognomeCreatore});
}
