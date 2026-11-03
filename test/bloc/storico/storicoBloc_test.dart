import 'package:flutter_test/flutter_test.dart';
import 'package:thepadel/bloc/storico/storicoBloc.dart';
import 'package:thepadel/bloc/storico/storicoEvent.dart';
import 'package:thepadel/bloc/storico/storicoState.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/useCase/storicoUseCase.dart';

import '../../fake/fakePartitaRepo.dart';

Matcher caricatoCon(List<int> idPartite)
{
  return isA<StoricoCaricato>().having((s) => s.partite.map((p) => p.id).toList(), "id partite", idPartite);
}

void main()
{
  late FakePartitaRepo repo;
  late StoricoBloc bloc;

  setUp(()
  {
    repo = FakePartitaRepo();
    repo.partiteStorico = [partitaStoricoDiTest(id: 10), partitaStoricoDiTest(id: 11, risultato: risultatoDiTest())];
    bloc = StoricoBloc(storicoUseCase: StoricoUseCase(repo: repo));
  });

  tearDown(() async
  {
    await bloc.close();
  });

  test("lo stato iniziale e StoricoInitial", ()
  {
    expect(bloc.state, isA<StoricoInitial>());
  });

  test("caricamento ok: Loading poi Caricato con le partite nell'ordine del repository", () async
  {
    bloc.add(const StoricoRichiesto());

    await expectLater(bloc.stream, emitsInOrder([
      isA<StoricoLoading>(),
      caricatoCon([10, 11]),
    ]));
    expect(repo.chiamateStorico, 1);
  });

  test("storico vuoto: Loading poi Caricato con lista vuota", () async
  {
    repo.partiteStorico = [];
    bloc.add(const StoricoRichiesto());

    await expectLater(bloc.stream, emitsInOrder([
      isA<StoricoLoading>(),
      caricatoCon([]),
    ]));
  });

  test("errore: Loading poi Errore col messaggio di ErroreGenericoServer", () async
  {
    repo.erroreStorico = ErroreGenericoServer();
    bloc.add(const StoricoRichiesto());

    await expectLater(bloc.stream, emitsInOrder([
      isA<StoricoLoading>(),
      isA<StoricoErrore>().having((s) => s.messaggio, "messaggio", ErroreGenericoServer().messaggio),
    ]));
  });

  test("una seconda richiesta dopo l'errore ricarica lo storico", () async
  {
    repo.erroreStorico = ErroreGenericoServer();
    bloc.add(const StoricoRichiesto());
    await expectLater(bloc.stream, emitsInOrder([isA<StoricoLoading>(), isA<StoricoErrore>()]));

    repo.erroreStorico = null;
    bloc.add(const StoricoRichiesto());

    await expectLater(bloc.stream, emitsInOrder([
      isA<StoricoLoading>(),
      caricatoCon([10, 11]),
    ]));
    expect(repo.chiamateStorico, 2);
  });

  test("timeout o rete assente: Loading poi Errore col messaggio generico", () async
  {
    repo.erroreStorico = Exception("timeout");
    bloc.add(const StoricoRichiesto());

    await expectLater(bloc.stream, emitsInOrder([
      isA<StoricoLoading>(),
      isA<StoricoErrore>().having((s) => s.messaggio, "messaggio", ErroreGenericoServer().messaggio),
    ]));
  });
}
