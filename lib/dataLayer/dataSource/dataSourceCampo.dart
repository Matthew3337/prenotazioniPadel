import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thepadel/core/di/depInjection.dart';
import 'package:thepadel/core/network/client.dart';
import 'package:thepadel/core/network/myUrl.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/dataLayer/model/campoModel.dart';
import 'package:thepadel/dataLayer/model/slotOrarioModel.dart';
import 'package:thepadel/domainLayer/enetity/campo.dart';

class DataSourceCampo{
  //attributi 
  final Client c;
  final MyUrl elencoUrl;

  //metodi 
  DataSourceCampo({required this.c, required this.elencoUrl});

  Future<List<SlotOrarioModel>> getSlotByIdEData(int id, DateTime data) async
  {
    String token = sl<SharedPreferences>().getString("jwt")!;
    dynamic res = await c.get(elencoUrl.BaseUrl + elencoUrl.PrenotazioniSlotDisponibili.replaceFirst("{id}", id.toString()).replaceAll( "{data}",data.toIso8601String().split('T').first), token: token);

    //l api restituisce comunque tutti gli slot specificando poi quali sono disponibili e quali no quindi l unico errore da gestire è quello generico 
    if(res is List)  //l'api restituisce la lista di orari se tutto va a buon. fine 
    {
      return res.map((e) => SlotOrarioModel.fromJson(e as Map<String,dynamic>)).toList();
    }
    else //se c'è un errore allora restituisce solo una mappa 
    {
      throw ErroreGenericoServer();
    }

  }

  Future<List<Campo>> getListaCampi() async
  {
    String token = sl<SharedPreferences>().getString("jwt")!;
    dynamic res = await c.get(elencoUrl.BaseUrl + elencoUrl.CampiGetAll, token: token);

    //l api restituisce comunque tutti gli slot specificando poi quali sono disponibili e quali no quindi l unico errore da gestire è quello generico 
    if(res is List)  //l'api restituisce la lista dei campi se tutto va a buon. fine 
    {
      return res.map((e) => CampoModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    else //se c'è un errore allora restituisce solo una mappa 
    {
      throw ErroreGenericoServer();
    }

  }

  
}