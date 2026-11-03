import 'package:flutter_test/flutter_test.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/domainLayer/enetity/postoPartita.dart';
import 'package:thepadel/useCase/bachecaInvitiUseCase.dart';

import '../fake/fakePartitaRepo.dart';

PostoPartita postoUtente(String telefono, {bool confermata = false})
{
  return PostoPartita(idPosto: null, tipo: "UTENTE", telefono: telefono, nome: "Nome", cognome: "Cognome", livello: 2.5, confermata: confermata, squadra: null);
}

void main()
{
  late FakePartitaRepo repo;

  setUp(()
  {
    repo = FakePartitaRepo();
    repo.telefonoUtente = "3330000000";
  });

  group("BachecaInvitiUseCase", ()
  {
    test("restituisce le partite del repository", () async
    {
      repo.partiteInviti = [partitaInvitoDiTest(id: 10), partitaInvitoDiTest(id: 11)];

      final partite = await BachecaInvitiUseCase(repo: repo).call();

      expect(partite.map((p) => p.id).toList(), [10, 11]);
    });
  });

  group("InvitiConStatoUseCase", ()
  {
    test("puoConfermare arriva dalle azioni del dettaglio", () async
    {
      repo.partiteInviti = [partitaInvitoDiTest(id: 10), partitaInvitoDiTest(id: 11)];
      repo.dettagliPerId = {
        10: dettaglioDiTest(id: 10, azioni: azioniDiTest(puoConfermare: true)),
        11: dettaglioDiTest(id: 11, azioni: azioniDiTest()),
      };

      final voci = await InvitiConStatoUseCase(repo: repo).call();

      expect(voci.map((v) => v.partita.id).toList(), [10, 11]);
      expect(voci[0].puoConfermare, true);
      expect(voci[1].puoConfermare, false);
    });

    test("giaConfermato solo se il posto dell'utente e confermato", () async
    {
      repo.partiteInviti = [partitaInvitoDiTest(id: 10), partitaInvitoDiTest(id: 11), partitaInvitoDiTest(id: 12)];
      repo.dettagliPerId = {
        10: dettaglioDiTest(id: 10, posti: [postoUtente("3330000000", confermata: true)]),
        11: dettaglioDiTest(id: 11, posti: [postoUtente("3330000000")]),
        //ha confermato un altro: non conta
        12: dettaglioDiTest(id: 12, posti: [postoUtente("3339999999", confermata: true), postoUtente("3330000000")]),
      };

      final voci = await InvitiConStatoUseCase(repo: repo).call();

      expect(voci.map((v) => v.giaConfermato).toList(), [true, false, false]);
    });

    test("un dettaglio che non arriva non fa perdere la lista: quella voce resta senza azioni", () async
    {
      repo.partiteInviti = [partitaInvitoDiTest(id: 10), partitaInvitoDiTest(id: 11)];
      repo.dettagliPerId = {10: dettaglioDiTest(id: 10, azioni: azioniDiTest(puoConfermare: true))};
      repo.dettagliInErrore = {11};

      final voci = await InvitiConStatoUseCase(repo: repo).call();

      expect(voci.length, 2);
      expect(voci[0].puoConfermare, true);
      expect(voci[1].puoConfermare, false);
      expect(voci[1].giaConfermato, false);
    });

    test("se non arriva la lista l'errore arriva a chi chiama", ()
    {
      repo.erroreInviti = ErroreGenericoServer();

      expect(InvitiConStatoUseCase(repo: repo).call(), throwsA(isA<ErroreGenericoServer>()));
    });
  });
}
