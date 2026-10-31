import 'package:flutter_test/flutter_test.dart';
import 'package:thepadel/useCase/creaPartitaUseCase.dart';
import 'package:thepadel/useCase/eccezioniUseCase.dart';

import '../fake/fakePrenotazioneRepo.dart';

void main()
{
  late FakePrenotazioneRepo repo;
  late CreaPartitaUseCase useCase;

  setUp(()
  {
    repo = FakePrenotazioneRepo();
    useCase = CreaPartitaUseCase(repo: repo);
  });

  group("CreaPartitaUseCase tipo valido", ()
  {
    test("PUBBLICA passa al repository idCampo e ora dello slot, data e tipo", () async
    {
      final data = DateTime(2026, 11, 2);

      final prenotazione = await useCase.call(slotDiTest(), data, "PUBBLICA");

      expect(prenotazione.id, 10);
      expect(repo.chiamate, 1);
      expect(repo.idCampoRicevuto, 3);
      expect(repo.dataRicevuta, data);
      expect(repo.oraInizioRicevuta, "18:30:00");
      expect(repo.tipoRicevuto, "PUBBLICA");
    });

    test("PRIVATA viene accettato", () async
    {
      final prenotazione = await useCase.call(slotDiTest(), DateTime(2026, 11, 2), "PRIVATA");

      expect(prenotazione.tipo, "PRIVATA");
      expect(repo.tipoRicevuto, "PRIVATA");
    });
  });

  group("CreaPartitaUseCase tipo non valido", ()
  {
    for(final tipo in ["", "pubblica", "ALTRO"])
    {
      test("tipo '$tipo' lancia TipoPartitaMancante senza chiamare il repository", ()
      {
        expect(() => useCase.call(slotDiTest(), DateTime(2026, 11, 2), tipo), throwsA(isA<TipoPartitaMancante>()));
        expect(repo.chiamate, 0);
      });
    }

    test("il messaggio di TipoPartitaMancante e quello mostrato all'utente", ()
    {
      expect(TipoPartitaMancante().message, "scegliere se la partita è pubblica o privata");
    });
  });
}
