import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:thepadel/bloc/dettaglioAdmin/dettaglioAdminBloc.dart';
import 'package:thepadel/bloc/dettaglioAdmin/dettaglioAdminEvent.dart';
import 'package:thepadel/bloc/dettaglioAdmin/dettaglioAdminState.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/domainLayer/enetity/setPartita.dart';
import 'package:thepadel/useCase/adminUseCase.dart';
import 'package:thepadel/useCase/dettaglioPartitaUseCase.dart';
import 'package:thepadel/useCase/eccezioniUseCase.dart';

import '../../fake/fakeAdminRepo.dart';
import '../../fake/fakePartitaRepo.dart';

final List<SetPartita> setValidi = [SetPartita(squadra1: 6, squadra2: 4), SetPartita(squadra1: 6, squadra2: 2)];

void main()
{
  late FakeAdminRepo repoAdmin;
  late FakePartitaRepo repoPartita;
  late DettaglioAdminBloc bloc;

  setUp(()
  {
    repoAdmin = FakeAdminRepo();
    repoPartita = FakePartitaRepo();
    repoPartita.risposta = dettaglioDiTest(id: 7, stato: "creata");
    bloc = DettaglioAdminBloc(
      dettaglioPartitaUseCase: DettaglioPartitaUseCase(repo: repoPartita),
      modificaPartecipantiUseCase: ModificaPartecipantiUseCase(repo: repoAdmin),
      modificaRisultatoUseCase: ModificaRisultatoUseCase(repo: repoAdmin),
      modificaStatoUseCase: ModificaStatoUseCase(repo: repoAdmin),
      annullaPartitaUseCase: AnnullaPartitaUseCase(repo: repoAdmin),
      aggiungiGiocatoriCampoUseCase: AggiungiGiocatoriCampoUseCase(repo: repoAdmin),
      rimuoviGiocatoreCampoUseCase: RimuoviGiocatoreCampoUseCase(repo: repoAdmin),
    );
  });

  tearDown(() async
  {
    await bloc.close();
  });

  Future<void> caricaDettaglio() async
  {
    bloc.add(const DettaglioAdminRichiesto(id: 7));
    await expectLater(bloc.stream, emitsInOrder([isA<DettaglioAdminLoading>(), isA<DettaglioAdminCaricato>()]));
  }

  test("lo stato iniziale e DettaglioAdminInitial", ()
  {
    expect(bloc.state, isA<DettaglioAdminInitial>());
    expect(bloc.dettaglio, isNull);
  });

  group("caricamento", ()
  {
    test("ok: Loading poi Caricato e il dettaglio resta nel bloc", () async
    {
      bloc.add(const DettaglioAdminRichiesto(id: 7));

      await expectLater(bloc.stream, emitsInOrder([
        isA<DettaglioAdminLoading>(),
        isA<DettaglioAdminCaricato>().having((s) => s.dettaglio.id, "id", 7),
      ]));
      expect(repoPartita.idRicevuto, 7);
      expect(bloc.dettaglio!.id, 7);
    });

    final errori = <String, Exception Function()>{
      "404": () => PartitaNonTrovata(messaggio: "Partita non trovata"),
      "generico": () => ErroreGenericoServer(),
      "timeout": () => Exception("timeout"),
    };
    final messaggi = {"404": "Partita non trovata", "generico": ErroreGenericoServer().messaggio, "timeout": ErroreGenericoServer().messaggio};
    errori.forEach((nome, errore)
    {
      test("errore $nome: Loading poi Errore col messaggio", () async
      {
        repoPartita.errore = errore();
        bloc.add(const DettaglioAdminRichiesto(id: 7));

        await expectLater(bloc.stream, emitsInOrder([
          isA<DettaglioAdminLoading>(),
          isA<DettaglioAdminErrore>().having((s) => s.messaggio, "messaggio", messaggi[nome]),
        ]));
      });
    });
  });

  //le quattro operazioni seguono le stesse sequenze: cambiano evento, repository e messaggio
  final Map<String, DettaglioAdminEvent> eventi = {
    "partecipanti": const ModificaPartecipantiRichiesta(id: 7, telefoni: ["1", "2"]),
    "risultato": ModificaRisultatoRichiesta(id: 7, squadra1: const [11, 12], squadra2: const [13, 14], set: setValidi),
    "stato": const ModificaStatoRichiesta(id: 7, stato: "giocata"),
    "annulla": const AnnullaPartitaRichiesta(id: 7),
  };
  final Map<String, String> messaggiRiuscita = {
    "partecipanti": "Partecipanti aggiornati",
    "risultato": "Risultato aggiornato",
    "stato": "Stato aggiornato",
    "annulla": "Partita annullata",
  };

  void impostaErrore(String operazione, Exception errore)
  {
    if(operazione == "partecipanti")
    {
      repoAdmin.errorePartecipanti = errore;
    }
    else if(operazione == "risultato")
    {
      repoAdmin.erroreRisultato = errore;
    }
    else if(operazione == "stato")
    {
      repoAdmin.erroreStato = errore;
    }
    else
    {
      repoAdmin.erroreAnnulla = errore;
    }
  }

  void impostaRisposta(String operazione)
  {
    final nuovo = dettaglioDiTest(id: 7, stato: "confermata");
    if(operazione == "partecipanti")
    {
      repoAdmin.rispostaPartecipanti = nuovo;
    }
    else if(operazione == "risultato")
    {
      repoAdmin.rispostaRisultato = nuovo;
    }
    else if(operazione == "stato")
    {
      repoAdmin.rispostaStato = nuovo;
    }
    else
    {
      repoAdmin.rispostaAnnulla = nuovo;
    }
  }

  eventi.forEach((operazione, evento)
  {
    group("operazione $operazione", ()
    {
      test("prima del caricamento non fa nulla", () async
      {
        bloc.add(evento);
        await Future<void>.delayed(Duration.zero);

        expect(bloc.state, isA<DettaglioAdminInitial>());
        expect(repoAdmin.chiamatePartecipanti + repoAdmin.chiamateRisultato + repoAdmin.chiamateStato + repoAdmin.chiamateAnnulla, 0);
      });

      test("ok: InCorso col dettaglio vecchio, Riuscita col nuovo e nessuna ricarica", () async
      {
        await caricaDettaglio();
        impostaRisposta(operazione);

        bloc.add(evento);

        await expectLater(bloc.stream, emitsInOrder([
          isA<OperazioneAdminInCorso>().having((s) => s.dettaglio.stato, "stato", "creata"),
          isA<OperazioneAdminRiuscita>().having((s) => s.dettaglio.stato, "stato", "confermata").having((s) => s.messaggio, "messaggio", messaggiRiuscita[operazione]),
        ]));
        expect(bloc.dettaglio!.stato, "confermata");
        expect(repoPartita.chiamate, 1);
      });

      final errori = <String, Exception Function()>{
        "404": () => PartitaNonTrovata(messaggio: "Partita non trovata"),
        "409": () => OperazioneRifiutata(messaggio: "Regola violata"),
        "generico": () => ErroreGenericoServer(),
        "timeout": () => Exception("timeout"),
      };
      final messaggi = {
        "404": "Partita non trovata",
        "409": "Regola violata",
        "generico": ErroreGenericoServer().messaggio,
        "timeout": ErroreGenericoServer().messaggio,
      };
      errori.forEach((nome, errore)
      {
        test("errore $nome: Errore col dettaglio vecchio, poi la partita viene ricaricata senza Loading", () async
        {
          await caricaDettaglio();
          impostaErrore(operazione, errore());
          repoPartita.risposta = dettaglioDiTest(id: 7, stato: "giocata");

          bloc.add(evento);

          await expectLater(bloc.stream, emitsInOrder([
            isA<OperazioneAdminInCorso>(),
            isA<OperazioneAdminErrore>().having((s) => s.messaggio, "messaggio", messaggi[nome]).having((s) => s.dettaglio.stato, "stato", "creata"),
            isA<DettaglioAdminCaricato>().having((s) => s.dettaglio.stato, "stato", "giocata"),
          ]));
          expect(repoPartita.chiamate, 2);
          expect(bloc.dettaglio!.stato, "giocata");
        });
      });

      test("se fallisce anche la ricarica: Errore e poi DettaglioAdminErrore", () async
      {
        await caricaDettaglio();
        impostaErrore(operazione, OperazioneRifiutata(messaggio: "Regola violata"));
        repoPartita.errore = PartitaNonTrovata(messaggio: "Partita non trovata");

        bloc.add(evento);

        await expectLater(bloc.stream, emitsInOrder([
          isA<OperazioneAdminInCorso>(),
          isA<OperazioneAdminErrore>(),
          isA<DettaglioAdminErrore>().having((s) => s.messaggio, "messaggio", "Partita non trovata"),
        ]));
      });
    });
  });

  group("dati inviati", ()
  {
    test("partecipanti: partita e telefoni", () async
    {
      await caricaDettaglio();

      bloc.add(eventi["partecipanti"]!);
      await expectLater(bloc.stream, emitsInOrder([isA<OperazioneAdminInCorso>(), isA<OperazioneAdminRiuscita>()]));

      expect(repoAdmin.idPartecipantiRicevuto, 7);
      expect(repoAdmin.telefoniRicevuti, ["1", "2"]);
    });

    test("risultato: partita, squadre e set", () async
    {
      await caricaDettaglio();

      bloc.add(eventi["risultato"]!);
      await expectLater(bloc.stream, emitsInOrder([isA<OperazioneAdminInCorso>(), isA<OperazioneAdminRiuscita>()]));

      expect(repoAdmin.idRisultatoRicevuto, 7);
      expect(repoAdmin.squadra1Ricevuta, [11, 12]);
      expect(repoAdmin.squadra2Ricevuta, [13, 14]);
      expect(repoAdmin.setRicevuti, setValidi);
    });

    test("stato: partita e stato", () async
    {
      await caricaDettaglio();

      bloc.add(eventi["stato"]!);
      await expectLater(bloc.stream, emitsInOrder([isA<OperazioneAdminInCorso>(), isA<OperazioneAdminRiuscita>()]));

      expect(repoAdmin.idStatoRicevuto, 7);
      expect(repoAdmin.statoRicevuto, "giocata");
    });

    test("annulla: partita", () async
    {
      await caricaDettaglio();

      bloc.add(eventi["annulla"]!);
      await expectLater(bloc.stream, emitsInOrder([isA<OperazioneAdminInCorso>(), isA<OperazioneAdminRiuscita>()]));

      expect(repoAdmin.idAnnullaRicevuto, 7);
    });
  });

  //il server non e stato chiamato: niente ricarica
  group("validazioni, senza server e senza ricarica", ()
  {
    final casi = <String, DettaglioAdminEvent>{
      PartecipantiMancanti().message: const ModificaPartecipantiRichiesta(id: 7, telefoni: []),
      TroppiPartecipanti().message: const ModificaPartecipantiRichiesta(id: 7, telefoni: ["1", "2", "3", "4", "5"]),
      SquadraIncompleta().message: ModificaRisultatoRichiesta(id: 7, squadra1: const [11], squadra2: const [13, 14], set: setValidi),
      GiocatoriRipetuti().message: ModificaRisultatoRichiesta(id: 7, squadra1: const [11, 11], squadra2: const [13, 14], set: setValidi),
      NumeroSetNonValido().message: ModificaRisultatoRichiesta(id: 7, squadra1: const [11, 12], squadra2: const [13, 14], set: [setValidi.first]),
      SetNonValido().message: ModificaRisultatoRichiesta(id: 7, squadra1: const [11, 12], squadra2: const [13, 14], set: [setValidi.first, SetPartita(squadra1: 4, squadra2: 4)]),
    };
    casi.forEach((messaggio, evento)
    {
      test(messaggio, () async
      {
        await caricaDettaglio();

        bloc.add(evento);

        await expectLater(bloc.stream, emitsInOrder([
          isA<OperazioneAdminInCorso>(),
          isA<OperazioneAdminErrore>().having((s) => s.messaggio, "messaggio", messaggio).having((s) => s.dettaglio.id, "id", 7),
        ]));
        await Future<void>.delayed(Duration.zero);
        expect(bloc.state, isA<OperazioneAdminErrore>());
        expect(repoPartita.chiamate, 1);
        expect(repoAdmin.chiamatePartecipanti + repoAdmin.chiamateRisultato, 0);
      });
    });
  });

  group("giocatori del campo", ()
  {
    test("senza dettaglio caricato le operazioni non fanno nulla", () async
    {
      bloc.add(const AggiungiGiocatoriCampoRichiesta(id: 7, numero: 1));
      bloc.add(const RimuoviGiocatoreCampoRichiesta(id: 7, idPosto: 14));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state, isA<DettaglioAdminInitial>());
      expect(repoAdmin.numeroRicevuto, isNull);
      expect(repoAdmin.idPostoRicevuto, isNull);
    });

    test("aggiungi ok: InCorso poi Riuscita col dettaglio del server, senza ricaricare", () async
    {
      await caricaDettaglio();
      repoAdmin.rispostaGiocatoriCampo = dettaglioDiTest(id: 7, stato: "confermata");

      bloc.add(const AggiungiGiocatoriCampoRichiesta(id: 7, numero: 2));

      await expectLater(bloc.stream, emitsInOrder([
        isA<OperazioneAdminInCorso>().having((s) => s.dettaglio.stato, "stato", "creata"),
        isA<OperazioneAdminRiuscita>().having((s) => s.dettaglio.stato, "stato", "confermata").having((s) => s.messaggio, "messaggio", "Giocatori del campo aggiunti"),
      ]));
      expect(repoAdmin.idGiocatoriCampoRicevuto, 7);
      expect(repoAdmin.numeroRicevuto, 2);
      expect(repoPartita.chiamate, 1);
      expect(bloc.dettaglio!.stato, "confermata");
    });

    test("aggiungi con numero non valido: errore senza chiamare il server e senza ricaricare", () async
    {
      await caricaDettaglio();

      bloc.add(const AggiungiGiocatoriCampoRichiesta(id: 7, numero: 4));

      await expectLater(bloc.stream, emitsInOrder([
        isA<OperazioneAdminInCorso>(),
        isA<OperazioneAdminErrore>().having((s) => s.messaggio, "messaggio", NumeroGiocatoriCampoNonValido().message),
      ]));
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state, isA<OperazioneAdminErrore>());
      expect(repoAdmin.numeroRicevuto, isNull);
      expect(repoPartita.chiamate, 1);
    });

    test("rimuovi ok: InCorso poi Riuscita, passa partita e posto", () async
    {
      await caricaDettaglio();

      bloc.add(const RimuoviGiocatoreCampoRichiesta(id: 7, idPosto: 14));

      await expectLater(bloc.stream, emitsInOrder([
        isA<OperazioneAdminInCorso>(),
        isA<OperazioneAdminRiuscita>().having((s) => s.messaggio, "messaggio", "Giocatore del campo rimosso"),
      ]));
      expect(repoAdmin.idRimuoviCampoRicevuto, 7);
      expect(repoAdmin.idPostoRicevuto, 14);
    });

    final errori = <String, Exception Function()>{
      "404": () => PartitaNonTrovata(messaggio: "Partita non trovata"),
      "409": () => OperazioneRifiutata(messaggio: "Puoi aggiungere al massimo 1 giocatori del campo"),
      "generico": () => ErroreGenericoServer(),
      "rete": () => TimeoutException("timeout"),
    };
    final messaggi = <String, String>{
      "404": "Partita non trovata",
      "409": "Puoi aggiungere al massimo 1 giocatori del campo",
      "generico": ErroreGenericoServer().messaggio,
      "rete": ErroreGenericoServer().messaggio,
    };

    errori.forEach((nome, errore)
    {
      test("aggiungi, errore $nome: Errore col dettaglio vecchio, poi la partita viene ricaricata", () async
      {
        await caricaDettaglio();
        repoAdmin.erroreGiocatoriCampo = errore();

        bloc.add(const AggiungiGiocatoriCampoRichiesta(id: 7, numero: 1));

        await expectLater(bloc.stream, emitsInOrder([
          isA<OperazioneAdminInCorso>(),
          isA<OperazioneAdminErrore>().having((s) => s.messaggio, "messaggio", messaggi[nome]).having((s) => s.dettaglio.id, "id", 7),
          isA<DettaglioAdminCaricato>(),
        ]));
        expect(repoPartita.chiamate, 2);
      });

      test("rimuovi, errore $nome: Errore col dettaglio vecchio, poi la partita viene ricaricata", () async
      {
        await caricaDettaglio();
        repoAdmin.erroreRimuoviCampo = errore();

        bloc.add(const RimuoviGiocatoreCampoRichiesta(id: 7, idPosto: 14));

        await expectLater(bloc.stream, emitsInOrder([
          isA<OperazioneAdminInCorso>(),
          isA<OperazioneAdminErrore>().having((s) => s.messaggio, "messaggio", messaggi[nome]),
          isA<DettaglioAdminCaricato>(),
        ]));
        expect(repoPartita.chiamate, 2);
      });
    });
  });
}
