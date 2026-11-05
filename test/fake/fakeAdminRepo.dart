import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:thepadel/core/network/client.dart';
import 'package:thepadel/dataLayer/dataSource/dataSourceAdmin.dart';
import 'package:thepadel/domainLayer/enetity/avvisoAdmin.dart';
import 'package:thepadel/domainLayer/enetity/dettaglioPartita.dart';
import 'package:thepadel/domainLayer/enetity/partitaAdmin.dart';
import 'package:thepadel/domainLayer/enetity/partiteCampoAdmin.dart';
import 'package:thepadel/domainLayer/enetity/setPartita.dart';
import 'package:thepadel/domainLayer/enetity/utenteAdmin.dart';
import 'package:thepadel/repositoryImpl/adminRepoImpl.dart';

import 'fakePartitaRepo.dart';
import 'fakePrenotazioneRepo.dart';

PartitaAdmin partitaAdminDiTest({int id = 7, String stato = "creata", List<String> giocatori = const ["Mario Rossi", "Giocatore del campo"], int postiLiberi = 2, List<SetPartita>? risultato})
{
  return PartitaAdmin(
    id: id,
    oraInizio: const TimeOfDay(hour: 18, minute: 30),
    oraFine: const TimeOfDay(hour: 20, minute: 0),
    stato: stato,
    tipo: "PUBBLICA",
    giocatori: giocatori,
    postiLiberi: postiLiberi,
    risultato: risultato,
  );
}

PartiteCampoAdmin campoAdminDiTest({int idCampo = 1, String nomeCampo = "Campo Centrale", List<PartitaAdmin>? partite})
{
  return PartiteCampoAdmin(idCampo: idCampo, nomeCampo: nomeCampo, partite: partite ?? [partitaAdminDiTest()]);
}

AvvisoAdmin avvisoDiTest({int id = 1, int idPartita = 7, String nomeCampo = "Campo Centrale", int postiLiberi = 2})
{
  return AvvisoAdmin(
    id: id,
    idPartita: idPartita,
    nomeCampo: nomeCampo,
    dataPartita: DateTime(2026, 11, 5),
    oraInizio: const TimeOfDay(hour: 18, minute: 30),
    oraFine: const TimeOfDay(hour: 20, minute: 0),
    postiLiberi: postiLiberi,
  );
}

UtenteAdmin utenteAdminDiTest({String telefono = "3335550001", String nome = "Luca", String cognome = "Bianchi", double livello = 2.5, int punteggio = 12})
{
  return UtenteAdmin(telefono: telefono, nome: nome, cognome: cognome, livello: livello, punteggio: punteggio);
}

//repository finto: estende quello vero (lo use case dipende dalla classe concreta)
//ma non passa mai dal data source, restituisce la risposta o lancia l'errore impostati dal test
class FakeAdminRepo extends AdminRepoImpl
{
  //attributi

  //partite del giorno
  List<PartiteCampoAdmin> campi = [];
  Exception? errorePartite;
  Completer<void>? attesaPartite; //se impostato la chiamata resta in sospeso finche il test non la completa
  List<DateTime> dateRicevute = [];

  //avvisi
  List<AvvisoAdmin> avvisi = [];
  Exception? erroreAvvisi;
  Completer<void>? attesaAvvisi;
  int chiamateAvvisi = 0;

  //utenti
  List<UtenteAdmin> utenti = [];
  Exception? erroreUtenti;
  List<String> cercaRicevuti = [];

  //livello: se rispostaLivello e null restituisce l'utente col livello ricevuto
  UtenteAdmin? rispostaLivello;
  Exception? erroreLivello;
  Completer<void>? attesaLivello;
  int chiamateLivello = 0;
  String? telefonoLivelloRicevuto;
  double? livelloRicevuto;

  //le quattro operazioni sulla partita: se la risposta e null restituiscono dettaglioDiTest con lo stesso id
  DettaglioPartita? rispostaPartecipanti;
  Exception? errorePartecipanti;
  Completer<void>? attesaPartecipanti;
  int chiamatePartecipanti = 0;
  int? idPartecipantiRicevuto;
  List<String>? telefoniRicevuti;

