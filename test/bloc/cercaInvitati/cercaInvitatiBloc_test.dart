import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:thepadel/bloc/cercaInvitati/cercaInvitatiBloc.dart';
import 'package:thepadel/bloc/cercaInvitati/cercaInvitatiEvent.dart';
import 'package:thepadel/bloc/cercaInvitati/cercaInvitatiState.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/domainLayer/enetity/utenteInvitabile.dart';
import 'package:thepadel/useCase/invitaUtentiUseCase.dart';

import '../../fake/fakePartitaRepo.dart';

//repository che risponde a ogni ricerca solo quando il test lo decide
class RepoConAttese extends FakePartitaRepo
{
  final Map<String, Completer<List<UtenteInvitabile>>> attese = {};

  @override
  Future<List<UtenteInvitabile>> getUtentiInvitabili(String cerca)
  {
    cercaUtentiRicevuti.add(cerca);
    attese[cerca] = Completer<List<UtenteInvitabile>>();
    return attese[cerca]!.future;
  }
}

void main()
{
  late FakePartitaRepo repo;
  late CercaInvitatiBloc bloc;

  setUp(()
  {
    repo = FakePartitaRepo();
    bloc = CercaInvitatiBloc(utentiInvitabiliUseCase: UtentiInvitabiliUseCase(repo: repo));
  });

  tearDown(() async
  {
    await bloc.close();
  });

  test("lo stato iniziale e CercaInvitatiInitial", ()
  {
    expect(bloc.state, isA<CercaInvitatiInitial>());
  });

  test("ricerca ok: Loading poi Caricati, il testo arriva al repository", () async
  {
    bloc.add(const CercaInvitatiRichiesta(cerca: "luca"));

    await expectLater(bloc.stream, emitsInOrder([
      isA<CercaInvitatiLoading>(),
      isA<CercaInvitatiCaricati>().having((s) => s.utenti.map((u) => u.telefono).toList(), "telefoni", ["3335550001", "3335550002"]),
    ]));
    expect(repo.cercaUtentiRicevuti, ["luca"]);
    //non serve nessuna partita: non si passa dagli invitabili della partita
    expect(repo.chiamateInvitabili, 0);
  });

  test("nessun utente trovato: Caricati con lista vuota", () async
  {
    repo.utentiInvitabili = [];
    bloc.add(const CercaInvitatiRichiesta(cerca: "zzz"));

    await expectLater(bloc.stream, emitsInOrder([
      isA<CercaInvitatiLoading>(),
      isA<CercaInvitatiCaricati>().having((s) => s.utenti, "utenti", isEmpty),
    ]));
  });

  test("ErroreGenericoServer: Errore col suo messaggio", () async
  {
    repo.erroreUtentiInvitabili = ErroreGenericoServer();
    bloc.add(const CercaInvitatiRichiesta(cerca: ""));

    await expectLater(bloc.stream, emitsInOrder([
      isA<CercaInvitatiLoading>(),
      isA<CercaInvitatiErrore>().having((s) => s.messaggio, "messaggio", ErroreGenericoServer().messaggio),
    ]));
  });

  test("timeout o rete assente: Errore col messaggio generico", () async
  {
    repo.erroreUtentiInvitabili = Exception("timeout");
    bloc.add(const CercaInvitatiRichiesta(cerca: ""));

    await expectLater(bloc.stream, emitsInOrder([
      isA<CercaInvitatiLoading>(),
      isA<CercaInvitatiErrore>().having((s) => s.messaggio, "messaggio", ErroreGenericoServer().messaggio),
    ]));
  });

  test("la risposta di una ricerca vecchia che arriva dopo quella nuova viene ignorata", () async
  {
    final repoLento = RepoConAttese();
    final blocLento = CercaInvitatiBloc(utentiInvitabiliUseCase: UtentiInvitabiliUseCase(repo: repoLento));
    final stati = <CercaInvitatiState>[];
    final ascolto = blocLento.stream.listen(stati.add);

    blocLento.add(const CercaInvitatiRichiesta(cerca: "lu"));
    await Future<void>.delayed(Duration.zero);
    blocLento.add(const CercaInvitatiRichiesta(cerca: "luca"));
    await Future<void>.delayed(Duration.zero);

    repoLento.attese["luca"]!.complete([utenteInvitabileDiTest()]);
    await Future<void>.delayed(Duration.zero);
    repoLento.attese["lu"]!.complete([utenteInvitabileDiTest(), utenteInvitabileDiTest(telefono: "3335550002")]);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await ascolto.cancel();
    await blocLento.close();

    final caricati = stati.whereType<CercaInvitatiCaricati>().toList();
    expect(caricati.length, 1);
    expect(caricati.single.utenti.length, 1);
    expect(blocLento.state, isA<CercaInvitatiCaricati>());
  });
}
