import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/useCase/homeUseCase.dart';

import '../fake/fakeCampoRepo.dart';
import '../fake/fakePrenotazioneRepo.dart';

void main()
{
  group("ProssimaPartitaUseCase", ()
  {
    test("restituisce la prossima partita, null se non c'e", () async
    {
      final repo = FakePrenotazioneRepo();
      final useCase = ProssimaPartitaUseCase(repo: repo);

      expect(await useCase.call(), isNull);

      repo.prossima = prenotazioneDiTest();
      expect((await useCase.call())!.id, 10);
    });
  });

  group("SlotDisponibiliUseCase", ()
  {
    test("passa la data al repository", () async
    {
      final repo = FakeCampoRepo();
      final data = DateTime(2026, 11, 5);

      final slots = await SlotDisponibiliUseCase(repo: repo).call(data);

      expect(slots.length, 1);
      expect(repo.dateRicevute, [data]);
    });
  });

  group("SlotOggiUseCase", ()
  {
    late FakeCampoRepo repo;
    late SlotOggiUseCase useCase;
    final adesso = DateTime(2026, 11, 5, 18, 0);

    setUp(()
    {
      repo = FakeCampoRepo();
      useCase = SlotOggiUseCase(repo: repo);
    });

    test("toglie gli slot gia iniziati e tiene quello che inizia adesso", () async
    {
      repo.slots = [
        slotCampoDiTest(oraInizio: "17:59:00"),
        slotCampoDiTest(oraInizio: "18:00:00"),
        slotCampoDiTest(oraInizio: "19:00:00"),
      ];

      final slots = await useCase.call(adesso);

      expect(slots.map((s) => s.oraInizio).toList(), ["18:00:00", "19:00:00"]);
    });

    test("tiene anche gli slot occupati", () async
    {
      repo.slots = [slotCampoDiTest(oraInizio: "19:00:00", disponibile: false)];

      final slots = await useCase.call(adesso);

      expect(slots.length, 1);
      expect(slots.first.disponibile, false);
    });

    test("uno slot dopo mezzanotte non e passato e va in fondo al suo campo", () async
    {
      repo.slots = [
        slotCampoDiTest(oraInizio: "00:30:00"),
        slotCampoDiTest(oraInizio: "22:00:00"),
      ];

      final slots = await useCase.call(adesso);

      expect(slots.map((s) => s.oraInizio).toList(), ["22:00:00", "00:30:00"]);
    });

    test("gli slot restano raggruppati nell'ordine dei campi", () async
    {
      repo.campi = [campoDiTest(id: 1, nome: "Uno"), campoDiTest(id: 2, nome: "Due")];
      repo.slots = [
        slotCampoDiTest(idCampo: 2, nomeCampo: "Due", oraInizio: "19:00:00"),
        slotCampoDiTest(idCampo: 1, nomeCampo: "Uno", oraInizio: "20:00:00"),
      ];

      final slots = await useCase.call(adesso);

      expect(slots.map((s) => s.nomeCampo).toList(), ["Uno", "Due"]);
    });

    test("l'orario di apertura e quello del campo dello slot", () async
    {
      repo.campi = [campoDiTest(oraApertura: const TimeOfDay(hour: 0, minute: 0))];
      repo.slots = [slotCampoDiTest(oraInizio: "00:30:00")];

      //con il campo aperto da mezzanotte le 00:30 sono di oggi, quindi gia passate
      expect(await useCase.call(adesso), isEmpty);
    });

    test("l'errore del repository arriva a chi chiama", ()
    {
      repo.erroreSlot = ErroreGenericoServer();

      expect(useCase.call(adesso), throwsA(isA<ErroreGenericoServer>()));
    });
  });
}
