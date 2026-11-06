import 'package:flutter_test/flutter_test.dart';
import 'package:thepadel/useCase/dettaglioPartitaUseCase.dart';
import 'package:thepadel/useCase/eccezioniUseCase.dart';
import 'package:thepadel/useCase/invitaUtentiUseCase.dart';
import 'package:thepadel/useCase/miePartiteUseCase.dart';

import '../fake/fakePartitaRepo.dart';

void main()
{
  late FakePartitaRepo repo;

  setUp(()
  {
    repo = FakePartitaRepo();
  });

  group("CambiaTipoUseCase", ()
  {
    for(final tipo in ["PUBBLICA", "PRIVATA"])
    {
      test("$tipo arriva al repository con l'id", () async
      {
        await CambiaTipoUseCase(repo: repo).call(7, tipo);

        expect(repo.chiamateCambiaTipo, 1);
        expect(repo.idCambiaTipoRicevuto, 7);
        expect(repo.tipoRicevuto, tipo);
      });
    }

    for(final tipo in ["", "pubblica", "ALTRO"])
    {
      test("tipo '$tipo' lancia TipoPartitaMancante senza chiamare il repository", ()
      {
        expect(() => CambiaTipoUseCase(repo: repo).call(7, tipo), throwsA(isA<TipoPartitaMancante>()));
        expect(repo.chiamateCambiaTipo, 0);
      });
    }
  });

  test("UtentiInvitabiliUseCase passa il testo cercato al repository", () async
  {
    final utenti = await UtentiInvitabiliUseCase(repo: repo).call("anna");

    expect(repo.cercaUtentiRicevuti, ["anna"]);
    expect(utenti.length, 2);
  });

  test("MiePartiteUseCase restituisce le partite del repository", () async
  {
    repo.partiteMie = [partitaStoricoDiTest(id: 5)];

    final partite = await MiePartiteUseCase(repo: repo).call();

    expect(partite.map((p) => p.id).toList(), [5]);
    expect(repo.chiamateMie, 1);
  });
}
