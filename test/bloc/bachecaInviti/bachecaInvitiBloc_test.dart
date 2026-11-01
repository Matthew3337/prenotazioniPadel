import 'package:flutter_test/flutter_test.dart';
import 'package:thepadel/bloc/bachecaInviti/bachecaInvitiBloc.dart';
import 'package:thepadel/bloc/bachecaInviti/bachecaInvitiEvent.dart';
import 'package:thepadel/bloc/bachecaInviti/bachecaInvitiState.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/useCase/bachecaInvitiUseCase.dart';

import '../../fake/fakePartitaRepo.dart';

Matcher caricataCon(List<int> idPartite)
{
  return isA<BachecaInvitiCaricata>().having((s) => s.partite.map((p) => p.id).toList(), "id partite", idPartite);
}

void main()
{
  late FakePartitaRepo repo;
  late BachecaInvitiBloc bloc;

  setUp(()
  {
    repo = FakePartitaRepo();
    repo.partiteInviti = [partitaInvitoDiTest(id: 10), partitaInvitoDiTest(id: 11, stato: "confermata")];
    bloc = BachecaInvitiBloc(bachecaInvitiUseCase: BachecaInvitiUseCase(repo: repo));
  });

  tearDown(() async
  {
    await bloc.close();
  });

  test("lo stato iniziale e BachecaInvitiInitial", ()
  {
    expect(bloc.state, isA<BachecaInvitiInitial>());
  });

  test("caricamento ok: Loading poi Caricata con le partite nell'ordine del repository", () async
  {
    bloc.add(const BachecaInvitiRichiesta());

    await expectLater(bloc.stream, emitsInOrder([
      isA<BachecaInvitiLoading>(),
      caricataCon([10, 11]),
    ]));
    expect(repo.chiamateInviti, 1);
  });

  test("nessun invito: Loading poi Caricata con lista vuota", () async
  {
    repo.partiteInviti = [];
    bloc.add(const BachecaInvitiRichiesta());

    await expectLater(bloc.stream, emitsInOrder([
      isA<BachecaInvitiLoading>(),
      caricataCon([]),
    ]));
  });

  test("errore: Loading poi Errore col messaggio di ErroreGenericoServer", () async
  {
    repo.erroreInviti = ErroreGenericoServer();
    bloc.add(const BachecaInvitiRichiesta());

    await expectLater(bloc.stream, emitsInOrder([
      isA<BachecaInvitiLoading>(),
      isA<BachecaInvitiErrore>().having((s) => s.messaggio, "messaggio", ErroreGenericoServer().messaggio),
    ]));
  });

  test("una seconda richiesta dopo l'errore ricarica la bacheca", () async
  {
    repo.erroreInviti = ErroreGenericoServer();
    bloc.add(const BachecaInvitiRichiesta());
    await expectLater(bloc.stream, emitsInOrder([isA<BachecaInvitiLoading>(), isA<BachecaInvitiErrore>()]));

    repo.erroreInviti = null;
    bloc.add(const BachecaInvitiRichiesta());

    await expectLater(bloc.stream, emitsInOrder([
      isA<BachecaInvitiLoading>(),
      caricataCon([10, 11]),
    ]));
    expect(repo.chiamateInviti, 2);
  });
}
