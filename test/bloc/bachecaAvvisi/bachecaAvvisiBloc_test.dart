import 'package:flutter_test/flutter_test.dart';
import 'package:thepadel/bloc/bachecaAvvisi/bachecaAvvisiBloc.dart';
import 'package:thepadel/bloc/bachecaAvvisi/bachecaAvvisiEvent.dart';
import 'package:thepadel/bloc/bachecaAvvisi/bachecaAvvisiState.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/useCase/adminUseCase.dart';

import '../../fake/fakeAdminRepo.dart';

Matcher erroreCon(String messaggio)
{
  return isA<BachecaAvvisiErrore>().having((s) => s.messaggio, "messaggio", messaggio);
}

void main()
{
  late FakeAdminRepo repo;
  late BachecaAvvisiBloc bloc;

  setUp(()
  {
    repo = FakeAdminRepo();
    bloc = BachecaAvvisiBloc(bachecaAvvisiUseCase: BachecaAvvisiUseCase(repo: repo));
  });

  tearDown(() async
  {
    await bloc.close();
  });

  test("lo stato iniziale e BachecaAvvisiInitial", ()
  {
    expect(bloc.state, isA<BachecaAvvisiInitial>());
  });

  test("caricamento ok: Loading poi Caricata con gli avvisi", () async
  {
    repo.avvisi = [avvisoDiTest(id: 1), avvisoDiTest(id: 2)];
    bloc.add(const BachecaAvvisiRichiesta());

    await expectLater(bloc.stream, emitsInOrder([
      isA<BachecaAvvisiLoading>(),
      isA<BachecaAvvisiCaricata>().having((s) => s.avvisi.map((a) => a.id).toList(), "id", [1, 2]),
    ]));
  });

  test("nessun avviso: Loading poi Caricata con lista vuota", () async
  {
    bloc.add(const BachecaAvvisiRichiesta());

    await expectLater(bloc.stream, emitsInOrder([
      isA<BachecaAvvisiLoading>(),
      isA<BachecaAvvisiCaricata>().having((s) => s.avvisi, "avvisi", isEmpty),
    ]));
  });

  test("404: Loading poi Errore col messaggio del server", () async
  {
    repo.erroreAvvisi = PartitaNonTrovata(messaggio: "Non trovata");
    bloc.add(const BachecaAvvisiRichiesta());

    await expectLater(bloc.stream, emitsInOrder([isA<BachecaAvvisiLoading>(), erroreCon("Non trovata")]));
  });

  test("403: Loading poi Errore col messaggio del server", () async
  {
    repo.erroreAvvisi = OperazioneRifiutata(messaggio: "Non permesso");
    bloc.add(const BachecaAvvisiRichiesta());

    await expectLater(bloc.stream, emitsInOrder([isA<BachecaAvvisiLoading>(), erroreCon("Non permesso")]));
  });

  test("errore generico: Loading poi Errore col suo messaggio", () async
  {
    repo.erroreAvvisi = ErroreGenericoServer();
    bloc.add(const BachecaAvvisiRichiesta());

    await expectLater(bloc.stream, emitsInOrder([isA<BachecaAvvisiLoading>(), erroreCon(ErroreGenericoServer().messaggio)]));
  });

  test("timeout o rete assente: Loading poi Errore col messaggio generico", () async
  {
    repo.erroreAvvisi = Exception("timeout");
    bloc.add(const BachecaAvvisiRichiesta());

    await expectLater(bloc.stream, emitsInOrder([isA<BachecaAvvisiLoading>(), erroreCon(ErroreGenericoServer().messaggio)]));
  });

  test("una seconda richiesta dopo l'errore ricarica", () async
  {
    repo.erroreAvvisi = ErroreGenericoServer();
    bloc.add(const BachecaAvvisiRichiesta());
    await expectLater(bloc.stream, emitsInOrder([isA<BachecaAvvisiLoading>(), isA<BachecaAvvisiErrore>()]));

    repo.erroreAvvisi = null;
    bloc.add(const BachecaAvvisiRichiesta());

    await expectLater(bloc.stream, emitsInOrder([isA<BachecaAvvisiLoading>(), isA<BachecaAvvisiCaricata>()]));
    expect(repo.chiamateAvvisi, 2);
  });
}
