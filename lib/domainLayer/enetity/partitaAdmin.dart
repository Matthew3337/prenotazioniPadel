import 'package:flutter/material.dart';
import 'package:thepadel/domainLayer/enetity/setPartita.dart';

//una partita nell'elenco del giorno dell'admin: e un riassunto, il dettaglio completo si chiede al tocco
class PartitaAdmin {
  //attributi
  final int id;
  final TimeOfDay oraInizio;
  final TimeOfDay oraFine;
  final String stato; //in minuscolo: creata, confermata, annullata, giocata
  final String tipo; //PUBBLICA o PRIVATA
  final List<String> giocatori; //nome e cognome, oppure "Giocatore del campo"
  final int postiLiberi;
  final List<SetPartita>? risultato; //null finche nessuno lo ha registrato

  PartitaAdmin({required this.id, required this.oraInizio, required this.oraFine, required this.stato, required this.tipo, required this.giocatori, required this.postiLiberi, required this.risultato});
}
