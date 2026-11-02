import 'package:flutter_test/flutter_test.dart';
import 'package:thepadel/bloc/registraRisultato/registraRisultatoBloc.dart';
import 'package:thepadel/bloc/registraRisultato/registraRisultatoEvent.dart';
import 'package:thepadel/bloc/registraRisultato/registraRisultatoState.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/domainLayer/enetity/setPartita.dart';
import 'package:thepadel/useCase/eccezioniUseCase.dart';
import 'package:thepadel/useCase/registraRisultatoUseCase.dart';

import '../../fake/fakePartitaRepo.dart';

Matcher erroreCon(String messaggio)
{
  return isA<RegistraRisultatoErrore>().having((s) => s.messaggio, "messaggio", messaggio);
}

RegistraRisultatoRichiesto eventoValido()
{
  return RegistraRisultatoRichiesto(idPartita: 7, squadra1: const [11, 12], squadra2: const [13, 14], set: [SetPartita(squadra1: 6, squadra2: 4), SetPartita(squadra1: 6, squadra2: 2)]);
}

void main()
{
  late FakePartitaRepo repo;
  late RegistraRisultatoBloc bloc;

  setUp(()
  {
    repo = FakePartitaRepo();
    bloc = RegistraRisultatoBloc(registraRisultatoUseCase: RegistraRisultatoUseCase(repo: repo));
  });

  tearDown(() async
  {
    await bloc.close();
  });

  test("lo stato iniziale e RegistraRisultatoInitial", ()
  {
    expect(bloc.state, isA<RegistraRisultatoInitial>());
  });

  test("successo: Loading poi RisultatoRegistrato col dettaglio del server", () async
  {
    repo.rispostaRisultato = dettaglioDiTest(stato: "giocata", risultato: risultatoDiTest());

    bloc.add(eventoValido());

    await expectLater(bloc.stream, emitsInOrder([
      isA<RegistraRisultatoLoading>(),
      isA<RisultatoRegistrato>().having((s) => s.dettaglio.stato, "stato", "giocata").having((s) => s.dettaglio.risultato, "risultato", isNotNull),
    ]));
    expect(repo.idRisultatoRicevuto, 7);
    expect(repo.squadra1Ricevuta, [11, 12]);
    expect(repo.squadra2Ricevuta, [13, 14]);
    expect(repo.setRicevuti!.length, 2);
  });

  group("validazione: Loading poi Errore col messaggio, nessuna chiamata", ()
  {
    final dueSet = [SetPartita(squadra1: 6, squadra2: 4), SetPartita(squadra1: 6, squadra2: 2)];

    test("squadra incompleta", () async
    {
      bloc.add(RegistraRisultatoRichiesto(idPartita: 7, squadra1: const [11], squadra2: const [12, 13, 14], set: dueSet));

      await expectLater(bloc.stream, emitsInOrder([isA<RegistraRisultatoLoading>(), erroreCon(SquadraIncompleta().message)]));
      expect(repo.chiamateRisultato, 0);
    });

    test("giocatori ripetuti", () async
    {
      bloc.add(RegistraRisultatoRichiesto(idPartita: 7, squadra1: const [11, 12], squadra2: const [12, 14], set: dueSet));

      await expectLater(bloc.stream, emitsInOrder([isA<RegistraRisultatoLoading>(), erroreCon(GiocatoriRipetuti().message)]));
      expect(repo.chiamateRisultato, 0);
    });

    test("numero di set sbagliato", () async
    {
      bloc.add(RegistraRisultatoRichiesto(idPartita: 7, squadra1: const [11, 12], squadra2: const [13, 14], set: [dueSet[0]]));

      await expectLater(bloc.stream, emitsInOrder([isA<RegistraRisultatoLoading>(), erroreCon(NumeroSetNonValido().message)]));
      expect(repo.chiamateRisultato, 0);
    });

    test("set non valido", () async
    {
      bloc.add(RegistraRisultatoRichiesto(idPartita: 7, squadra1: const [11, 12], squadra2: const [13, 14], set: [dueSet[0], SetPartita(squadra1: 3, squadra2: 3)]));

      await expectLater(bloc.stream, emitsInOrder([isA<RegistraRisultatoLoading>(), erroreCon(SetNonValido().message)]));
      expect(repo.chiamateRisultato, 0);
    });
  });

  group("errori del server: Loading poi Errore", ()
  {
    test("PartitaNonTrovata porta il messaggio del server", () async
    {
      repo.erroreRisultato = PartitaNonTrovata(messaggio: "Partita non trovata");

      bloc.add(eventoValido());

      await expectLater(bloc.stream, emitsInOrder([isA<RegistraRisultatoLoading>(), erroreCon("Partita non trovata")]));
    });

    test("OperazioneRifiutata porta il messaggio del server", () async
    {
      repo.erroreRisultato = OperazioneRifiutata(messaggio: "Il risultato è già stato registrato");

      bloc.add(eventoValido());

      await expectLater(bloc.stream, emitsInOrder([isA<RegistraRisultatoLoading>(), erroreCon("Il risultato è già stato registrato")]));
      expect(repo.chiamateRisultato, 1);
    });

    test("ErroreGenericoServer porta il suo messaggio", () async
    {
      repo.erroreRisultato = ErroreGenericoServer();

      bloc.add(eventoValido());

      await expectLater(bloc.stream, emitsInOrder([isA<RegistraRisultatoLoading>(), erroreCon(ErroreGenericoServer().messaggio)]));
    });
  });
}
