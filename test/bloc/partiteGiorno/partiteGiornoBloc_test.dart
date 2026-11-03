import 'package:flutter_test/flutter_test.dart';
import 'package:thepadel/bloc/partiteGiorno/partiteGiornoBloc.dart';
import 'package:thepadel/bloc/partiteGiorno/partiteGiornoEvent.dart';
import 'package:thepadel/bloc/partiteGiorno/partiteGiornoState.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/useCase/adminUseCase.dart';

import '../../fake/fakeAdminRepo.dart';

Matcher erroreCon(String messaggio)
{
  return isA<PartiteGiornoErrore>().having((s) => s.messaggio, "messaggio", messaggio);
}

void main()
{
  late FakeAdminRepo repo;
  late PartiteGiornoBloc bloc;
  final data = DateTime(2026, 11, 5);

  setUp(()
  {
    repo = FakeAdminRepo();
    bloc = PartiteGiornoBloc(partiteGiornoUseCase: PartiteGiornoUseCase(repo: repo));
  });

  tearDown(() async
  {
    await bloc.close();
  });

  test("lo stato iniziale e PartiteGiornoInitial", ()
  {
    expect(bloc.state, isA<PartiteGiornoInitial>());
  });

  test("caricamento ok: Loading poi Caricate coi campi della data chiesta", () async
  {
    repo.campi = [campoAdminDiTest(nomeCampo: "A"), campoAdminDiTest(idCampo: 2, nomeCampo: "B", partite: [])];
    bloc.add(PartiteGiornoRichieste(data: data));

    await expectLater(bloc.stream, emitsInOrder([
      isA<PartiteGiornoLoading>(),
      isA<PartiteGiornoCaricate>().having((s) => s.campi.map((c) => c.nomeCampo).toList(), "campi", ["A", "B"]),
    ]));
    expect(repo.dateRicevute, [data]);
  });

  test("404: Loading poi Errore col messaggio del server", () async
  {
    repo.errorePartite = PartitaNonTrovata(messaggio: "Non trovata");
    bloc.add(PartiteGiornoRichieste(data: data));

    await expectLater(bloc.stream, emitsInOrder([isA<PartiteGiornoLoading>(), erroreCon("Non trovata")]));
  });

  test("400 o 403: Loading poi Errore col messaggio del server", () async
  {
    repo.errorePartite = OperazioneRifiutata(messaggio: "Data non valida");
    bloc.add(PartiteGiornoRichieste(data: data));

    await expectLater(bloc.stream, emitsInOrder([isA<PartiteGiornoLoading>(), erroreCon("Data non valida")]));
  });

  test("errore generico: Loading poi Errore col suo messaggio", () async
  {
    repo.errorePartite = ErroreGenericoServer();
    bloc.add(PartiteGiornoRichieste(data: data));

    await expectLater(bloc.stream, emitsInOrder([isA<PartiteGiornoLoading>(), erroreCon(ErroreGenericoServer().messaggio)]));
  });

  test("timeout o rete assente: Loading poi Errore col messaggio generico", () async
  {
    repo.errorePartite = Exception("timeout");
    bloc.add(PartiteGiornoRichieste(data: data));

    await expectLater(bloc.stream, emitsInOrder([isA<PartiteGiornoLoading>(), erroreCon(ErroreGenericoServer().messaggio)]));
  });

  test("una seconda richiesta dopo l'errore ricarica", () async
  {
    repo.errorePartite = ErroreGenericoServer();
    bloc.add(PartiteGiornoRichieste(data: data));
    await expectLater(bloc.stream, emitsInOrder([isA<PartiteGiornoLoading>(), isA<PartiteGiornoErrore>()]));

    repo.errorePartite = null;
    bloc.add(PartiteGiornoRichieste(data: data));

    await expectLater(bloc.stream, emitsInOrder([isA<PartiteGiornoLoading>(), isA<PartiteGiornoCaricate>()]));
    expect(repo.dateRicevute.length, 2);
  });
}
