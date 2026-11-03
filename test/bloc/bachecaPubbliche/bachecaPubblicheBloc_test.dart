import 'package:flutter_test/flutter_test.dart';
import 'package:thepadel/bloc/bachecaPubbliche/bachecaPubblicheBloc.dart';
import 'package:thepadel/bloc/bachecaPubbliche/bachecaPubblicheEvent.dart';
import 'package:thepadel/bloc/bachecaPubbliche/bachecaPubblicheState.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/useCase/bachecaPubblicheUseCase.dart';

import '../../fake/fakePartitaRepo.dart';

Matcher caricataCon(List<int> idPartite)
{
  return isA<BachecaPubblicheCaricata>().having((s) => s.partite.map((p) => p.id).toList(), "id partite", idPartite);
}

void main()
{
  late FakePartitaRepo repo;
  late BachecaPubblicheBloc bloc;

  setUp(()
  {
    repo = FakePartitaRepo();
    repo.partitePubbliche = [partitaPubblicaDiTest(id: 10), partitaPubblicaDiTest(id: 11)];
    bloc = BachecaPubblicheBloc(
      partitePubblicheUseCase: PartitePubblicheUseCase(repo: repo),
      entraInPartitaUseCase: EntraInPartitaUseCase(repo: repo),
    );
  });

  tearDown(() async
  {
    await bloc.close();
  });

  //porta il bloc nello stato Caricata con la lista impostata nel setUp
  Future<void> caricaBacheca() async
  {
    bloc.add(const BachecaPubblicheRichiesta());
    await expectLater(bloc.stream, emitsInOrder([
      isA<BachecaPubblicheLoading>(),
      caricataCon([10, 11]),
    ]));
  }

  test("lo stato iniziale e BachecaPubblicheInitial", ()
  {
    expect(bloc.state, isA<BachecaPubblicheInitial>());
  });

  test("caricamento ok: Loading poi Caricata con le partite", () async
  {
    await caricaBacheca();
    expect(repo.chiamatePubbliche, 1);
  });

  test("caricamento con bacheca vuota: Loading poi Caricata con lista vuota", () async
  {
    repo.partitePubbliche = [];
    bloc.add(const BachecaPubblicheRichiesta());

    await expectLater(bloc.stream, emitsInOrder([
      isA<BachecaPubblicheLoading>(),
      caricataCon([]),
    ]));
  });

  test("errore di caricamento: Loading poi Errore col messaggio di ErroreGenericoServer", () async
  {
    repo.errorePubbliche = ErroreGenericoServer();
    bloc.add(const BachecaPubblicheRichiesta());

    await expectLater(bloc.stream, emitsInOrder([
      isA<BachecaPubblicheLoading>(),
      isA<BachecaPubblicheErrore>().having((s) => s.messaggio, "messaggio", ErroreGenericoServer().messaggio),
    ]));
  });

  test("ingresso riuscito: InCorso poi Riuscito col dettaglio, la lista resta e non si ricarica", () async
  {
    await caricaBacheca();

    bloc.add(const EntraInPartitaRichiesto(idPartita: 10));

    await expectLater(bloc.stream, emitsInOrder([
      isA<IngressoInCorso>()
          .having((s) => s.idPartita, "idPartita", 10)
          .having((s) => s.partite.length, "partite", 2),
      isA<IngressoRiuscito>()
          .having((s) => s.dettaglio.id, "id dettaglio", 10)
          .having((s) => s.partite.length, "partite", 2),
    ]));
    expect(repo.chiamateEntra, 1);
    expect(repo.idEntraRicevuto, 10);
    //la ricarica dopo il successo la chiede la pagina al ritorno dal dettaglio, non il bloc
    expect(repo.chiamatePubbliche, 1);
  });

  test("ingresso 409: InCorso, Errore col messaggio, poi ricarica automatica senza Loading", () async
  {
    await caricaBacheca();

    repo.erroreEntra = IngressoRifiutato(messaggio: "La partita è al completo");
    //la ricarica trova la bacheca aggiornata: la partita piena non c'e piu
    repo.partitePubbliche = [partitaPubblicaDiTest(id: 11)];
    bloc.add(const EntraInPartitaRichiesto(idPartita: 10));

    final stati = <Object>[];
    final sub = bloc.stream.listen(stati.add);
    await expectLater(bloc.stream, emitsInOrder([
      isA<IngressoInCorso>().having((s) => s.idPartita, "idPartita", 10),
      isA<IngressoErrore>()
          .having((s) => s.messaggio, "messaggio", "La partita è al completo")
          .having((s) => s.partite.length, "partite", 2),
      caricataCon([11]),
    ]));
    await sub.cancel();

    //sequenza esatta: nessun BachecaPubblicheLoading in mezzo
    expect(stati.length, 3);
    expect(stati.whereType<BachecaPubblicheLoading>(), isEmpty);
    expect(repo.chiamatePubbliche, 2);
  });

  test("ingresso 404: Errore col messaggio di PartitaNonTrovata e ricarica", () async
  {
    await caricaBacheca();

    repo.erroreEntra = PartitaNonTrovata(messaggio: "Partita non trovata");
    bloc.add(const EntraInPartitaRichiesto(idPartita: 10));

    await expectLater(bloc.stream, emitsInOrder([
      isA<IngressoInCorso>(),
      isA<IngressoErrore>().having((s) => s.messaggio, "messaggio", "Partita non trovata"),
      caricataCon([10, 11]),
    ]));
  });

  test("ingresso con errore generico e ricarica fallita: Errore dell'ingresso poi Errore della bacheca", () async
  {
    await caricaBacheca();

    repo.erroreEntra = ErroreGenericoServer();
    repo.errorePubbliche = ErroreGenericoServer();
    bloc.add(const EntraInPartitaRichiesto(idPartita: 10));

    await expectLater(bloc.stream, emitsInOrder([
      isA<IngressoInCorso>(),
      isA<IngressoErrore>().having((s) => s.messaggio, "messaggio", ErroreGenericoServer().messaggio),
      isA<BachecaPubblicheErrore>().having((s) => s.messaggio, "messaggio", ErroreGenericoServer().messaggio),
    ]));
  });

  test("timeout o rete assente al caricamento: Loading poi Errore col messaggio generico", () async
  {
    repo.errorePubbliche = Exception("timeout");
    bloc.add(const BachecaPubblicheRichiesta());

    await expectLater(bloc.stream, emitsInOrder([
      isA<BachecaPubblicheLoading>(),
      isA<BachecaPubblicheErrore>().having((s) => s.messaggio, "messaggio", ErroreGenericoServer().messaggio),
    ]));
  });

  test("timeout o rete assente all'ingresso: IngressoErrore col messaggio generico, poi la lista ricaricata", () async
  {
    await caricaBacheca();

    repo.erroreEntra = Exception("timeout");
    bloc.add(const EntraInPartitaRichiesto(idPartita: 10));

    await expectLater(bloc.stream, emitsInOrder([
      isA<IngressoInCorso>(),
      isA<IngressoErrore>().having((s) => s.messaggio, "messaggio", ErroreGenericoServer().messaggio),
      caricataCon([10, 11]),
    ]));
  });
}
