import 'package:flutter/material.dart';
import 'package:thepadel/domainLayer/enetity/azioniPartita.dart';
import 'package:thepadel/domainLayer/enetity/postoPartita.dart';

class DettaglioPartita {
  //attributi
  final int id;
  final int idCampo;
  final String nomeCampo;
  final DateTime dataPartita;
  final TimeOfDay oraInizio;
  final TimeOfDay oraFine;
  final String stato; //in minuscolo: creata, confermata, annullata, giocata
  final String tipo; //PUBBLICA o PRIVATA
  final String telefonoCreatore;
  final List<PostoPartita> posti; //solo i posti occupati, il creatore e sempre il primo
  final AzioniPartita azioni;

  DettaglioPartita({required this.id, required this.idCampo, required this.nomeCampo, required this.dataPartita, required this.oraInizio, required this.oraFine, required this.stato, required this.tipo, required this.telefonoCreatore, required this.posti, required this.azioni});

  //metodi

  //i posti sono sempre 4, quelli che il server non manda sono liberi
  int get postiLiberi => 4 - posti.length;
}
