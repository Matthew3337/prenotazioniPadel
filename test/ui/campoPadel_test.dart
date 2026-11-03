import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thepadel/core/di/depInjection.dart';
import 'package:thepadel/domainLayer/enetity/postoPartita.dart';
import 'package:thepadel/ui/campoPadel.dart';

import '../fake/fakePartitaRepo.dart';
import '../fake/fakePreferenze.dart';
import '../fake/temaDiTest.dart';

void main()
{
  setUpAll(caricaFontDellApp);

  setUp(() async
  {
    await sl.reset();
    await registraPreferenzeDiTest();
  });

  tearDown(() async
  {
    await sl.reset();
  });

  test("telefonoUtenteCorrente legge il telefono salvato al login", ()
  {
    expect(telefonoUtenteCorrente(), "3331234567");
  });

  test("inizialiDi regge i nomi mancanti", ()
  {
    expect(inizialiDi("mario", "rossi"), "MR");
    expect(inizialiDi("Mario", null), "M");
    expect(inizialiDi(null, ""), "");
  });

  group("postiDaDettaglio", ()
  {
    test("il mio posto e Tu, gli altri le iniziali e il campo una C; i liberi in fondo", ()
    {
      final posti = postiDaDettaglio(dettaglioDiTest(posti: [
        PostoPartita(idPosto: 1, tipo: "UTENTE", telefono: "3331234567", nome: "Mario", cognome: "Rossi", livello: 2.5, confermata: false, squadra: null),
        PostoPartita(idPosto: 2, tipo: "UTENTE", telefono: "3335550001", nome: "Luca", cognome: "Bianchi", livello: 3.0, confermata: false, squadra: null),
        PostoPartita(idPosto: 3, tipo: "CAMPO", telefono: null, nome: null, cognome: null, livello: null, confermata: false, squadra: null),
      ]));

      expect(posti.map((p) => p.iniziali).toList(), ["Tu", "LB", "C", ""]);
      expect(posti.map((p) => p.descrizione).toList(), ["Tu", "Luca Bianchi", "Giocatore del campo", "Posto libero"]);
      expect(posti.last.libero, true);
    });

    test("chi ha una squadra sta dal suo lato: prima la squadra 1, poi la 2", ()
    {
      final posti = postiDaDettaglio(dettaglioDiTest(posti: [
        PostoPartita(idPosto: 1, tipo: "UTENTE", telefono: "1", nome: "Anna", cognome: "Verdi", livello: 1, confermata: true, squadra: 2),
        PostoPartita(idPosto: 2, tipo: "UTENTE", telefono: "2", nome: "Luca", cognome: "Bianchi", livello: 1, confermata: true, squadra: 1),
        PostoPartita(idPosto: 3, tipo: "UTENTE", telefono: "3", nome: "Sara", cognome: "Neri", livello: 1, confermata: true, squadra: 2),
        PostoPartita(idPosto: 4, tipo: "UTENTE", telefono: "4", nome: "Elena", cognome: "Gialli", livello: 1, confermata: true, squadra: 1),
      ]));

      expect(posti.map((p) => p.iniziali).toList(), ["LB", "EG", "AV", "SN"]);
    });

    test("conNomi aggiunge i nomi, il campo diventa Del campo", ()
    {
      final posti = postiDaDettaglio(dettaglioDiTest(), conNomi: true);

      expect(posti[0].nome, "Mario");
      expect(posti[1].nome, "Del campo");
    });

    test("con onInvita i posti liberi si toccano e hanno il piu; senza no", ()
    {
      final conInvito = postiDaDettaglio(dettaglioDiTest(), conNomi: true, onInvita: () {});
      expect(conInvito[2].onTap, isNotNull);
      expect(conInvito[2].conPiu, true);
      expect(conInvito[2].nome, "Invita");

      final senzaInvito = postiDaDettaglio(dettaglioDiTest());
      expect(senzaInvito[2].onTap, isNull);
      expect(senzaInvito[2].conPiu, false);
    });

    test("restituisce sempre quattro posti", ()
    {
      expect(postiDaDettaglio(dettaglioConInvitati(0)).length, 4);
      expect(postiDaDettaglio(dettaglioConInvitati(3)).length, 4);
    });
  });

  group("CampoPadel", ()
  {
    Future<void> mostra(WidgetTester tester, Widget campo) async
    {
      await tester.pumpWidget(MaterialApp(theme: temaDiTest(), home: Scaffold(body: campo)));
    }

    testWidgets("disegna i posti con le iniziali e il nome", (tester) async
    {
      await mostra(tester, CampoPadel(altezza: 200, posti: postiDaDettaglio(dettaglioDiTest(), conNomi: true)));

      expect(tester.takeException(), isNull);
      expect(find.text("Tu"), findsOneWidget);
      expect(find.text("Mario"), findsOneWidget);
      expect(find.text("C"), findsOneWidget);
    });

    testWidgets("il tocco sul posto libero chiama l'azione", (tester) async
    {
      int tocchi = 0;
      await mostra(tester, CampoPadel(altezza: 200, posti: postiDaDettaglio(dettaglioConInvitati(2), onInvita: () { tocchi++; })));

      await tester.tap(find.text("+"));
      expect(tocchi, 1);
    });

    testWidgets("senza posti disegna solo il campo", (tester) async
    {
      await mostra(tester, const CampoPadel(altezza: 130, posti: []));

      expect(tester.takeException(), isNull);
    });

    testWidgets("MiniCampo dice quanti posti sono occupati e liberi", (tester) async
    {
      final semantica = tester.ensureSemantics();
      await mostra(tester, const MiniCampo(postiLiberi: 1));

      expect(find.bySemanticsLabel("3 posti occupati, 1 liberi"), findsOneWidget);
      expect(tester.takeException(), isNull);
      semantica.dispose();
    });
  });
}