  DettaglioPartita? rispostaRisultato;
  Exception? erroreRisultato;
  int chiamateRisultato = 0;
  int? idRisultatoRicevuto;
  List<int>? squadra1Ricevuta;
  List<int>? squadra2Ricevuta;
  List<SetPartita>? setRicevuti;

  DettaglioPartita? rispostaStato;
  Exception? erroreStato;
  Completer<void>? attesaStato;
  int chiamateStato = 0;
  int? idStatoRicevuto;
  String? statoRicevuto;

  DettaglioPartita? rispostaAnnulla;
  Exception? erroreAnnulla;
  int chiamateAnnulla = 0;
  int? idAnnullaRicevuto;

  //livello dei giocatori del campo
  double livelloCampo = 2.0;
  Exception? erroreLivelloCampo; //lettura
  Exception? erroreSalvaLivelloCampo;
  Completer<void>? attesaSalvaLivelloCampo;
  int chiamateLivelloCampo = 0;
  List<double> livelliCampoRicevuti = [];

  //giocatori del campo: se la risposta e null restituiscono dettaglioDiTest con lo stesso id
  DettaglioPartita? rispostaGiocatoriCampo;
  Exception? erroreGiocatoriCampo;
  int? idGiocatoriCampoRicevuto;
  int? numeroRicevuto;

  DettaglioPartita? rispostaRimuoviCampo;
  Exception? erroreRimuoviCampo;
  int? idRimuoviCampoRicevuto;
  int? idPostoRicevuto;

  //partita creata dall'admin: se la risposta e null restituisce dettaglioDiTest
  DettaglioPartita? rispostaCreaPartita;
  Exception? erroreCreaPartita;
  Completer<void>? attesaCreaPartita;
  int chiamateCreaPartita = 0;
  int? idCampoCreaRicevuto;
  DateTime? dataCreaRicevuta;
  String? oraCreaRicevuta;
  String? tipoCreaRicevuto;
  List<String>? telefoniCreaRicevuti;
  int? giocatoriCampoCreaRicevuti;

  //metodi
  FakeAdminRepo() : super(dsAdmin: DataSourceAdmin(c: Client(c: MockClient((_) async => http.Response('', 500))), elencoUrl: urlDiTest()));

  @override
  Future<List<PartiteCampoAdmin>> getPartiteDelGiorno(DateTime data) async
  {
    dateRicevute.add(data);

    if(attesaPartite != null)
    {
      await attesaPartite!.future;
    }
    if(errorePartite != null)
    {
      throw errorePartite!;
    }
    return campi;
  }

  @override
  Future<List<AvvisoAdmin>> getAvvisi() async
  {
    chiamateAvvisi++;

    if(attesaAvvisi != null)
    {
      await attesaAvvisi!.future;
    }
    if(erroreAvvisi != null)
    {
      throw erroreAvvisi!;
    }
    return avvisi;
  }

  @override
  Future<List<UtenteAdmin>> getUtenti(String cerca) async
  {
    cercaRicevuti.add(cerca);

    if(erroreUtenti != null)
    {
      throw erroreUtenti!;
    }
    return utenti;
  }

  @override
  Future<UtenteAdmin> cambiaLivello(String telefono, double livello) async
  {
    chiamateLivello++;
    telefonoLivelloRicevuto = telefono;
    livelloRicevuto = livello;

    if(attesaLivello != null)
    {
      await attesaLivello!.future;
    }
    if(erroreLivello != null)
    {
      throw erroreLivello!;
    }
    return rispostaLivello ?? utenteAdminDiTest(telefono: telefono, livello: livello);
  }

