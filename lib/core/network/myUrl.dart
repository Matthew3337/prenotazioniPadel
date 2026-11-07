import 'dart:convert';

import 'package:flutter/services.dart';

class MyUrl {

  //attributi 
  final String BaseUrl;

  final String AuthRegister;
  final String AuthLogin;

  final String CampiGetAll;
  final String CampiGetById;
  final String CampiCreate;
  final String CampiUpdate;
  final String CampiDelete;

  final String PrenotazioniSlotDisponibili;
  final String PrenotazioniCreate;
  final String PrenotazioniCancel;
  final String PrenotazioniProssima;
  final String PrenotazioniByUtente;

  final String PartiteDettaglio;
  final String PartitePubbliche;
  final String PartiteEntra;
  final String PartiteElimina;
  final String PartiteEsci;
  final String PartiteStorico;
  final String PartiteInvitabili;
  final String PartiteInvita;
  final String PartiteInviti;
  final String PartiteConferma;
  final String PartiteRisultato;
  final String PartiteMie;
  final String PartiteTipo;
  final String UtentiInvitabili;
  final String UtenteMe;

  final String Classifica;

  final String AdminPartite;
  final String AdminAvvisi;
  final String AdminUtenti;
  final String AdminLivello;
  final String AdminPartecipanti;
  final String AdminRisultato;
  final String AdminStato;
  final String AdminAnnulla;
  final String AdminImpostazioni;
  final String AdminLivelloCampo;
  final String AdminGiocatoriCampo;
  final String AdminRimuoviGiocatoreCampo;
  final String AdminCreaPartita;

  //metodi

  MyUrl({required this.AuthLogin, required this.AuthRegister, required this.BaseUrl, required this.CampiCreate, required this.CampiDelete, required this.CampiGetAll, required this.CampiGetById, required this.CampiUpdate, required this.PrenotazioniByUtente, required this.PrenotazioniCancel, required this.PrenotazioniCreate, required this.PrenotazioniProssima, required this.PrenotazioniSlotDisponibili, required this.PartiteDettaglio, required this.PartitePubbliche, required this.PartiteEntra, required this.PartiteElimina, required this.PartiteEsci, required this.PartiteStorico, required this.PartiteInvitabili, required this.PartiteInvita, required this.PartiteInviti, required this.PartiteConferma, required this.PartiteRisultato, required this.PartiteMie, required this.PartiteTipo, required this.UtentiInvitabili, required this.UtenteMe, required this.Classifica, required this.AdminPartite, required this.AdminAvvisi, required this.AdminUtenti, required this.AdminLivello, required this.AdminPartecipanti, required this.AdminRisultato, required this.AdminStato, required this.AdminAnnulla, required this.AdminImpostazioni, required this.AdminLivelloCampo, required this.AdminGiocatoriCampo, required this.AdminRimuoviGiocatoreCampo, required this.AdminCreaPartita});

  factory MyUrl.fromJsom(Map<String, dynamic> json)
  {
    return MyUrl(
      AuthLogin: json['AuthLogin'], 
      AuthRegister: json['AuthRegister'], 
      BaseUrl: json['BaseUrl'], 
      CampiCreate: json['CampiCreate'], 
      CampiDelete: json['CampiDelete'], 
      CampiGetAll: json['CampiGetAll'], 
      CampiGetById: json['CampiGetById'], 
      CampiUpdate: json['CampiUpdate'], 
      PrenotazioniByUtente: json['PrenotazioniByUtente'], 
      PrenotazioniCancel: json['PrenotazioniCancel'], 
      PrenotazioniCreate: json['PrenotazioniCreate'], 
      PrenotazioniProssima: json['PrenotazioniProssima'], 
      PrenotazioniSlotDisponibili: json['PrenotazioniSlotDisponibili'],
      PartiteDettaglio: json['PartiteDettaglio'],
      PartitePubbliche: json['PartitePubbliche'],
      PartiteEntra: json['PartiteEntra'],
      PartiteElimina: json['PartiteElimina'],
      PartiteEsci: json['PartiteEsci'],
      PartiteStorico: json['PartiteStorico'],
      PartiteInvitabili: json['PartiteInvitabili'],
      PartiteInvita: json['PartiteInvita'],
      PartiteInviti: json['PartiteInviti'],
      PartiteConferma: json['PartiteConferma'],
      PartiteRisultato: json['PartiteRisultato'],
      PartiteMie: json['PartiteMie'],
      PartiteTipo: json['PartiteTipo'],
      UtentiInvitabili: json['UtentiInvitabili'],
      UtenteMe: json['UtenteMe'],
      Classifica: json['Classifica'],
      AdminPartite: json['AdminPartite'],
      AdminAvvisi: json['AdminAvvisi'],
      AdminUtenti: json['AdminUtenti'],
      AdminLivello: json['AdminLivello'],
      AdminPartecipanti: json['AdminPartecipanti'],
      AdminRisultato: json['AdminRisultato'],
      AdminStato: json['AdminStato'],
      AdminAnnulla: json['AdminAnnulla'],
      AdminImpostazioni: json['AdminImpostazioni'],
      AdminLivelloCampo: json['AdminLivelloCampo'],
      AdminGiocatoriCampo: json['AdminGiocatoriCampo'],
      AdminRimuoviGiocatoreCampo: json['AdminRimuoviGiocatoreCampo'],
      AdminCreaPartita: json['AdminCreaPartita']
    );
  }

  static Future<MyUrl> loadUrl() async 
  {
    String json = await rootBundle.loadString('assets/json/api-endpoints.json');
    return MyUrl.fromJsom( jsonDecode(json) as Map<String, dynamic> );
  }

}