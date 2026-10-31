import 'package:flutter_test/flutter_test.dart';
import 'package:thepadel/bloc/creaPartita/creaPartitaBloc.dart';
import 'package:thepadel/bloc/creaPartita/creaPartitaEvent.dart';
import 'package:thepadel/bloc/creaPartita/creaPartitaState.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/useCase/creaPartitaUseCase.dart';

import '../../fake/fakePrenotazioneRepo.dart';

Matcher erroreCon(String messaggio)
{
  return isA<CreaPartitaErrore>().having((s) => s.messaggio, "messaggio", messaggio);
}

void main()
{
  late FakePrenotazioneRepo repo;
  late CreaPartitaBloc bloc;

  setUp(()
  {
    repo = FakePrenotazioneRepo();
    bloc = CreaPartitaBloc(creaPartitaUseCase: CreaPartitaUseCase(repo: repo));
  });

  tearDown(() async
  {
    await bloc.close();
  });

  test("lo stato iniziale e CreaPartitaInitial", ()
  {
    expect(bloc.state, isA<CreaPartitaInitial>());
  });

  test("successo: Loading poi Success con la prenotazione creata", () async
  {
    bloc.add(CreaPartitaRichiesta(slot: slotDiTest(), data: DateTime(2026, 11, 2), tipo: "PUBBLICA"));

    await expectLater(bloc.stream, emitsInOrder([
      isA<CreaPartitaLoading>(),
      isA<CreaPartitaSuccess>().having((s) => s.prenotazione.id, "id", 10).having((s) => s.prenotazione.tipo, "tipo", "PUBBLICA"),
    ]));
    expect(repo.tipoRicevuto, "PUBBLICA");
  });

  test("tipo non scelto: Loading poi Errore col messaggio di validazione, nessuna chiamata", () async
  {
    bloc.add(CreaPartitaRichiesta(slot: slotDiTest(), data: DateTime(2026, 11, 2), tipo: ""));

    await expectLater(bloc.stream, emitsInOrder([
      isA<CreaPartitaLoading>(),
      erroreCon("scegliere se la partita è pubblica o privata"),
    ]));
    expect(repo.chiamate, 0);
  });

  test("409: Loading poi Errore col messaggio del server", () async
  {
    repo.errore = SlotNonDisponibile(messaggio: "Lo slot selezionato è già occupato");
    bloc.add(CreaPartitaRichiesta(slot: slotDiTest(), data: DateTime(2026, 11, 2), tipo: "PRIVATA"));

    await expectLater(bloc.stream, emitsInOrder([
      isA<CreaPartitaLoading>(),
      erroreCon("Lo slot selezionato è già occupato"),
    ]));
  });

  test("400: Loading poi Errore col messaggio del server", () async
  {
    repo.errore = PrenotazioneNonValida(messaggio: "Dati non validi");
    bloc.add(CreaPartitaRichiesta(slot: slotDiTest(), data: DateTime(2026, 11, 2), tipo: "PUBBLICA"));

    await expectLater(bloc.stream, emitsInOrder([isA<CreaPartitaLoading>(), erroreCon("Dati non validi")]));
  });

  test("404: Loading poi Errore col messaggio del server", () async
  {
    repo.errore = CampoInesistente(messaggio: "Campo non trovato");
    bloc.add(CreaPartitaRichiesta(slot: slotDiTest(), data: DateTime(2026, 11, 2), tipo: "PUBBLICA"));

    await expectLater(bloc.stream, emitsInOrder([isA<CreaPartitaLoading>(), erroreCon("Campo non trovato")]));
  });

  test("errore generico: Loading poi Errore col messaggio generico", () async
  {
    repo.errore = ErroreGenericoServer();
    bloc.add(CreaPartitaRichiesta(slot: slotDiTest(), data: DateTime(2026, 11, 2), tipo: "PUBBLICA"));

    await expectLater(bloc.stream, emitsInOrder([
      isA<CreaPartitaLoading>(),
      erroreCon("errore generico del server, riprova piu tardi"),
    ]));
  });
}
