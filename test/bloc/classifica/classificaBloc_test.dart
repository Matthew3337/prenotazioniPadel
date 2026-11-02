import 'package:flutter_test/flutter_test.dart';
import 'package:thepadel/bloc/classifica/classificaBloc.dart';
import 'package:thepadel/bloc/classifica/classificaEvent.dart';
import 'package:thepadel/bloc/classifica/classificaState.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/useCase/classificaUseCase.dart';

import '../../fake/fakeUtenteRepo.dart';

Matcher caricataCon(List<String> telefoni)
{
  return isA<ClassificaCaricata>().having((s) => s.voci.map((v) => v.telefono).toList(), "telefoni", telefoni);
}

void main()
{
  late FakeUtenteRepo repo;
  late ClassificaBloc bloc;

  setUp(()
  {
    repo = FakeUtenteRepo();
    repo.voci = [voceDiTest(telefono: "1"), voceDiTest(telefono: "2")];
    bloc = ClassificaBloc(classificaUseCase: ClassificaUseCase(repo: repo));
  });

  tearDown(() async
  {
    await bloc.close();
  });

  test("lo stato iniziale e ClassificaInitial", ()
  {
    expect(bloc.state, isA<ClassificaInitial>());
  });

  test("caricamento ok: Loading poi Caricata con le voci nell'ordine del repository", () async
  {
    bloc.add(const ClassificaRichiesta());

    await expectLater(bloc.stream, emitsInOrder([
      isA<ClassificaLoading>(),
      caricataCon(["1", "2"]),
    ]));
    expect(repo.chiamate, 1);
  });

  test("classifica vuota: Loading poi Caricata con lista vuota", () async
  {
    repo.voci = [];
    bloc.add(const ClassificaRichiesta());

    await expectLater(bloc.stream, emitsInOrder([
      isA<ClassificaLoading>(),
      caricataCon([]),
    ]));
  });

  test("errore: Loading poi Errore col messaggio di ErroreGenericoServer", () async
  {
    repo.errore = ErroreGenericoServer();
    bloc.add(const ClassificaRichiesta());

    await expectLater(bloc.stream, emitsInOrder([
      isA<ClassificaLoading>(),
      isA<ClassificaErrore>().having((s) => s.messaggio, "messaggio", ErroreGenericoServer().messaggio),
    ]));
  });

  test("una seconda richiesta dopo l'errore ricarica la classifica", () async
  {
    repo.errore = ErroreGenericoServer();
    bloc.add(const ClassificaRichiesta());
    await expectLater(bloc.stream, emitsInOrder([isA<ClassificaLoading>(), isA<ClassificaErrore>()]));

    repo.errore = null;
    bloc.add(const ClassificaRichiesta());

    await expectLater(bloc.stream, emitsInOrder([
      isA<ClassificaLoading>(),
      caricataCon(["1", "2"]),
    ]));
    expect(repo.chiamate, 2);
  });
}
