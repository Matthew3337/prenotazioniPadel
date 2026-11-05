import 'package:flutter/material.dart';
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

  Future<CampoModel> creaCampo(String nome, bool alCoperto, TimeOfDay oraApertura, TimeOfDay oraChiusura) async
  {
    String token = sl<SharedPreferences>().getString("jwt")!;
    Map<String, dynamic> body = _bodyCampo(nome, alCoperto, oraApertura, oraChiusura);
    dynamic res = await c.post(elencoUrl.BaseUrl + elencoUrl.CampiCreate, body, token: token);

    return _leggiCampo(res);
  }

  Future<CampoModel> modificaCampo(int id, String nome, bool alCoperto, TimeOfDay oraApertura, TimeOfDay oraChiusura) async
  {
    String token = sl<SharedPreferences>().getString("jwt")!;
    Map<String, dynamic> body = _bodyCampo(nome, alCoperto, oraApertura, oraChiusura);
    dynamic res = await c.put(elencoUrl.BaseUrl + elencoUrl.CampiUpdate.replaceFirst("{id}", id.toString()), body, token: token);

    return _leggiCampo(res);
  }

  Future<void> eliminaCampo(int id) async
  {
    String token = sl<SharedPreferences>().getString("jwt")!;
    dynamic res = await c.delete(elencoUrl.BaseUrl + elencoUrl.CampiDelete.replaceFirst("{id}", id.toString()), token: token);

    if(res is Map<String, dynamic> && !res.containsKey("errore") && res['status'] == 204) //BUON FINE, il server non manda nessun body
    {
      return;
    }
    else
    {
      throw _erroreDaRisposta(res);
    }
  }

  //creazione e modifica mandano gli stessi dati: l'id del campo, se c'e, sta nell'url
  Map<String, dynamic> _bodyCampo(String nome, bool alCoperto, TimeOfDay oraApertura, TimeOfDay oraChiusura)
  {
    return {"nome": nome, "alCoperto": alCoperto, "oraApertura": _formattaOra(oraApertura), "oraChiusura": _formattaOra(oraChiusura)};
  }

  String _formattaOra(TimeOfDay ora)
  {
    return "${ora.hour.toString().padLeft(2,'0')}:${ora.minute.toString().padLeft(2,'0')}";
  }

  CampoModel _leggiCampo(dynamic res)
  {
    if(res is Map<String, dynamic> && res.containsKey("id")) //BUON FINE, il server restituisce il campo salvato
    {
      return CampoModel.fromJson(res);
    }
    else
    {
      throw _erroreDaRisposta(res);
    }
  }

  //stessi codici degli endpoint admin, compreso il 404 che qui vuol dire campo inesistente
  Exception _erroreDaRisposta(dynamic res)
  {
    if(res is Map<String, dynamic> && res.containsKey("errore"))
    {
      int status = res['status'] as int;

      if(status == 404) //CAMPO INESISTENTE
      {
        return PartitaNonTrovata(messaggio: res['errore']);
      }
      else if(status == 400 || status == 403 || status == 409) //DATI NON VALIDI, NON ADMIN O CAMPO CON PARTITE COLLEGATE
      {
        return OperazioneRifiutata(messaggio: res['errore']);
      }
    }

    //ALTRI ERRORI, compresa la risposta senza body (es. token scaduto)
    return ErroreGenericoServer();
  }
}