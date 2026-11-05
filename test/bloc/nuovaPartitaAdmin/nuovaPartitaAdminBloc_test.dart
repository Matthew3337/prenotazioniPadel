import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:thepadel/bloc/nuovaPartitaAdmin/nuovaPartitaAdminBloc.dart';
import 'package:thepadel/bloc/nuovaPartitaAdmin/nuovaPartitaAdminEvent.dart';
import 'package:thepadel/bloc/nuovaPartitaAdmin/nuovaPartitaAdminState.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/useCase/adminUseCase.dart';
import 'package:thepadel/useCase/eccezioniUseCase.dart';

import '../../fake/fakeAdminRepo.dart';
import '../../fake/fakePartitaRepo.dart';

void main()
{
  late FakeAdminRepo repo;
  late NuovaPartitaAdminBloc bloc;
  final data = DateTime(2026, 11, 5);

  CreaPartitaAdminRichiesta evento({List<String> telefoni = const ["3335550001"], int giocatoriCampo = 1})
  {
    return CreaPartitaAdminRichiesta(idCampo: 1, data: data, oraInizio: "18:00:00", tipo: "PUBBLICA", telefoni: telefoni, giocatoriCampo: giocatoriCampo);
  }

  setUp(()
  {
    repo = FakeAdminRepo();
    bloc = NuovaPartitaAdminBloc(creaPartitaAdminUseCase: CreaPartitaAdminUseCase(repo: repo));
  });

  tearDown(() async
  {
    await bloc.close();
  });

  test("lo stato iniziale e NuovaPartitaAdminInitial", ()
  {
    expect(bloc.state, isA<NuovaPartitaAdminInitial>());
  });

  test("ok: Loading poi Creata col dettaglio, i dati arrivano al repository", () async
  {
    repo.rispostaCreaPartita = dettaglioDiTest(id: 33);

    bloc.add(evento());

    await expectLater(bloc.stream, emitsInOrder([
      isA<NuovaPartitaAdminLoading>(),
      isA<PartitaAdminCreata>().having((s) => s.dettaglio.id, "id", 33),
    ]));
    expect(repo.idCampoCreaRicevuto, 1);
    expect(repo.dataCreaRicevuta, data);
    expect(repo.oraCreaRicevuta, "18:00:00");
    expect(repo.tipoCreaRicevuto, "PUBBLICA");
    expect(repo.telefoniCreaRicevuti, ["3335550001"]);
    expect(repo.giocatoriCampoCreaRicevuti, 1);
  });

  test("senza utenti: errore senza chiamare il server", () async
  {
    bloc.add(evento(telefoni: []));

    await expectLater(bloc.stream, emitsInOrder([
      isA<NuovaPartitaAdminLoading>(),
      isA<NuovaPartitaAdminErrore>().having((s) => s.messaggio, "messaggio", PartecipantiMancanti().message),
    ]));
    expect(repo.chiamateCreaPartita, 0);
  });

  test("troppi posti: errore senza chiamare il server", () async
  {
    bloc.add(evento(telefoni: ["1", "2"], giocatoriCampo: 3));

    await expectLater(bloc.stream, emitsInOrder([
      isA<NuovaPartitaAdminLoading>(),
      isA<NuovaPartitaAdminErrore>().having((s) => s.messaggio, "messaggio", TroppiPartecipanti().message),
    ]));
    expect(repo.chiamateCreaPartita, 0);
  });

  final errori = <String, Exception Function()>{
    "404": () => PartitaNonTrovata(messaggio: "Utente non trovato"),
    "409": () => OperazioneRifiutata(messaggio: "Slot occupato"),
    "generico": () => ErroreGenericoServer(),
    "rete": () => TimeoutException("timeout"),
  };
  final messaggi = <String, String>{
    "404": "Utente non trovato",
    "409": "Slot occupato",
    "generico": ErroreGenericoServer().messaggio,
    "rete": ErroreGenericoServer().messaggio,
  };

  errori.forEach((nome, errore)
  {
    test("errore $nome: Errore col messaggio", () async
    {
      repo.erroreCreaPartita = errore();

      bloc.add(evento());

      await expectLater(bloc.stream, emitsInOrder([
        isA<NuovaPartitaAdminLoading>(),
        isA<NuovaPartitaAdminErrore>().having((s) => s.messaggio, "messaggio", messaggi[nome]),
      ]));
    });
  });
}
