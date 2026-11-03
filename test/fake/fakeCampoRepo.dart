import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:thepadel/core/network/client.dart';
import 'package:thepadel/dataLayer/dataSource/dataSourceCampo.dart';
import 'package:thepadel/domainLayer/enetity/campo.dart';
import 'package:thepadel/domainLayer/enetity/slotOrario.dart';
import 'package:thepadel/repositoryImpl/campoRepoImpl.dart';

import 'fakePrenotazioneRepo.dart';

Campo campoDiTest({int id = 3, String nome = "Campo Centrale", bool alCoperto = true, TimeOfDay oraApertura = const TimeOfDay(hour: 9, minute: 0)})
{
  return Campo(id: id, nome: nome, alCoperto: alCoperto, oraApertura: oraApertura, oraChiusura: const TimeOfDay(hour: 23, minute: 0));
}

SlotOrario slotCampoDiTest({int idCampo = 3, String nomeCampo = "Campo Centrale", String oraInizio = "18:30:00", String oraFine = "20:00:00", bool disponibile = true})
{
  return SlotOrario(idCampo: idCampo, oraInizio: oraInizio, oraFine: oraFine, disponibile: disponibile, nomeCampo: nomeCampo);
}

//repository finto: estende quello vero (lo use case dipende dalla classe concreta)
//ma non passa mai dal data source, restituisce campi e slot o lancia gli errori impostati dal test
class FakeCampoRepo extends CampoRepoImpl
{
  //attributi
  List<Campo> campi = [campoDiTest()];
  List<SlotOrario> slots = [slotCampoDiTest()];
  Exception? erroreCampi;
  Exception? erroreSlot;
  int chiamateCampi = 0;
  int chiamateSlot = 0;
  List<DateTime> dateRicevute = [];

  //se c'e un completer per la data la chiamata resta in sospeso finche il test non lo completa
  Map<DateTime, Completer<List<SlotOrario>>> attesePerData = {};

  //metodi
  FakeCampoRepo() : super(dsCampo: DataSourceCampo(c: Client(c: MockClient((_) async => http.Response('', 500))), elencoUrl: urlDiTest()));

  @override
  Future<List<Campo>> getListaCampi() async
  {
    chiamateCampi++;

    if(erroreCampi != null)
    {
      throw erroreCampi!;
    }
    return campi;
  }

  @override
  Future<List<SlotOrario>> getListaOrariSlotCampiAll(DateTime data) async
  {
    chiamateSlot++;
    dateRicevute.add(data);

    final attesa = attesePerData[data];
    if(attesa != null)
    {
      return attesa.future;
    }
    if(erroreSlot != null)
    {
      throw erroreSlot!;
    }
    return slots;
  }
}
