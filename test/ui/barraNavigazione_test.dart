import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thepadel/core/di/depInjection.dart';
import 'package:thepadel/ui/bachecaInviti.dart';
import 'package:thepadel/ui/bachecaPubbliche.dart';
import 'package:thepadel/ui/barraNavigazione.dart';
import 'package:thepadel/ui/home.dart';
import 'package:thepadel/ui/miePartite.dart';
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

  testWidgets("mostra le sei voci, senza overflow anche sul telefono piu piccolo (320 px)", (tester) async
  {
    tester.view.physicalSize = const Size(960, 1704);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    for(final attiva in VoceBarra.values)
    {
      await tester.pumpWidget(MaterialApp(theme: temaDiTest(), home: Scaffold(bottomNavigationBar: BarraNavigazione(voceAttiva: attiva))));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      for(final voce in ["Home", "Prenota", "Partite", "Bacheca", "Storico", "Classifica"])
      {
        expect(find.text(voce), findsOneWidget);
      }
    }
  });

  testWidgets("la barra e staccata dai bordi dello schermo", (tester) async
  {
    tester.view.physicalSize = const Size(960, 1704);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(theme: temaDiTest(), home: const Scaffold(bottomNavigationBar: BarraNavigazione(voceAttiva: VoceBarra.home))));
    await tester.pumpAndSettle();

    final home = tester.getTopLeft(find.text("Home"));
    final classifica = tester.getTopRight(find.text("Classifica"));
    expect(home.dx, greaterThan(8));
    expect(classifica.dx, lessThan(320 - 8));
  });

  //il rettangolo bianco arrotondato della barra
  Rect rettangoloBarra(WidgetTester tester)
  {
    final contenitore = find.descendant(
      of: find.byType(BarraNavigazione),
      matching: find.byWidgetPredicate((w) => w is Container && w.decoration is BoxDecoration && (w.decoration as BoxDecoration).borderRadius == BorderRadius.circular(24)),
    );
    return tester.getRect(contenitore.first);
  }

  final schermi = <String, Size>{"telefono piccolo (320 px)": const Size(960, 1704), "telefono normale (390 px)": const Size(1170, 2532)};

  schermi.forEach((nome, dimensione)
  {
    testWidgets("$nome: la distanza dal bordo basso e uguale a quella dai lati", (tester) async
    {
      tester.view.physicalSize = dimensione;
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(MaterialApp(theme: temaDiTest(), home: const Scaffold(bottomNavigationBar: BarraNavigazione(voceAttiva: VoceBarra.home))));
      await tester.pumpAndSettle();

      final barra = rettangoloBarra(tester);
      final double larghezza = dimensione.width / 3;
      final double altezza = dimensione.height / 3;
      final double sinistra = barra.left;
      final double destra = larghezza - barra.right;
      final double basso = altezza - barra.bottom;

      expect(sinistra, greaterThan(0));
      expect(destra, sinistra);
      expect(basso, sinistra);
    });
  });

  testWidgets("anche con la barra della home di iPhone la distanza in basso resta quella dei lati", (tester) async
  {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    tester.view.padding = const FakeViewPadding(bottom: 34 * 3);
    tester.view.viewPadding = const FakeViewPadding(bottom: 34 * 3);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(theme: temaDiTest(), home: const Scaffold(bottomNavigationBar: BarraNavigazione(voceAttiva: VoceBarra.home))));
    await tester.pumpAndSettle();

    final barra = rettangoloBarra(tester);
    expect(844 - barra.bottom, barra.left);
  });

  testWidgets("la voce attiva ha sopra il cerchio di vetro, fatto con BackdropFilter", (tester) async
  {
    await apriBarra(tester, VoceBarra.classifica);
    await tester.pumpAndSettle();

    expect(find.descendant(of: find.byType(BarraNavigazione), matching: find.byType(BackdropFilter)), findsOneWidget);
  });

  final pagine = <String, Type>{
    "Partite": MiePartitePage,
    "Bacheca": BachecaPubblichePage,
  };
  for(final voce in pagine.entries)
  {
    testWidgets("la voce ${voce.key} apre ${voce.value}", (tester) async
    {
      await apriBarra(tester, VoceBarra.home);

      await tester.tap(find.text(voce.key));
      await tester.pumpAndSettle();

      expect(find.byType(voce.value), findsOneWidget);
    });
  }

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
