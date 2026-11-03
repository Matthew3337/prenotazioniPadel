import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thepadel/core/di/depInjection.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/ui/bachecaAvvisi.dart';
import 'package:thepadel/ui/dettaglioAdmin.dart';
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
  late FakePartitaRepo repoPartita;

  setUp(() async
  {
    await sl.reset();
    await registraPreferenzeDiTest();
    repo = FakeAdminRepo();
    repoPartita = FakePartitaRepo();
    registraBlocDiTest(repoPartita: repoPartita, repoCampo: FakeCampoRepo(), repoPrenotazione: FakePrenotazioneRepo(), repoUtente: FakeUtenteRepo(), repoAdmin: repo);
  });

  tearDown(() async
  {
    await sl.reset();
  });

  Future<void> apriPagina(WidgetTester tester, {bool aspetta = true}) async
  {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(theme: temaDiTest(), home: const BachecaAvvisiPage()));
    if(aspetta)
    {
      await tester.pumpAndSettle();
    }
  }

  testWidgets("durante il caricamento ci sono le barre grigie", (tester) async
  {
    repo.attesaAvvisi = Completer<void>();
    await apriPagina(tester, aspetta: false);
    await tester.pump();

    expect(find.byType(BarraGrigia), findsNWidgets(3));

    repo.attesaAvvisi!.complete();
    await tester.pumpAndSettle();
  });

  testWidgets("senza avvisi lo dice", (tester) async
  {
    await apriPagina(tester);

    expect(find.text("Bacheca avvisi"), findsOneWidget);
    expect(find.text("Nessun avviso aperto"), findsOneWidget);
  });

  testWidgets("un avviso mostra campo, giorno, orario e posti liberi", (tester) async
  {
    repo.avvisi = [avvisoDiTest(nomeCampo: "Campo Nord", postiLiberi: 1)];
    await apriPagina(tester);

    expect(find.text("Campo Nord"), findsOneWidget);
    expect(find.text("Giovedì 5 novembre, 18:30 - 20:00"), findsOneWidget);
    expect(find.text("1 posto libero"), findsOneWidget);
  });

  testWidgets("mostra un avviso per ogni partita, nell'ordine del server", (tester) async
  {
    repo.avvisi = [avvisoDiTest(id: 1, nomeCampo: "Primo"), avvisoDiTest(id: 2, nomeCampo: "Secondo")];
    await apriPagina(tester);

    expect(tester.getTopLeft(find.text("Primo")).dy, lessThan(tester.getTopLeft(find.text("Secondo")).dy));
  });

  testWidgets("il tocco apre il dettaglio della partita dell'avviso e al ritorno la bacheca si ricarica", (tester) async
  {
    repo.avvisi = [avvisoDiTest(id: 1, idPartita: 42)];
    repoPartita.risposta = dettaglioDiTest(id: 42);
    await apriPagina(tester);

    await tester.tap(find.text("Campo Centrale"));
    await tester.pumpAndSettle();

    expect(find.byType(DettaglioAdminPage), findsOneWidget);
    expect(repoPartita.idRicevuto, 42);

    repo.avvisi = [];
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
    await tester.pumpAndSettle();

    expect(repo.chiamateAvvisi, 2);
    expect(find.text("Nessun avviso aperto"), findsOneWidget);
  });

  testWidgets("errore: messaggio e Riprova ricarica", (tester) async
  {
    repo.erroreAvvisi = ErroreGenericoServer();
    await apriPagina(tester);

    expect(find.text("Non siamo riusciti a caricare gli avvisi"), findsOneWidget);
    expect(find.text(ErroreGenericoServer().messaggio), findsOneWidget);

    repo.erroreAvvisi = null;
    repo.avvisi = [avvisoDiTest()];
    await tester.tap(find.text("Riprova"));
    await tester.pumpAndSettle();

    expect(find.text("Campo Centrale"), findsOneWidget);
    expect(repo.chiamateAvvisi, 2);
  });

  testWidgets("tirando giu la lista si ricarica", (tester) async
  {
    repo.avvisi = [avvisoDiTest()];
    await apriPagina(tester);

    await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();

    expect(repo.chiamateAvvisi, 2);
  });
}
