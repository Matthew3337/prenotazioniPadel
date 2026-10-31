import 'package:flutter_test/flutter_test.dart';
import 'package:thepadel/bloc/dettaglioPartita/dettaglioPartitaBloc.dart';
import 'package:thepadel/bloc/dettaglioPartita/dettaglioPartitaEvent.dart';
import 'package:thepadel/bloc/dettaglioPartita/dettaglioPartitaState.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/useCase/dettaglioPartitaUseCase.dart';

import '../../fake/fakePartitaRepo.dart';

Matcher erroreCon(String messaggio)
{
  return isA<DettaglioPartitaErrore>().having((s) => s.messaggio, "messaggio", messaggio);
}

void main()
{
  late FakePartitaRepo repo;
  late DettaglioPartitaBloc bloc;

  setUp(()
  {
    repo = FakePartitaRepo();
    bloc = DettaglioPartitaBloc(dettaglioPartitaUseCase: DettaglioPartitaUseCase(repo: repo));
  });

  tearDown(() async
  {
    await bloc.close();
  });

  test("lo stato iniziale e DettaglioPartitaInitial", ()
  {
    expect(bloc.state, isA<DettaglioPartitaInitial>());
  });

  test("successo: Loading poi Caricato col dettaglio, l'id arriva al repository", () async
  {
    bloc.add(const DettaglioPartitaRichiesto(idPartita: 10));

    await expectLater(bloc.stream, emitsInOrder([
      isA<DettaglioPartitaLoading>(),
      isA<DettaglioPartitaCaricato>().having((s) => s.dettaglio.id, "id", 10).having((s) => s.dettaglio.posti.length, "posti", 2),
    ]));
    expect(repo.chiamate, 1);
    expect(repo.idRicevuto, 10);
  });

  test("404: Loading poi Errore col messaggio di PartitaNonTrovata", () async
  {
    repo.errore = PartitaNonTrovata(messaggio: "Partita non trovata");
    bloc.add(const DettaglioPartitaRichiesto(idPartita: 99));

    await expectLater(bloc.stream, emitsInOrder([
      isA<DettaglioPartitaLoading>(),
      erroreCon("Partita non trovata"),
    ]));
  });

  test("errore generico: Loading poi Errore col messaggio di ErroreGenericoServer", () async
  {
    repo.errore = ErroreGenericoServer();
    bloc.add(const DettaglioPartitaRichiesto(idPartita: 10));

    await expectLater(bloc.stream, emitsInOrder([
      isA<DettaglioPartitaLoading>(),
      erroreCon(ErroreGenericoServer().messaggio),
    ]));
  });
}
