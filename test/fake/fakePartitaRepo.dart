import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:thepadel/core/network/client.dart';
import 'package:thepadel/dataLayer/dataSource/dataSourcePartita.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/domainLayer/enetity/azioniPartita.dart';
import 'package:thepadel/domainLayer/enetity/dettaglioPartita.dart';
import 'package:thepadel/domainLayer/enetity/partitaInvito.dart';
import 'package:thepadel/domainLayer/enetity/partitaPubblica.dart';
import 'package:thepadel/domainLayer/enetity/partitaStorico.dart';
import 'package:thepadel/domainLayer/enetity/postoPartita.dart';
import 'package:thepadel/domainLayer/enetity/risultatoPartita.dart';
import 'package:thepadel/domainLayer/enetity/setPartita.dart';
import 'package:thepadel/domainLayer/enetity/utenteInvitabile.dart';
import 'package:thepadel/repositoryImpl/partitaRepoImpl.dart';

import 'fakePrenotazioneRepo.dart';

AzioniPartita azioniDiTest({bool puoInvitare = false, bool puoEliminare = false, bool puoUscire = false, bool puoConfermare = false, bool puoRegistrareRisultato = false, bool puoCambiareTipo = false})
{
  return AzioniPartita(puoInvitare: puoInvitare, puoEliminare: puoEliminare, puoUscire: puoUscire, puoConfermare: puoConfermare, puoRegistrareRisultato: puoRegistrareRisultato, puoCambiareTipo: puoCambiareTipo);
}

//partita con il creatore (Mario Rossi) e un giocatore del campo: restano 2 posti liberi
//telefonoCreatore: null esplicito simula un creatore che ha eliminato l'account
DettaglioPartita dettaglioDiTest({AzioniPartita? azioni, List<PostoPartita>? posti, String stato = "creata", RisultatoPartita? risultato, int id = 10, DateTime? dataPartita, String? telefonoCreatore = "3331234567", String tipo = "PUBBLICA", TimeOfDay oraInizio = const TimeOfDay(hour: 18, minute: 30), TimeOfDay oraFine = const TimeOfDay(hour: 20, minute: 0)})
{
  return DettaglioPartita(
    id: id,
    idCampo: 3,
    nomeCampo: "Campo Centrale",
    dataPartita: dataPartita ?? DateTime(2026, 11, 2),
    oraInizio: oraInizio,
    oraFine: oraFine,
    stato: stato,
    tipo: tipo,
    telefonoCreatore: telefonoCreatore,
    posti: posti ?? [
      PostoPartita(idPosto: null, tipo: "UTENTE", telefono: "3331234567", nome: "Mario", cognome: "Rossi", livello: 2.5, confermata: false, squadra: null),
      PostoPartita(idPosto: null, tipo: "CAMPO", telefono: null, nome: null, cognome: null, livello: null, confermata: false, squadra: null),
    ],
    azioni: azioni ?? azioniDiTest(puoInvitare: true, puoEliminare: true),
    risultato: risultato,
  );
}

//i 4 posti di una partita pronta per il risultato: idPosto da 11 a 14, l'ultimo e un giocatore del campo.
//con conSquadre il risultato e gia registrato: i primi due in squadra 1, gli altri in squadra 2
List<PostoPartita> quattroPostiDiTest({bool conSquadre = false})
{
  return [
    PostoPartita(idPosto: 11, tipo: "UTENTE", telefono: "3331234567", nome: "Mario", cognome: "Rossi", livello: 2.5, confermata: true, squadra: conSquadre ? 1 : null),
    PostoPartita(idPosto: 12, tipo: "UTENTE", telefono: "3335550001", nome: "Luca", cognome: "Bianchi", livello: 3.0, confermata: true, squadra: conSquadre ? 1 : null),
    PostoPartita(idPosto: 13, tipo: "UTENTE", telefono: "3335550002", nome: "Anna", cognome: "Verdi", livello: 2.5, confermata: true, squadra: conSquadre ? 2 : null),
    PostoPartita(idPosto: 14, tipo: "CAMPO", telefono: null, nome: null, cognome: null, livello: null, confermata: false, squadra: conSquadre ? 2 : null),
  ];
}

//partita della bacheca pubbliche: di default e quella di dettaglioDiTest vista dalla bacheca
//nomeCreatore e cognomeCreatore null espliciti: il creatore ha eliminato l'account
PartitaPubblica partitaPubblicaDiTest({int id = 10, String nomeCampo = "Campo Centrale", int postiLiberi = 2, double? livelloCreatore = 2.5, String? nomeCreatore = "Mario", String? cognomeCreatore = "Rossi"})
{
  return PartitaPubblica(
    id: id,
    idCampo: 3,
    nomeCampo: nomeCampo,
    dataPartita: DateTime(2026, 11, 2),
    oraInizio: const TimeOfDay(hour: 18, minute: 30),
    oraFine: const TimeOfDay(hour: 20, minute: 0),
    nomeCreatore: nomeCreatore,
    cognomeCreatore: cognomeCreatore,
    livelloCreatore: livelloCreatore,
    postiLiberi: postiLiberi,
  );
}

