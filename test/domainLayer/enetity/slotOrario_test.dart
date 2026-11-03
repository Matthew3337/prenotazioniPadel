import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fake/fakeCampoRepo.dart';

void main()
{
  const apertura = TimeOfDay(hour: 9, minute: 0);

  group("inizio", ()
  {
    test("legge ore e minuti con i secondi", ()
    {
      expect(slotCampoDiTest(oraInizio: "18:30:00").inizio, const TimeOfDay(hour: 18, minute: 30));
    });

    test("legge ore e minuti senza i secondi", ()
    {
      expect(slotCampoDiTest(oraInizio: "07:05").inizio, const TimeOfDay(hour: 7, minute: 5));
    });
  });

  group("inizioEffettivo", ()
  {
    test("uno slot dopo l'apertura cade nel giorno della serata", ()
    {
      final inizio = slotCampoDiTest(oraInizio: "18:30:00").inizioEffettivo(DateTime(2026, 11, 5), apertura);

      expect(inizio, DateTime(2026, 11, 5, 18, 30));
    });

    test("uno slot prima dell'apertura cade nel giorno dopo", ()
    {
      final inizio = slotCampoDiTest(oraInizio: "00:30:00").inizioEffettivo(DateTime(2026, 11, 5), apertura);

      expect(inizio, DateTime(2026, 11, 6, 0, 30));
    });

    test("alla stessa ora dell'apertura contano i minuti", ()
    {
      const aperturaEMezza = TimeOfDay(hour: 9, minute: 30);

      expect(slotCampoDiTest(oraInizio: "09:30:00").inizioEffettivo(DateTime(2026, 11, 5), aperturaEMezza), DateTime(2026, 11, 5, 9, 30));
      expect(slotCampoDiTest(oraInizio: "09:00:00").inizioEffettivo(DateTime(2026, 11, 5), aperturaEMezza), DateTime(2026, 11, 6, 9, 0));
    });

    test("l'ultimo giorno dell'anno passa al primo di quello dopo", ()
    {
      final inizio = slotCampoDiTest(oraInizio: "01:00:00").inizioEffettivo(DateTime(2026, 12, 31), apertura);

      expect(inizio, DateTime(2027, 1, 1, 1, 0));
    });
  });
}
