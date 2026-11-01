import 'package:flutter/material.dart';
import 'package:thepadel/domainLayer/enetity/risultatoPartita.dart';

//una partita dello storico dell'utente: il dettaglio completo si chiede quando la apre
class PartitaStorico {
  //attributi
  final int id;
  final int idCampo;
  final String nomeCampo;
  final DateTime dataPartita;
  final TimeOfDay oraInizio;
  final TimeOfDay oraFine;
  final String stato; //in minuscolo: creata, confermata, giocata (le annullate il server non le manda)
  final String tipo; //PUBBLICA o PRIVATA
  final RisultatoPartita? risultato; //null finche il risultato non e registrato

  PartitaStorico({required this.id, required this.idCampo, required this.nomeCampo, required this.dataPartita, required this.oraInizio, required this.oraFine, required this.stato, required this.tipo, required this.risultato});
}
