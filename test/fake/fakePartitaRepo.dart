import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:thepadel/core/network/client.dart';
import 'package:thepadel/dataLayer/dataSource/dataSourcePartita.dart';
import 'package:thepadel/domainLayer/enetity/azioniPartita.dart';
import 'package:thepadel/domainLayer/enetity/dettaglioPartita.dart';
import 'package:thepadel/domainLayer/enetity/partitaPubblica.dart';
import 'package:thepadel/domainLayer/enetity/partitaStorico.dart';
import 'package:thepadel/domainLayer/enetity/postoPartita.dart';
import 'package:thepadel/domainLayer/enetity/risultatoPartita.dart';
import 'package:thepadel/domainLayer/enetity/setPartita.dart';
import 'package:thepadel/repositoryImpl/partitaRepoImpl.dart';

import 'fakePrenotazioneRepo.dart';

AzioniPartita azioniDiTest({bool puoInvitare = false, bool puoEliminare = false, bool puoUscire = false, bool puoConfermare = false, bool puoRegistrareRisultato = false})
{
  return AzioniPartita(puoInvitare: puoInvitare, puoEliminare: puoEliminare, puoUscire: puoUscire, puoConfermare: puoConfermare, puoRegistrareRisultato: puoRegistrareRisultato);
}

//partita con il creatore (Mario Rossi) e un giocatore del campo: restano 2 posti liberi
DettaglioPartita dettaglioDiTest({AzioniPartita? azioni, List<PostoPartita>? posti})
{
  return DettaglioPartita(
    id: 10,
    idCampo: 3,
    nomeCampo: "Campo Centrale",
    dataPartita: DateTime(2026, 11, 2),
    oraInizio: const TimeOfDay(hour: 18, minute: 30),
    oraFine: const TimeOfDay(hour: 20, minute: 0),
    stato: "creata",
    tipo: "PUBBLICA",
    telefonoCreatore: "3331234567",
    posti: posti ?? [
      PostoPartita(tipo: "UTENTE", telefono: "3331234567", nome: "Mario", cognome: "Rossi", livello: 2.5, confermata: false),
      PostoPartita(tipo: "CAMPO", telefono: null, nome: null, cognome: null, livello: null, confermata: false),
    ],
    azioni: azioni ?? azioniDiTest(puoInvitare: true, puoEliminare: true),
  );
}

//partita della bacheca pubbliche: di default e quella di dettaglioDiTest vista dalla bacheca
PartitaPubblica partitaPubblicaDiTest({int id = 10, String nomeCampo = "Campo Centrale", int postiLiberi = 2})
{
  return PartitaPubblica(
    id: id,
    idCampo: 3,
    nomeCampo: nomeCampo,
    dataPartita: DateTime(2026, 11, 2),
    oraInizio: const TimeOfDay(hour: 18, minute: 30),
    oraFine: const TimeOfDay(hour: 20, minute: 0),
    nomeCreatore: "Mario",
    cognomeCreatore: "Rossi",
    livelloCreatore: 2.5,
    postiLiberi: postiLiberi,
  );
}

//partita dello storico: di default e quella di dettaglioDiTest, ancora senza risultato
PartitaStorico partitaStoricoDiTest({int id = 10, String nomeCampo = "Campo Centrale", String stato = "creata", RisultatoPartita? risultato})
{
  return PartitaStorico(
    id: id,
    idCampo: 3,
    nomeCampo: nomeCampo,
    dataPartita: DateTime(2026, 11, 2),
    oraInizio: const TimeOfDay(hour: 18, minute: 30),
    oraFine: const TimeOfDay(hour: 20, minute: 0),
    stato: stato,
    tipo: "PUBBLICA",
    risultato: risultato,
  );
}