  @override
  Future<DettaglioPartita> modificaPartecipanti(int idPartita, List<String> telefoni) async
  {
    chiamatePartecipanti++;
    idPartecipantiRicevuto = idPartita;
    telefoniRicevuti = telefoni;

    if(attesaPartecipanti != null)
    {
      await attesaPartecipanti!.future;
    }
    if(errorePartecipanti != null)
    {
      throw errorePartecipanti!;
    }
    return rispostaPartecipanti ?? dettaglioDiTest(id: idPartita);
  }

  @override
  Future<DettaglioPartita> modificaRisultato(int idPartita, List<int> squadra1, List<int> squadra2, List<SetPartita> set) async
  {
    chiamateRisultato++;
    idRisultatoRicevuto = idPartita;
    squadra1Ricevuta = squadra1;
    squadra2Ricevuta = squadra2;
    setRicevuti = set;

    if(erroreRisultato != null)
    {
      throw erroreRisultato!;
    }
    return rispostaRisultato ?? dettaglioDiTest(id: idPartita);
  }

  @override
  Future<DettaglioPartita> modificaStato(int idPartita, String stato) async
  {
    chiamateStato++;
    idStatoRicevuto = idPartita;
    statoRicevuto = stato;

    if(attesaStato != null)
    {
      await attesaStato!.future;
    }
    if(erroreStato != null)
    {
      throw erroreStato!;
    }
    return rispostaStato ?? dettaglioDiTest(id: idPartita, stato: stato);
  }

  @override
  Future<DettaglioPartita> annullaPartita(int idPartita) async
  {
    chiamateAnnulla++;
    idAnnullaRicevuto = idPartita;

    if(erroreAnnulla != null)
    {
      throw erroreAnnulla!;
    }
    return rispostaAnnulla ?? dettaglioDiTest(id: idPartita, stato: "annullata");
  }

  @override
  Future<double> getLivelloGiocatoriCampo() async
  {
    chiamateLivelloCampo++;

    if(erroreLivelloCampo != null)
    {
      throw erroreLivelloCampo!;
    }
    return livelloCampo;
  }

  @override
  Future<double> setLivelloGiocatoriCampo(double livello) async
  {
    livelliCampoRicevuti.add(livello);

    if(attesaSalvaLivelloCampo != null)
    {
      await attesaSalvaLivelloCampo!.future;
    }
    if(erroreSalvaLivelloCampo != null)
    {
      throw erroreSalvaLivelloCampo!;
    }
    livelloCampo = livello;
    return livello;
  }

  @override
  Future<DettaglioPartita> aggiungiGiocatoriCampo(int idPartita, int numero) async
  {
    idGiocatoriCampoRicevuto = idPartita;
    numeroRicevuto = numero;

    if(erroreGiocatoriCampo != null)
    {
      throw erroreGiocatoriCampo!;
    }
    return rispostaGiocatoriCampo ?? dettaglioDiTest(id: idPartita);
  }

  @override
  Future<DettaglioPartita> rimuoviGiocatoreCampo(int idPartita, int idPosto) async
  {
    idRimuoviCampoRicevuto = idPartita;
    idPostoRicevuto = idPosto;

    if(erroreRimuoviCampo != null)
    {
      throw erroreRimuoviCampo!;
    }
    return rispostaRimuoviCampo ?? dettaglioDiTest(id: idPartita);
  }

  @override
  Future<DettaglioPartita> creaPartitaAdmin(int idCampo, DateTime data, String oraInizio, String tipo, List<String> telefoni, int giocatoriCampo) async
  {
    chiamateCreaPartita++;
    idCampoCreaRicevuto = idCampo;
    dataCreaRicevuta = data;
    oraCreaRicevuta = oraInizio;
    tipoCreaRicevuto = tipo;
    telefoniCreaRicevuti = telefoni;
    giocatoriCampoCreaRicevuti = giocatoriCampo;

    if(attesaCreaPartita != null)
    {
      await attesaCreaPartita!.future;
    }
    if(erroreCreaPartita != null)
    {
      throw erroreCreaPartita!;
    }
    return rispostaCreaPartita ?? dettaglioDiTest();
  }
}