//partita dello storico: di default e quella di dettaglioDiTest, ancora senza risultato
PartitaStorico partitaStoricoDiTest({int id = 10, int idCampo = 3, String nomeCampo = "Campo Centrale", String stato = "creata", RisultatoPartita? risultato, DateTime? dataPartita, TimeOfDay oraInizio = const TimeOfDay(hour: 18, minute: 30), TimeOfDay oraFine = const TimeOfDay(hour: 20, minute: 0)})
{
  return PartitaStorico(
    id: id,
    idCampo: idCampo,
    nomeCampo: nomeCampo,
    dataPartita: dataPartita ?? DateTime(2026, 11, 2),
    oraInizio: oraInizio,
    oraFine: oraFine,
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

UtenteInvitabile utenteInvitabileDiTest({String telefono = "3335550001", String nome = "Luca", String cognome = "Bianchi", double livello = 3.0})
{
  return UtenteInvitabile(telefono: telefono, nome: nome, cognome: cognome, livello: livello);
}

//partita della bacheca inviti: di default e quella di dettaglioDiTest, creata da Mario Rossi
PartitaInvito partitaInvitoDiTest({int id = 10, String nomeCampo = "Campo Centrale", String stato = "creata", String tipo = "PRIVATA", String? nomeCreatore = "Mario", String? cognomeCreatore = "Rossi"})
{
  return PartitaInvito(
    id: id,
    idCampo: 3,
    nomeCampo: nomeCampo,
    dataPartita: DateTime(2026, 11, 2),
    oraInizio: const TimeOfDay(hour: 18, minute: 30),
    oraFine: const TimeOfDay(hour: 20, minute: 0),
    stato: stato,
    tipo: tipo,
    nomeCreatore: nomeCreatore,
    cognomeCreatore: cognomeCreatore,
  );
}

//dettaglio con il creatore e tanti invitati quanti indicati: serve per avere i posti liberi voluti (4 - 1 - invitati)
DettaglioPartita dettaglioConInvitati(int invitati)
{
  final posti = <PostoPartita>[
    PostoPartita(idPosto: null, tipo: "UTENTE", telefono: "3331234567", nome: "Mario", cognome: "Rossi", livello: 2.5, confermata: false, squadra: null),
  ];
  for (int i = 0; i < invitati; i++)
  {
    posti.add(PostoPartita(idPosto: null, tipo: "UTENTE", telefono: "333555000$i", nome: "Invitato", cognome: "$i", livello: 3.0, confermata: false, squadra: null));
  }
  return dettaglioDiTest(posti: posti);
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

  //il telefono dell'utente loggato, uguale a quello del creatore di dettaglioDiTest
  String telefonoUtente = "3331234567";

  //dettagli diversi per partita, usati quando una lista legge il dettaglio di ogni voce
  Map<int, DettaglioPartita> dettagliPerId = {};
  Set<int> dettagliInErrore = {};

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

  //le mie partite: se partiteMie e null restituisce una sola partita di test
  List<PartitaStorico>? partiteMie;
  Exception? erroreMie;
  int chiamateMie = 0;

  //utenti invitabili mentre si prenota: se utentiInvitabili e null restituisce due utenti di test
  List<UtenteInvitabile>? utentiInvitabili;
  Exception? erroreUtentiInvitabili;
  int chiamateUtentiInvitabili = 0;
  List<String> cercaUtentiRicevuti = [];

  //cambio di visibilita: se rispostaCambiaTipo e null restituisce dettaglioDiTest
  DettaglioPartita? rispostaCambiaTipo;
  Exception? erroreCambiaTipo;
  Completer<DettaglioPartita>? attesaCambiaTipo;
  int chiamateCambiaTipo = 0;
  int? idCambiaTipoRicevuto;
  String? tipoRicevuto;

  //utenti invitabili: se invitabili e null restituisce due utenti di test
  List<UtenteInvitabile>? invitabili;
  Exception? erroreInvitabili;
  int chiamateInvitabili = 0;
  int? idInvitabiliRicevuto;
  List<String> cercaRicevuti = [];

  //invito: se rispostaInvita e null restituisce dettaglioDiTest
  DettaglioPartita? rispostaInvita;
  Exception? erroreInvita;
  Completer<DettaglioPartita>? attesaInvita;
  int chiamateInvita = 0;
  int? idInvitaRicevuto;
  String? telefonoInvitaRicevuto;

  //bacheca inviti: se partiteInviti e null restituisce una sola partita di test
  List<PartitaInvito>? partiteInviti;
  Exception? erroreInviti;
  int chiamateInviti = 0;

  //conferma: se rispostaConferma e null restituisce dettaglioDiTest
  DettaglioPartita? rispostaConferma;
  Exception? erroreConferma;
  Completer<DettaglioPartita>? attesaConferma;
  int chiamateConferma = 0;
  int? idConfermaRicevuto;

  //risultato: se rispostaRisultato e null restituisce dettaglioDiTest
  DettaglioPartita? rispostaRisultato;
  Exception? erroreRisultato;
  Completer<DettaglioPartita>? attesaRisultato;
  int chiamateRisultato = 0;
  int? idRisultatoRicevuto;
  List<int>? squadra1Ricevuta;
  List<int>? squadra2Ricevuta;
  List<SetPartita>? setRicevuti;

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
    if(dettagliInErrore.contains(idPartita))
    {
      throw ErroreGenericoServer();
    }
    return dettagliPerId[idPartita] ?? risposta ?? dettaglioDiTest();
  }

  @override
  String getTelefonoUtente()
  {
    return telefonoUtente;
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

  @override
  Future<List<PartitaStorico>> getMiePartite() async
  {
    chiamateMie++;

    if(erroreMie != null)
    {
      throw erroreMie!;
    }
    return partiteMie ?? [partitaStoricoDiTest()];
  }

  @override
  Future<List<UtenteInvitabile>> getUtentiInvitabili(String cerca) async
  {
    chiamateUtentiInvitabili++;
    cercaUtentiRicevuti.add(cerca);

    if(erroreUtentiInvitabili != null)
    {
      throw erroreUtentiInvitabili!;
    }
    return utentiInvitabili ?? [utenteInvitabileDiTest(), utenteInvitabileDiTest(telefono: "3335550002", nome: "Anna", cognome: "Verdi", livello: 2.5)];
  }

  @override
  Future<DettaglioPartita> cambiaTipoPartita(int idPartita, String tipo) async
  {
    chiamateCambiaTipo++;
    idCambiaTipoRicevuto = idPartita;
    tipoRicevuto = tipo;

    if(attesaCambiaTipo != null)
    {
      return attesaCambiaTipo!.future;
    }
    if(erroreCambiaTipo != null)
    {
      throw erroreCambiaTipo!;
    }
    return rispostaCambiaTipo ?? dettaglioDiTest();
  }

  @override
  Future<List<UtenteInvitabile>> getInvitabili(int idPartita, String cerca) async
  {
    chiamateInvitabili++;
    idInvitabiliRicevuto = idPartita;
    cercaRicevuti.add(cerca);

    if(erroreInvitabili != null)
    {
      throw erroreInvitabili!;
    }
    return invitabili ?? [utenteInvitabileDiTest(), utenteInvitabileDiTest(telefono: "3335550002", nome: "Anna", cognome: "Verdi", livello: 2.5)];
  }

  @override
  Future<DettaglioPartita> invitaUtente(int idPartita, String telefono) async
  {
    chiamateInvita++;
    idInvitaRicevuto = idPartita;
    telefonoInvitaRicevuto = telefono;

    if(attesaInvita != null)
    {
      return attesaInvita!.future;
    }
    if(erroreInvita != null)
    {
      throw erroreInvita!;
    }
    return rispostaInvita ?? dettaglioDiTest();
  }

  @override
  Future<List<PartitaInvito>> getInviti() async
  {
    chiamateInviti++;

    if(erroreInviti != null)
    {
      throw erroreInviti!;
    }
    return partiteInviti ?? [partitaInvitoDiTest()];
  }

  @override
  Future<DettaglioPartita> confermaPartita(int idPartita) async
  {
    chiamateConferma++;
    idConfermaRicevuto = idPartita;

    if(attesaConferma != null)
    {
      return attesaConferma!.future;
    }
    if(erroreConferma != null)
    {
      throw erroreConferma!;
    }
    return rispostaConferma ?? dettaglioDiTest();
  }

  @override
  Future<DettaglioPartita> registraRisultato(int idPartita, List<int> squadra1, List<int> squadra2, List<SetPartita> set) async
  {
    chiamateRisultato++;
    idRisultatoRicevuto = idPartita;
    squadra1Ricevuta = squadra1;
    squadra2Ricevuta = squadra2;
    setRicevuti = set;

    if(attesaRisultato != null)
    {
      return attesaRisultato!.future;
    }
    if(erroreRisultato != null)
    {
      throw erroreRisultato!;
    }
    return rispostaRisultato ?? dettaglioDiTest();
  }
}
