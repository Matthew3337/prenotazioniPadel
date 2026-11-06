import 'package:flutter_test/flutter_test.dart';
import 'package:thepadel/useCase/creaPartitaUseCase.dart';
import 'package:thepadel/useCase/eccezioniUseCase.dart';

import '../fake/fakeCampoRepo.dart';
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
      expect(TipoPartitaMancante().message, "Scegli se la partita è pubblica o privata");
    });
  });

  group("SlotLiberiDataUseCase", ()
  {
    late FakeCampoRepo repoCampo;
    late SlotLiberiDataUseCase slotLiberi;
    final data = DateTime(2026, 11, 5);

    setUp(()
    {
      repoCampo = FakeCampoRepo();
      slotLiberi = SlotLiberiDataUseCase(repo: repoCampo);
    });

    test("tiene solo gli slot disponibili", () async
    {
      repoCampo.slots = [slotCampoDiTest(oraInizio: "18:00:00", disponibile: false), slotCampoDiTest(oraInizio: "19:00:00")];

      final slots = await slotLiberi.call(data, DateTime(2026, 11, 5, 9, 0));

      expect(slots.map((s) => s.oraInizio).toList(), ["19:00:00"]);
      expect(repoCampo.dateRicevute, [data]);
    });

    test("toglie gli slot gia iniziati, anche quello che inizia proprio adesso", () async
    {
      repoCampo.slots = [slotCampoDiTest(oraInizio: "17:00:00"), slotCampoDiTest(oraInizio: "18:00:00"), slotCampoDiTest(oraInizio: "19:00:00")];

      final slots = await slotLiberi.call(data, DateTime(2026, 11, 5, 18, 0));

      expect(slots.map((s) => s.oraInizio).toList(), ["19:00:00"]);
    });

    test("uno slot dopo mezzanotte va in fondo, campo per campo", () async
    {
      repoCampo.campi = [campoDiTest(id: 1, nome: "Uno"), campoDiTest(id: 2, nome: "Due")];
      repoCampo.slots = [
        slotCampoDiTest(idCampo: 2, nomeCampo: "Due", oraInizio: "20:00:00"),
        slotCampoDiTest(idCampo: 1, nomeCampo: "Uno", oraInizio: "00:30:00"),
        slotCampoDiTest(idCampo: 1, nomeCampo: "Uno", oraInizio: "22:00:00"),
      ];

      final slots = await slotLiberi.call(data, DateTime(2026, 11, 5, 9, 0));

      expect(slots.map((s) => "${s.nomeCampo} ${s.oraInizio}").toList(), ["Uno 22:00:00", "Uno 00:30:00", "Due 20:00:00"]);
    });
  });

  group("CreaPartitaUseCase invitati", ()
  {
    test("senza invitati al repository arriva una lista vuota", () async
    {
      await useCase.call(slotDiTest(), DateTime(2026, 11, 2), "PUBBLICA");

      expect(repo.invitatiRicevuti, isEmpty);
    });

    test("fino a 3 invitati arrivano al repository nell'ordine scelto", () async
    {
      await useCase.call(slotDiTest(), DateTime(2026, 11, 2), "PRIVATA", invitati: ["1", "2", "3"]);

      expect(repo.invitatiRicevuti, ["1", "2", "3"]);
    });

    test("4 invitati lanciano TroppiInvitati senza chiamare il repository", ()
    {
      expect(() => useCase.call(slotDiTest(), DateTime(2026, 11, 2), "PRIVATA", invitati: ["1", "2", "3", "4"]), throwsA(isA<TroppiInvitati>()));
      expect(repo.chiamate, 0);
      expect(TroppiInvitati().message, "Puoi invitare al massimo 3 giocatori");
    });
  });
}
