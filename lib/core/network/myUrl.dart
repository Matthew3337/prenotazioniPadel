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

  //metodi

  MyUrl({required this.AuthLogin, required this.AuthRegister, required this.BaseUrl, required this.CampiCreate, required this.CampiDelete, required this.CampiGetAll, required this.CampiGetById, required this.CampiUpdate, required this.PrenotazioniByUtente, required this.PrenotazioniCancel, required this.PrenotazioniCreate, required this.PrenotazioniProssima, required this.PrenotazioniSlotDisponibili});

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
      PrenotazioniSlotDisponibili: json['PrenotazioniSlotDisponibili']
    );
  }

  static Future<MyUrl> loadUrl() async 
  {
    String json = await rootBundle.loadString('assets/json/api-endpoints.json');
    return MyUrl.fromJsom( jsonDecode(json) as Map<String, dynamic> );
  }

}