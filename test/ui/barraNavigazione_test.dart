import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thepadel/core/di/depInjection.dart';
import 'package:thepadel/ui/bachecaInviti.dart';
import 'package:thepadel/ui/bachecaPubbliche.dart';
import 'package:thepadel/ui/barraNavigazione.dart';
import 'package:thepadel/ui/home.dart';
import 'package:thepadel/ui/prenota.dart';

import '../fake/blocDiTest.dart';
import '../fake/fakeCampoRepo.dart';
import '../fake/fakePartitaRepo.dart';
import '../fake/fakePreferenze.dart';
import '../fake/fakePrenotazioneRepo.dart';
import '../fake/fakeUtenteRepo.dart';
import '../fake/temaDiTest.dart';

void main()
{
  setUpAll(caricaFontDellApp);

  setUp(() async
  {
    await sl.reset();
    await registraPreferenzeDiTest();
    registraBlocDiTest(repoPartita: FakePartitaRepo(), repoCampo: FakeCampoRepo(), repoPrenotazione: FakePrenotazioneRepo(), repoUtente: FakeUtenteRepo());
  });

  tearDown(() async
  {
    await sl.reset();
  });

  Future<void> apriBarra(WidgetTester tester, VoceBarra voce) async
  {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(theme: temaDiTest(), home: Scaffold(bottomNavigationBar: BarraNavigazione(voceAttiva: voce))));
  }

  testWidgets("mostra le cinque voci, senza overflow anche sul telefono piu piccolo", (tester) async
  {
    tester.view.physicalSize = const Size(960, 1704);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(theme: temaDiTest(), home: const Scaffold(bottomNavigationBar: BarraNavigazione(voceAttiva: VoceBarra.home))));

    expect(tester.takeException(), isNull);
    for(final voce in ["Home", "Prenota", "Partite", "Storico", "Classifica"])
    {
      expect(find.text(voce), findsOneWidget);
    }
  });

  testWidgets("la voce attiva e in grassetto e le altre no", (tester) async
  {
    await apriBarra(tester, VoceBarra.storico);

    expect(tester.widget<Text>(find.text("Storico")).style?.fontWeight, FontWeight.w700);
    expect(tester.widget<Text>(find.text("Home")).style?.fontWeight, FontWeight.w600);
  });

  testWidgets("toccare la voce attiva non cambia pagina", (tester) async
  {
    await apriBarra(tester, VoceBarra.home);

    await tester.tap(find.text("Home"));
    await tester.pumpAndSettle();

    expect(find.byType(HomePage), findsNothing);
    expect(find.byType(BarraNavigazione), findsOneWidget);
  });

  testWidgets("toccare un'altra voce sostituisce la pagina, senza pagine sotto", (tester) async
  {
    await apriBarra(tester, VoceBarra.home);

    await tester.tap(find.text("Prenota"));
    await tester.pumpAndSettle();

    expect(find.byType(PrenotaPage), findsOneWidget);
    final NavigatorState navigator = tester.state(find.byType(Navigator));
    expect(navigator.canPop(), false);
  });

  group("SchedePartite", ()
  {
    Future<void> apriSchede(WidgetTester tester, {required bool inviti, String? conteggio, bool inCaricamento = false}) async
    {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(MaterialApp(theme: temaDiTest(), home: Scaffold(body: SchedePartite(inviti: inviti, conteggio: conteggio, inCaricamento: inCaricamento))));
    }

    testWidgets("il conteggio c'e solo sulla scheda attiva", (tester) async
    {
      await apriSchede(tester, inviti: true, conteggio: "2 ricevuti");

      expect(find.text("Inviti"), findsOneWidget);
      expect(find.text("Pubbliche"), findsOneWidget);
      expect(find.text("2 ricevuti"), findsOneWidget);
    });

    testWidgets("toccare la scheda spenta apre l'altra bacheca", (tester) async
    {
      await apriSchede(tester, inviti: true);

      await tester.tap(find.text("Pubbliche"));
      await tester.pumpAndSettle();

      expect(find.byType(BachecaPubblichePage), findsOneWidget);
    });

    testWidgets("toccare la scheda attiva non fa nulla", (tester) async
    {
      await apriSchede(tester, inviti: true);

      await tester.tap(find.text("Inviti"));
      await tester.pumpAndSettle();

      expect(find.byType(BachecaInvitiPage), findsNothing);
    });
  });
}
