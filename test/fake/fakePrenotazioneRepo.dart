import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:thepadel/core/network/client.dart';
import 'package:thepadel/core/network/myUrl.dart';
import 'package:thepadel/dataLayer/dataSource/dataSourcePrenotazione.dart';
import 'package:thepadel/domainLayer/enetity/prenotazione.dart';
import 'package:thepadel/domainLayer/enetity/slotOrario.dart';
import 'package:thepadel/repositoryImpl/prenotazioneRepoImpl.dart';

//elenco degli url usato nei test, uguale a quello di assets/json/api-endpoints.json
MyUrl urlDiTest()
{
  return MyUrl(
    BaseUrl: "http://test",
    AuthRegister: "/api/auth/register",
    AuthLogin: "/api/auth/login",
    CampiGetAll: "/api/campi",
    CampiGetById: "/api/campi/{id}",
    CampiCreate: "/api/campi",
    CampiUpdate: "/api/campi/{id}",
    CampiDelete: "/api/campi/{id}",
    PrenotazioniSlotDisponibili: "/api/prenotazioni/slot-disponibili?idCampo={id}&data={data}",
    PrenotazioniCreate: "/api/prenotazioni",
    PrenotazioniCancel: "/api/prenotazioni/{id}",
    PrenotazioniProssima: "/api/prenotazioni/prossima?telefono=",
    PrenotazioniByUtente: "/api/prenotazioni/utente/{idUtente}",
    PartiteDettaglio: "/api/partite/{id}",
    PartitePubbliche: "/api/partite/pubbliche",
    PartiteEntra: "/api/partite/{id}/entra",
    PartiteElimina: "/api/partite/{id}",
    PartiteEsci: "/api/partite/{id}/esci",
    PartiteStorico: "/api/partite/storico",
    PartiteInvitabili: "/api/partite/{id}/invitabili?cerca={cerca}",
    PartiteInvita: "/api/partite/{id}/inviti",
    PartiteInviti: "/api/partite/inviti",
    PartiteConferma: "/api/partite/{id}/conferma",
    PartiteRisultato: "/api/partite/{id}/risultato",
    Classifica: "/api/classifica",
  );
}

SlotOrario slotDiTest()
{
  return SlotOrario(idCampo: 3, oraInizio: "18:30:00", oraFine: "20:00:00", disponibile: true, nomeCampo: "Campo Centrale");
}

Prenotazione prenotazioneDiTest({String tipo = "PUBBLICA"})
{
  return Prenotazione(
    id: 10,
    idCampo: 3,
    telefonoGiocatore1: "3331234567",
    telefonoGiocatore2: null,
    telefonoGiocatore3: null,
    telefonoGiocatore4: null,
    dataPrenotazione: DateTime(2026, 11, 2),
    oraInizio: const TimeOfDay(hour: 18, minute: 30),
    oraFine: const TimeOfDay(hour: 20, minute: 0),
    stato: "CONFERMATA",
    tipo: tipo,
  );
}

//repository finto: estende quello vero (lo use case dipende dalla classe concreta)
//ma non passa mai dal data source, restituisce la risposta o lancia l'errore impostati dal test
class FakePrenotazioneRepo extends PrenotazioneRepoImpl
{
  //attributi
  Prenotazione? risposta;
  Exception? errore;
  Completer<Prenotazione>? attesa; //se impostato la chiamata resta in sospeso finche il test non la completa

  int chiamate = 0;
  int? idCampoRicevuto;
  DateTime? dataRicevuta;
  String? oraInizioRicevuta;
  String? tipoRicevuto;

  //prossima partita: null vuol dire nessuna partita in programma
  Prenotazione? prossima;
  Exception? erroreProssima;
  int chiamateProssima = 0;

  //metodi
  FakePrenotazioneRepo() : super(dsPrenotazione: DataSourcePrenotazione(c: Client(c: MockClient((_) async => http.Response('', 500))), elencoUrl: urlDiTest()));

  @override
  Future<Prenotazione> creaPartita(int idCampo, DateTime data, String oraInizio, String tipo) async
  {
    chiamate++;
    idCampoRicevuto = idCampo;
    dataRicevuta = data;
    oraInizioRicevuta = oraInizio;
    tipoRicevuto = tipo;

    if(attesa != null)
    {
      return attesa!.future;
    }
    if(errore != null)
    {
      throw errore!;
    }
    return risposta ?? prenotazioneDiTest(tipo: tipo);
  }

  @override
  Future<Prenotazione?> getProssimaPartita() async
  {
    chiamateProssima++;

    if(erroreProssima != null)
    {
      throw erroreProssima!;
    }
    return prossima;
  }
}
