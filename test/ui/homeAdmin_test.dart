import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thepadel/core/di/depInjection.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/ui/bachecaAvvisi.dart';
import 'package:thepadel/ui/bottoneEsci.dart';
import 'package:thepadel/ui/gestioneLivelli.dart';
import 'package:thepadel/ui/homeAdmin.dart';
import 'package:thepadel/ui/partiteGiorno.dart';
import 'package:thepadel/ui/stileApp.dart';

import '../fake/blocDiTest.dart';
import '../fake/fakeAdminRepo.dart';
import '../fake/fakeCampoRepo.dart';
import '../fake/fakePartitaRepo.dart';
import '../fake/fakePreferenze.dart';
import '../fake/fakePrenotazioneRepo.dart';
import '../fake/fakeUtenteRepo.dart';
import '../fake/temaDiTest.dart';

void main()
{
  setUpAll(caricaFontDellApp);

  late FakeAdminRepo repo;

  setUp(() async
  {
    await sl.reset();
    await registraPreferenzeDiTest();
    repo = FakeAdminRepo();
    registraBlocDiTest(repoPartita: FakePartitaRepo(), repoCampo: FakeCampoRepo(), repoPrenotazione: FakePrenotazioneRepo(), repoUtente: FakeUtenteRepo(), repoAdmin: repo);
  });

  tearDown(() async
  {
    await sl.reset();
  });

  Future<void> apriPagina(WidgetTester tester, {Size schermo = const Size(390, 844), bool aspetta = true}) async
  {
    tester.view.physicalSize = schermo * 3.0;
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(theme: temaDiTest(), home: const HomeAdminPage()));
    if(aspetta)
    {
      await tester.pumpAndSettle();
    }
  }

  void chiudiPaginaInCima(WidgetTester tester)
  {
    final NavigatorState navigator = tester.state(find.byType(Navigator).first);
    navigator.pop();
  }

  testWidgets("mostra le tre voci e il bottone Esci", (tester) async
  {
    await apriPagina(tester);

    expect(find.text("Area amministratore"), findsOneWidget);
    expect(find.text("Partite del giorno"), findsOneWidget);
    expect(find.text("Bacheca avvisi"), findsOneWidget);
    expect(find.text("Gestione livelli"), findsOneWidget);
    expect(find.byType(BottoneEsci), findsOneWidget);
  });

  testWidgets("su un telefono piccolo non va in overflow", (tester) async
  {
    await apriPagina(tester, schermo: const Size(320, 568));

    expect(tester.takeException(), isNull);
  });

  group("saluto", ()
  {
    testWidgets("col nome salvato al login", (tester) async
    {
      await sl<SharedPreferences>().setString("nome", "Paola");
      await apriPagina(tester);

      expect(find.text("Ciao, Paola"), findsOneWidget);
    });

    testWidgets("senza nome salvato resta Ciao", (tester) async
    {
      await apriPagina(tester);

      expect(find.text("Ciao"), findsOneWidget);
    });
  });

  group("numero di avvisi", ()
  {
    testWidgets("nessun avviso", (tester) async
    {
      await apriPagina(tester);

      expect(find.text("Nessun avviso aperto"), findsOneWidget);
      expect(repo.chiamateAvvisi, 1);
    });

    testWidgets("un avviso, al singolare", (tester) async
    {
      repo.avvisi = [avvisoDiTest()];
      await apriPagina(tester);

      expect(find.text("1 avviso aperto"), findsOneWidget);
    });

    testWidgets("piu avvisi, al plurale", (tester) async
    {
      repo.avvisi = [avvisoDiTest(id: 1), avvisoDiTest(id: 2), avvisoDiTest(id: 3)];
      await apriPagina(tester);

      expect(find.text("3 avvisi aperti"), findsOneWidget);
    });

    testWidgets("durante il caricamento c'e la barra grigia", (tester) async
    {
      repo.attesaAvvisi = Completer<void>();
      await apriPagina(tester, aspetta: false);
      await tester.pump();

      expect(find.byType(BarraGrigia), findsOneWidget);
      expect(find.text("Nessun avviso aperto"), findsNothing);

      repo.attesaAvvisi!.complete();
      await tester.pumpAndSettle();
      expect(find.byType(BarraGrigia), findsNothing);
    });

    testWidgets("in errore lo dice e la voce resta apribile", (tester) async
    {
      repo.erroreAvvisi = ErroreGenericoServer();
      await apriPagina(tester);

      expect(find.text("Numero di avvisi non disponibile"), findsOneWidget);

      await tester.tap(find.text("Bacheca avvisi"));
      await tester.pumpAndSettle();

      expect(find.byType(BachecaAvvisiPage), findsOneWidget);
    });
  });

  group("navigazione", ()
  {
    testWidgets("Partite del giorno apre la sua pagina", (tester) async
    {
      await apriPagina(tester);

      await tester.tap(find.text("Partite del giorno"));
      await tester.pumpAndSettle();

      expect(find.byType(PartiteGiornoPage), findsOneWidget);
    });

    testWidgets("Bacheca avvisi apre la sua pagina", (tester) async
    {
      await apriPagina(tester);

      await tester.tap(find.text("Bacheca avvisi"));
      await tester.pumpAndSettle();

      expect(find.byType(BachecaAvvisiPage), findsOneWidget);
    });

    testWidgets("Gestione livelli apre la sua pagina", (tester) async
    {
      await apriPagina(tester);

      await tester.tap(find.text("Gestione livelli"));
      await tester.pumpAndSettle();

      expect(find.byType(GestioneLivelliPage), findsOneWidget);
    });

    testWidgets("al ritorno da una pagina il numero di avvisi viene richiesto di nuovo", (tester) async
    {
      repo.avvisi = [avvisoDiTest(id: 1), avvisoDiTest(id: 2)];
      await apriPagina(tester);
      expect(find.text("2 avvisi aperti"), findsOneWidget);

      await tester.tap(find.text("Gestione livelli"));
      await tester.pumpAndSettle();

      repo.avvisi = [avvisoDiTest(id: 1)];
      chiudiPaginaInCima(tester);
      await tester.pumpAndSettle();

      expect(repo.chiamateAvvisi, 2);
      expect(find.text("1 avviso aperto"), findsOneWidget);
    });
  });
}