//risultato 6-4 3-6 6-2 visto dalla squadra 1
RisultatoPartita risultatoDiTest({int? squadraUtente = 1, String? esito = "VINTA", int? puntiAssegnati = 12})
{
  return RisultatoPartita(
    set: [
      SetPartita(squadra1: 6, squadra2: 4),
      SetPartita(squadra1: 3, squadra2: 6),
      SetPartita(squadra1: 6, squadra2: 2),
    ],
    squadraUtente: squadraUtente,
    esito: esito,
    puntiAssegnati: puntiAssegnati,
  );
}

//repository finto: estende quello vero (lo use case dipende dalla classe concreta)
//ma non passa mai dal data source, restituisce la risposta o lancia l'errore impostati dal test
class FakePartitaRepo extends PartitaRepoImpl
{
  //attributi
  DettaglioPartita? risposta;
  Exception? errore;
  Completer<DettaglioPartita>? attesa; //se impostato la chiamata resta in sospeso finche il test non la completa

  int chiamate = 0;
  int? idRicevuto;

  //bacheca pubbliche: se partitePubbliche e null restituisce una sola partita di test
  List<PartitaPubblica>? partitePubbliche;
  Exception? errorePubbliche;
  int chiamatePubbliche = 0;

  //ingresso in partita
  DettaglioPartita? rispostaEntra;
  Exception? erroreEntra;
  Completer<DettaglioPartita>? attesaEntra;
  int chiamateEntra = 0;
  int? idEntraRicevuto;

  //eliminazione e uscita: se l'errore e null l'operazione riesce
  Exception? erroreElimina;
  Completer<void>? attesaElimina;
  int chiamateElimina = 0;
  int? idEliminaRicevuto;

  Exception? erroreEsci;
  Completer<void>? attesaEsci;
  int chiamateEsci = 0;
  int? idEsciRicevuto;

  //storico: se partiteStorico e null restituisce una sola partita di test
  List<PartitaStorico>? partiteStorico;
  Exception? erroreStorico;
  int chiamateStorico = 0;

  //metodi
  FakePartitaRepo() : super(dsPartita: DataSourcePartita(c: Client(c: MockClient((_) async => http.Response('', 500))), elencoUrl: urlDiTest()));

  @override
  Future<DettaglioPartita> getDettaglioPartita(int idPartita) async
  {
    chiamate++;
    idRicevuto = idPartita;

    if(attesa != null)
    {
      return attesa!.future;
    }
    if(errore != null)
    {
      throw errore!;
    }
    return risposta ?? dettaglioDiTest();
  }

  @override
  Future<List<PartitaPubblica>> getPartitePubbliche() async
  {
    chiamatePubbliche++;

    if(errorePubbliche != null)
    {
      throw errorePubbliche!;
    }
    return partitePubbliche ?? [partitaPubblicaDiTest()];
  }

  @override
  Future<DettaglioPartita> entraInPartita(int idPartita) async
  {
    chiamateEntra++;
    idEntraRicevuto = idPartita;

    if(attesaEntra != null)
    {
      return attesaEntra!.future;
    }
    if(erroreEntra != null)
    {
      throw erroreEntra!;
    }
    return rispostaEntra ?? dettaglioDiTest();
  }

  @override
  Future<void> eliminaPartita(int idPartita) async
  {
    chiamateElimina++;
    idEliminaRicevuto = idPartita;

    if(attesaElimina != null)
    {
      return attesaElimina!.future;
    }
    if(erroreElimina != null)
    {
      throw erroreElimina!;
    }
  }

  @override
  Future<void> esciDaPartita(int idPartita) async
  {
    chiamateEsci++;
    idEsciRicevuto = idPartita;

    if(attesaEsci != null)
    {
      return attesaEsci!.future;
    }
    if(erroreEsci != null)
    {
      throw erroreEsci!;
    }
  }

  @override
  Future<List<PartitaStorico>> getStorico() async
  {
    chiamateStorico++;

    if(erroreStorico != null)
    {
      throw erroreStorico!;
    }
    return partiteStorico ?? [partitaStoricoDiTest()];
  }
}
