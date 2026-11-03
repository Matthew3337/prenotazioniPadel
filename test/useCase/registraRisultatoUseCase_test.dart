import 'package:flutter_test/flutter_test.dart';
import 'package:thepadel/domainLayer/enetity/setPartita.dart';
import 'package:thepadel/useCase/eccezioniUseCase.dart';
import 'package:thepadel/useCase/registraRisultatoUseCase.dart';

import '../fake/fakePartitaRepo.dart';

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
  late FakePartitaRepo repo;
  late RegistraRisultatoUseCase useCase;

  setUp(()
  {
    repo = FakePartitaRepo();
    useCase = RegistraRisultatoUseCase(repo: repo);
  });

  group("RegistraRisultatoUseCase dati validi", ()
  {
    test("due set: passa al repository partita, squadre e set", () async
    {
      final set = [unSet(6, 4), unSet(6, 2)];

      final dettaglio = await useCase.call(7, [11, 12], [13, 14], set);

      expect(dettaglio.id, 10);
      expect(repo.chiamateRisultato, 1);
      expect(repo.idRisultatoRicevuto, 7);
      expect(repo.squadra1Ricevuta, [11, 12]);
      expect(repo.squadra2Ricevuta, [13, 14]);
      expect(repo.setRicevuti, set);
    });

    test("tre set e game ai limiti 0 e 6 vengono accettati", () async
    {
      await useCase.call(7, [11, 12], [13, 14], [unSet(6, 0), unSet(0, 6), unSet(6, 4)]);

      expect(repo.chiamateRisultato, 1);
      expect(repo.setRicevuti!.length, 3);
    });

    test("la regola su chi vince i set la decide il server: 2 set a uno pari passano", () async
    {
      await useCase.call(7, [11, 12], [13, 14], [unSet(6, 4), unSet(4, 6)]);

      expect(repo.chiamateRisultato, 1);
    });
  });

  group("RegistraRisultatoUseCase squadre non valide", ()
  {
    test("squadra 1 con un solo giocatore: SquadraIncompleta, nessuna chiamata", ()
    {
      expect(() => useCase.call(7, [11], [12, 13, 14], [unSet(6, 4), unSet(6, 2)]), throwsA(isA<SquadraIncompleta>()));
      expect(repo.chiamateRisultato, 0);
    });

    test("squadra 2 con un solo giocatore: SquadraIncompleta, nessuna chiamata", ()
    {
      expect(() => useCase.call(7, [11, 12, 13], [14], [unSet(6, 4), unSet(6, 2)]), throwsA(isA<SquadraIncompleta>()));
      expect(repo.chiamateRisultato, 0);
    });

    test("squadre vuote: SquadraIncompleta, nessuna chiamata", ()
    {
      expect(() => useCase.call(7, [], [], [unSet(6, 4), unSet(6, 2)]), throwsA(isA<SquadraIncompleta>()));
      expect(repo.chiamateRisultato, 0);
    });

    test("giocatore ripetuto nella stessa squadra: GiocatoriRipetuti, nessuna chiamata", ()
    {
      expect(() => useCase.call(7, [11, 11], [13, 14], [unSet(6, 4), unSet(6, 2)]), throwsA(isA<GiocatoriRipetuti>()));
      expect(repo.chiamateRisultato, 0);
    });

    test("giocatore in tutte e due le squadre: GiocatoriRipetuti, nessuna chiamata", ()
    {
      expect(() => useCase.call(7, [11, 12], [12, 14], [unSet(6, 4), unSet(6, 2)]), throwsA(isA<GiocatoriRipetuti>()));
      expect(repo.chiamateRisultato, 0);
    });
  });

  group("RegistraRisultatoUseCase set non validi", ()
  {
    test("nessun set: NumeroSetNonValido, nessuna chiamata", ()
    {
      expect(() => useCase.call(7, [11, 12], [13, 14], []), throwsA(isA<NumeroSetNonValido>()));
      expect(repo.chiamateRisultato, 0);
    });

    test("un solo set: NumeroSetNonValido, nessuna chiamata", ()
    {
      expect(() => useCase.call(7, [11, 12], [13, 14], [unSet(6, 4)]), throwsA(isA<NumeroSetNonValido>()));
      expect(repo.chiamateRisultato, 0);
    });

    test("quattro set: NumeroSetNonValido, nessuna chiamata", ()
    {
      expect(() => useCase.call(7, [11, 12], [13, 14], [unSet(6, 4), unSet(4, 6), unSet(6, 4), unSet(6, 4)]), throwsA(isA<NumeroSetNonValido>()));
      expect(repo.chiamateRisultato, 0);
    });

    final setSbagliati = {
      "squadra 1 finisce 7-4": unSet(7, 4),
      "squadra 2 finisce 4-7": unSet(4, 7),
      "squadra 1 sotto zero": unSet(-1, 5),
      "squadra 2 sotto zero": unSet(5, -1),
      "set in parita": unSet(3, 3),
      "set zero a zero": unSet(0, 0),
    };

    for(final caso in setSbagliati.entries)
    {
      test("${caso.key}: SetNonValido, nessuna chiamata", ()
      {
        expect(() => useCase.call(7, [11, 12], [13, 14], [unSet(6, 4), caso.value]), throwsA(isA<SetNonValido>()));
        expect(repo.chiamateRisultato, 0);
      });
    }

    test("anche il terzo set viene controllato", ()
    {
      expect(() => useCase.call(7, [11, 12], [13, 14], [unSet(6, 4), unSet(4, 6), unSet(2, 2)]), throwsA(isA<SetNonValido>()));
      expect(repo.chiamateRisultato, 0);
    });
  });

  group("setValido", ()
  {
    //tutte le coppie da 0 a 8 game: comprende 5-4, 6-5, 7-4, 6-6, 7-7, 0-0 e 8-6
    for(int a = 0; a <= 8; a++)
    {
      for(int b = 0; b <= 8; b++)
      {
        final bool atteso = punteggioValido(a, b);

        test("$a-$b e ${atteso ? "valido" : "non valido"}", ()
        {
          expect(setValido(unSet(a, b)), atteso);
        });
      }
    }

    test("i punteggi validi sono 14, contando gli inversi", ()
    {
      int validi = 0;
      for(int a = 0; a <= 8; a++)
      {
        for(int b = 0; b <= 8; b++)
        {
          if(setValido(unSet(a, b)))
          {
            validi++;
          }
        }
      }

      expect(validi, 14);
    });

    test("game negativi: non valido", ()
    {
      expect(setValido(unSet(-1, 6)), isFalse);
      expect(setValido(unSet(6, -1)), isFalse);
    });

    test("il messaggio di SetNonValido spiega la regola", ()
    {
      expect(SetNonValido().message, "si vince a 6 game con almeno 2 di scarto, oppure 7-5 o 7-6");
    });
  });

  group("RegistraRisultatoUseCase regola dei set", ()
  {
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
}
