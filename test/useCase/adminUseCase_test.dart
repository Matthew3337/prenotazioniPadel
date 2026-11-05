import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/domainLayer/enetity/setPartita.dart';
import 'package:thepadel/useCase/adminUseCase.dart';
import 'package:thepadel/useCase/eccezioniUseCase.dart';

import '../fake/fakeAdminRepo.dart';
import '../fake/fakeCampoRepo.dart';

SetPartita unSet(int squadra1, int squadra2)
{
  return SetPartita(squadra1: squadra1, squadra2: squadra2);
}

//i soli punteggi validi: gli inversi si provano nei test
const List<List<int>> punteggiValidi = [[6, 0], [6, 1], [6, 2], [6, 3], [6, 4], [7, 5], [7, 6]];

bool punteggioValido(int a, int b)
{
  for(final p in punteggiValidi)
  {
    if((a == p[0] && b == p[1]) || (a == p[1] && b == p[0]))
    {
      return true;
    }
  }
  return false;
}

void main()
{
  late FakeAdminRepo repo;

  setUp(()
  {
    repo = FakeAdminRepo();
  });

  group("letture", ()
  {
    test("PartiteGiornoUseCase passa la data e restituisce i campi", () async
    {
      repo.campi = [campoAdminDiTest()];
      final data = DateTime(2026, 11, 5);

      final campi = await PartiteGiornoUseCase(repo: repo).call(data);

      expect(campi.single.nomeCampo, "Campo Centrale");
      expect(repo.dateRicevute, [data]);
    });

    test("BachecaAvvisiUseCase restituisce gli avvisi", () async
    {
      repo.avvisi = [avvisoDiTest()];

      expect((await BachecaAvvisiUseCase(repo: repo).call()).length, 1);
    });

    test("UtentiAdminUseCase passa il testo cercato, anche vuoto", () async
    {
      await UtentiAdminUseCase(repo: repo).call("");
      await UtentiAdminUseCase(repo: repo).call("mar");

      expect(repo.cercaRicevuti, ["", "mar"]);
    });
  });

  group("CambiaLivelloUseCase", ()
  {
    for(final livello in [0.0, 0.5, 2.5, 3.0, 5.0])
    {
      test("livello $livello valido: arriva al repository", () async
      {
        final utente = await CambiaLivelloUseCase(repo: repo).call("3335550001", livello);

        expect(utente.livello, livello);
        expect(repo.telefonoLivelloRicevuto, "3335550001");
        expect(repo.livelloRicevuto, livello);
      });
    }

    for(final livello in [-0.5, 5.5, 2.3, 2.75, 100.0])
    {
      test("livello $livello: LivelloNonValido senza chiamare il repository", ()
      {
        expect(() => CambiaLivelloUseCase(repo: repo).call("3335550001", livello), throwsA(isA<LivelloNonValido>()));
        expect(repo.chiamateLivello, 0);
      });
    }
  });

  group("ModificaPartecipantiUseCase", ()
  {
    test("elenco vuoto: PartecipantiMancanti senza chiamare il repository", ()
    {
      expect(() => ModificaPartecipantiUseCase(repo: repo).call(7, []), throwsA(isA<PartecipantiMancanti>()));
      expect(repo.chiamatePartecipanti, 0);
    });

    test("cinque telefoni: TroppiPartecipanti senza chiamare il repository", ()
    {
      expect(() => ModificaPartecipantiUseCase(repo: repo).call(7, ["1", "2", "3", "4", "5"]), throwsA(isA<TroppiPartecipanti>()));
      expect(repo.chiamatePartecipanti, 0);
    });

    for(final telefoni in [["1"], ["1", "2", "3", "4"]])
    {
      test("${telefoni.length} telefoni: arrivano al repository", () async
      {
        final dettaglio = await ModificaPartecipantiUseCase(repo: repo).call(7, telefoni);

        expect(dettaglio.id, 7);
        expect(repo.idPartecipantiRicevuto, 7);
        expect(repo.telefoniRicevuti, telefoni);
      });
    }

    test("gli errori del repository arrivano a chi chiama", () async
    {
      repo.errorePartecipanti = OperazioneRifiutata(messaggio: "no");

      await expectLater(ModificaPartecipantiUseCase(repo: repo).call(7, ["1"]), throwsA(isA<OperazioneRifiutata>()));
    });
  });

  group("ModificaRisultatoUseCase", ()
  {
    late ModificaRisultatoUseCase useCase;

    setUp(()
    {
      useCase = ModificaRisultatoUseCase(repo: repo);
    });

    test("due set: passa partita, squadre e set", () async
    {
      final set = [unSet(6, 4), unSet(6, 2)];

      final dettaglio = await useCase.call(7, [11, 12], [13, 14], set);

      expect(dettaglio.id, 7);
      expect(repo.idRisultatoRicevuto, 7);
      expect(repo.squadra1Ricevuta, [11, 12]);
      expect(repo.squadra2Ricevuta, [13, 14]);
      expect(repo.setRicevuti, set);
    });

    test("tre set: validi", () async
    {
      await useCase.call(7, [11, 12], [13, 14], [unSet(6, 4), unSet(2, 6), unSet(6, 0)]);

      expect(repo.chiamateRisultato, 1);
    });

    final squadreSbagliate = {
      "squadra 1 con un giocatore": [[11], [13, 14]],
      "squadra 2 con un giocatore": [[11, 12], [13]],
      "squadra 1 con tre giocatori": [[11, 12, 15], [13, 14]],
    };
    squadreSbagliate.forEach((nome, squadre)
    {
      test("$nome: SquadraIncompleta", ()
      {
        expect(() => useCase.call(7, squadre[0], squadre[1], [unSet(6, 4), unSet(6, 2)]), throwsA(isA<SquadraIncompleta>()));
        expect(repo.chiamateRisultato, 0);
      });
    });

    final squadreRipetute = {
      "stesso posto nella stessa squadra": [[11, 11], [13, 14]],
      "stesso posto nelle due squadre": [[11, 12], [12, 14]],
    };
    squadreRipetute.forEach((nome, squadre)
    {
      test("$nome: GiocatoriRipetuti", ()
      {
        expect(() => useCase.call(7, squadre[0], squadre[1], [unSet(6, 4), unSet(6, 2)]), throwsA(isA<GiocatoriRipetuti>()));
        expect(repo.chiamateRisultato, 0);
      });
    });

    for(final numero in [0, 1, 4])
    {
      test("$numero set: NumeroSetNonValido", ()
      {
        final set = List.generate(numero, (_) => unSet(6, 4));

        expect(() => useCase.call(7, [11, 12], [13, 14], set), throwsA(isA<NumeroSetNonValido>()));
        expect(repo.chiamateRisultato, 0);
      });
    }

    final setSbagliati = {
      "parita": unSet(4, 4),
      "7-4 per la squadra 1": unSet(7, 4),
      "7-4 per la squadra 2": unSet(4, 7),
      "game negativi per la squadra 1": unSet(-1, 6),
      "game negativi per la squadra 2": unSet(6, -1),
    };
    setSbagliati.forEach((nome, set)
    {
      test("set con $nome: SetNonValido", ()
      {
        expect(() => useCase.call(7, [11, 12], [13, 14], [unSet(6, 4), set]), throwsA(isA<SetNonValido>()));
        expect(repo.chiamateRisultato, 0);
      });
    });
  });

  test("ModificaStatoUseCase passa partita e stato", () async
  {
    final dettaglio = await ModificaStatoUseCase(repo: repo).call(7, "giocata");

    expect(dettaglio.stato, "giocata");
    expect(repo.idStatoRicevuto, 7);
    expect(repo.statoRicevuto, "giocata");
  });

  test("AnnullaPartitaUseCase passa la partita", () async
  {
    final dettaglio = await AnnullaPartitaUseCase(repo: repo).call(7);

    expect(dettaglio.stato, "annullata");
    expect(repo.idAnnullaRicevuto, 7);
  });

  group("ModificaRisultatoUseCase regola dei set", ()
  {
    late ModificaRisultatoUseCase useCase;

    setUp(()
    {
      useCase = ModificaRisultatoUseCase(repo: repo);
    });

    //tutte le coppie da 0 a 8 game: comprende 5-4, 6-5, 7-4, 6-6, 7-7, 0-0 e 8-6
    for(int a = 0; a <= 8; a++)
    {
      for(int b = 0; b <= 8; b++)
      {
        if(punteggioValido(a, b))
        {
          test("$a-$b passa al repository", () async
          {
            await useCase.call(7, [11, 12], [13, 14], [unSet(6, 4), unSet(a, b)]);

            expect(repo.chiamateRisultato, 1);
          });
        }
        else
        {
          test("$a-$b: SetNonValido, nessuna chiamata", ()
          {
            expect(() => useCase.call(7, [11, 12], [13, 14], [unSet(6, 4), unSet(a, b)]), throwsA(isA<SetNonValido>()));
            expect(repo.chiamateRisultato, 0);
          });
        }
      }
    }
  });

  group("LivelloCampoUseCase e CambiaLivelloCampoUseCase", ()
  {
    test("la lettura restituisce il livello del repository", () async
    {
      repo.livelloCampo = 3.5;

      expect(await LivelloCampoUseCase(repo: repo).call(), 3.5);
    });

    for(final livello in [-0.5, 5.5, 2.3])
    {
      test("il livello $livello non e valido e il server non viene chiamato", ()
      {
        expect(() => CambiaLivelloCampoUseCase(repo: repo).call(livello), throwsA(isA<LivelloNonValido>()));
        expect(repo.livelliCampoRicevuti, isEmpty);
      });
    }

    for(final livello in [0.0, 2.5, 5.0])
    {
      test("il livello $livello viene salvato", () async
      {
        expect(await CambiaLivelloCampoUseCase(repo: repo).call(livello), livello);
        expect(repo.livelliCampoRicevuti, [livello]);
      });
    }
  });

  group("AggiungiGiocatoriCampoUseCase", ()
  {
    for(final numero in [0, 4, -1])
    {
      test("$numero giocatori: NumeroGiocatoriCampoNonValido e il server non viene chiamato", ()
      {
        expect(() => AggiungiGiocatoriCampoUseCase(repo: repo).call(7, numero), throwsA(isA<NumeroGiocatoriCampoNonValido>()));
        expect(repo.numeroRicevuto, isNull);
      });
    }

    for(final numero in [1, 3])
    {
      test("$numero giocatori arrivano al repository con la partita", () async
      {
        final dettaglio = await AggiungiGiocatoriCampoUseCase(repo: repo).call(7, numero);

        expect(dettaglio.id, 7);
        expect(repo.idGiocatoriCampoRicevuto, 7);
        expect(repo.numeroRicevuto, numero);
      });
    }
  });

  test("RimuoviGiocatoreCampoUseCase passa partita e posto", () async
  {
    final dettaglio = await RimuoviGiocatoreCampoUseCase(repo: repo).call(7, 14);

    expect(dettaglio.id, 7);
    expect(repo.idRimuoviCampoRicevuto, 7);
    expect(repo.idPostoRicevuto, 14);
  });

  group("CreaPartitaAdminUseCase", ()
  {
    final data = DateTime(2026, 11, 5);

    test("senza utenti: PartecipantiMancanti anche se ci sono giocatori del campo", ()
    {
      expect(() => CreaPartitaAdminUseCase(repo: repo).call(1, data, "18:00", "PUBBLICA", [], 3), throwsA(isA<PartecipantiMancanti>()));
      expect(repo.chiamateCreaPartita, 0);
    });

    test("piu di 4 posti tra utenti e giocatori del campo: TroppiPartecipanti", ()
    {
      expect(() => CreaPartitaAdminUseCase(repo: repo).call(1, data, "18:00", "PUBBLICA", ["1", "2"], 3), throwsA(isA<TroppiPartecipanti>()));
      expect(() => CreaPartitaAdminUseCase(repo: repo).call(1, data, "18:00", "PUBBLICA", ["1", "2", "3", "4", "5"], 0), throwsA(isA<TroppiPartecipanti>()));
      expect(repo.chiamateCreaPartita, 0);
    });

    test("1 utente e 3 giocatori del campo vanno bene e i dati arrivano al repository", () async
    {
      await CreaPartitaAdminUseCase(repo: repo).call(1, data, "18:00", "PRIVATA", ["1"], 3);

      expect(repo.idCampoCreaRicevuto, 1);
      expect(repo.dataCreaRicevuta, data);
      expect(repo.oraCreaRicevuta, "18:00");
      expect(repo.tipoCreaRicevuto, "PRIVATA");
      expect(repo.telefoniCreaRicevuti, ["1"]);
      expect(repo.giocatoriCampoCreaRicevuti, 3);
    });
  });

  group("campi", ()
  {
    const apertura = TimeOfDay(hour: 8, minute: 0);
    const chiusura = TimeOfDay(hour: 22, minute: 30);
    late FakeCampoRepo repoCampo;

    setUp(()
    {
      repoCampo = FakeCampoRepo();
    });

    for(final nome in ["", "   "])
    {
      test("nome '$nome': NomeCampoMancante e il server non viene chiamato", ()
      {
        expect(() => SalvaCampoUseCase(repo: repoCampo).call(null, nome, true, apertura, chiusura), throwsA(isA<NomeCampoMancante>()));
        expect(repoCampo.chiamateCrea + repoCampo.chiamateModifica, 0);
      });
    }

    test("senza id crea il campo", () async
    {
      final campo = await SalvaCampoUseCase(repo: repoCampo).call(null, "Nuovo", true, apertura, chiusura);

      expect(campo.id, repoCampo.idNuovoCampo);
      expect(repoCampo.chiamateCrea, 1);
      expect(repoCampo.chiamateModifica, 0);
      expect(repoCampo.nomeRicevuto, "Nuovo");
      expect(repoCampo.alCopertoRicevuto, true);
      expect(repoCampo.aperturaRicevuta, apertura);
      expect(repoCampo.chiusuraRicevuta, chiusura);
    });

    test("con l'id modifica quel campo", () async
    {
      final campo = await SalvaCampoUseCase(repo: repoCampo).call(3, "Rinominato", false, apertura, chiusura);

      expect(campo.id, 3);
      expect(repoCampo.chiamateCrea, 0);
      expect(repoCampo.idModificaRicevuto, 3);
    });

    test("EliminaCampoUseCase passa l'id", () async
    {
      await EliminaCampoUseCase(repo: repoCampo).call(3);

      expect(repoCampo.idEliminaRicevuto, 3);
    });
  });
}
