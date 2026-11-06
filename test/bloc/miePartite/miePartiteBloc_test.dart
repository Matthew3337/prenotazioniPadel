import 'package:flutter_test/flutter_test.dart';
import 'package:thepadel/bloc/miePartite/miePartiteBloc.dart';
import 'package:thepadel/bloc/miePartite/miePartiteEvent.dart';
import 'package:thepadel/bloc/miePartite/miePartiteState.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/useCase/miePartiteUseCase.dart';

import '../../fake/fakePartitaRepo.dart';

void main()
{
  late FakePartitaRepo repo;
  late MiePartiteBloc bloc;

  setUp(()
  {
    repo = FakePartitaRepo();
    repo.partiteMie = [partitaStoricoDiTest(id: 10), partitaStoricoDiTest(id: 11)];
    bloc = MiePartiteBloc(miePartiteUseCase: MiePartiteUseCase(repo: repo));
  });

  tearDown(() async
  {
    await bloc.close();
  });

  test("lo stato iniziale e MiePartiteInitial", ()
  {
    expect(bloc.state, isA<MiePartiteInitial>());
  });

  test("caricamento ok: Loading poi Caricate con le partite nell'ordine del repository", () async
  {
    bloc.add(const MiePartiteRichieste());

    await expectLater(bloc.stream, emitsInOrder([
      isA<MiePartiteLoading>(),
      isA<MiePartiteCaricate>().having((s) => s.partite.map((p) => p.id).toList(), "id", [10, 11]),
    ]));
    expect(repo.chiamateMie, 1);
    expect(repo.chiamateStorico, 0);
  });

  test("nessuna partita: Caricate con lista vuota", () async
  {
    repo.partiteMie = [];
    bloc.add(const MiePartiteRichieste());

    await expectLater(bloc.stream, emitsInOrder([
      isA<MiePartiteLoading>(),
      isA<MiePartiteCaricate>().having((s) => s.partite, "partite", isEmpty),
    ]));
  });

  test("ErroreGenericoServer: Loading poi Errore col suo messaggio", () async
  {
    repo.erroreMie = ErroreGenericoServer();
    bloc.add(const MiePartiteRichieste());

    await expectLater(bloc.stream, emitsInOrder([
      isA<MiePartiteLoading>(),
      isA<MiePartiteErrore>().having((s) => s.messaggio, "messaggio", ErroreGenericoServer().messaggio),
    ]));
  });

  test("timeout o rete assente: Errore col messaggio generico", () async
  {
    repo.erroreMie = Exception("timeout");
    bloc.add(const MiePartiteRichieste());

    await expectLater(bloc.stream, emitsInOrder([
      isA<MiePartiteLoading>(),
      isA<MiePartiteErrore>().having((s) => s.messaggio, "messaggio", ErroreGenericoServer().messaggio),
    ]));
  });
}
