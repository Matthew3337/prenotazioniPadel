import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thepadel/core/di/depInjection.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/ui/bachecaPubbliche.dart';
import 'package:thepadel/ui/dettaglioPartita.dart';
import 'package:thepadel/ui/miePartite.dart';
import 'package:thepadel/ui/prenota.dart';
import 'package:thepadel/ui/stileApp.dart';

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

  late FakePartitaRepo repo;

  final adesso = DateTime.now();
  final domani = DateTime(adesso.year, adesso.month, adesso.day + 1);
  final traTreGiorni = DateTime(adesso.year, adesso.month, adesso.day + 3);

  setUp(() async
  {
    await sl.reset();
    await registraPreferenzeDiTest();
    repo = FakePartitaRepo();
    registraBlocDiTest(repoPartita: repo, repoCampo: FakeCampoRepo(), repoPrenotazione: FakePrenotazioneRepo(), repoUtente: FakeUtenteRepo());
  });

  tearDown(() async
  {
    await sl.reset();
  });

  Future<void> apriPagina(WidgetTester tester, {Size schermo = const Size(390, 844)}) async
  {
    tester.view.physicalSize = schermo * 3.0;
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(theme: temaDiTest(), home: const MiePartitePage()));
    await tester.pumpAndSettle();
  }

  testWidgets("mostra le partite in programma nell'ordine del server, con data, orario, campo e stato", (tester) async
  {
    repo.partiteMie = [
      partitaStoricoDiTest(id: 10, nomeCampo: "Campo Uno", dataPartita: domani, stato: "creata"),
      partitaStoricoDiTest(id: 11, nomeCampo: "Campo Due", dataPartita: traTreGiorni, stato: "confermata"),
    ];
    await apriPagina(tester);

    expect(repo.chiamateMie, 1);
    expect(repo.chiamateStorico, 0);
    expect(find.text("Le mie partite"), findsOneWidget);
    expect(find.text(conMaiuscola(dataEstesa(domani))), findsOneWidget);
    expect(find.text(conMaiuscola(dataEstesa(traTreGiorni))), findsOneWidget);
    expect(find.text("18:30 - 20:00 · Campo Uno"), findsOneWidget);
    expect(find.text("18:30 - 20:00 · Campo Due"), findsOneWidget);
    expect(find.text("Creata"), findsOneWidget);
    expect(find.text("Confermata"), findsOneWidget);
    expect(tester.getTopLeft(find.text("18:30 - 20:00 · Campo Uno")).dy, lessThan(tester.getTopLeft(find.text("18:30 - 20:00 · Campo Due")).dy));
  });

  testWidgets("la voce Partite della barra e attiva: toccarla non ricarica", (tester) async
  {
    await apriPagina(tester);

    await tester.tap(find.text("Partite"));
    await tester.pumpAndSettle();

    expect(repo.chiamateMie, 1);
    expect(find.byType(MiePartitePage), findsOneWidget);
  });

  testWidgets("il tocco su una riga apre il dettaglio e al ritorno la pagina si ricarica", (tester) async
  {
    repo.partiteMie = [partitaStoricoDiTest(id: 77, dataPartita: domani)];
    await apriPagina(tester);

    await tester.tap(find.text("18:30 - 20:00 · Campo Centrale"));
    await tester.pumpAndSettle();
    expect(find.byType(DettaglioPartitaPage), findsOneWidget);
    expect(repo.idRicevuto, 77);

    final NavigatorState navigator = tester.state(find.byType(Navigator));
    navigator.pop();
    await tester.pumpAndSettle();

    expect(find.byType(MiePartitePage), findsOneWidget);
    expect(repo.chiamateMie, 2);
  });

  testWidgets("nessuna partita: lo dice e propone le due strade", (tester) async
  {
    repo.partiteMie = [];
    await apriPagina(tester);

    expect(find.text("Non hai partite in programma"), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, "Prenota un campo"), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, "Trova una partita"), findsOneWidget);
  });

  testWidgets("senza partite, Prenota un campo apre il tabellone", (tester) async
  {
    repo.partiteMie = [];
    await apriPagina(tester);

    await tester.tap(find.text("Prenota un campo"));
    await tester.pumpAndSettle();

    expect(find.byType(PrenotaPage), findsOneWidget);
    expect(find.byType(MiePartitePage), findsNothing);
  });

  testWidgets("senza partite, Trova una partita apre la bacheca", (tester) async
  {
    repo.partiteMie = [];
    await apriPagina(tester);

    await tester.tap(find.text("Trova una partita"));
    await tester.pumpAndSettle();

    expect(find.byType(BachecaPubblichePage), findsOneWidget);
  });

  testWidgets("errore di caricamento: messaggio e Riprova rifa la richiesta", (tester) async
  {
    repo.erroreMie = ErroreGenericoServer();
    await apriPagina(tester);

    expect(find.text("Non siamo riusciti a caricare le tue partite"), findsOneWidget);
    expect(find.text(ErroreGenericoServer().messaggio), findsOneWidget);

    repo.erroreMie = null;
    repo.partiteMie = [partitaStoricoDiTest(dataPartita: domani)];
    await tester.tap(find.text("Riprova"));
    await tester.pumpAndSettle();

    expect(repo.chiamateMie, 2);
    expect(find.text("18:30 - 20:00 · Campo Centrale"), findsOneWidget);
  });

  testWidgets("pull-to-refresh rifa la richiesta", (tester) async
  {
    repo.partiteMie = [partitaStoricoDiTest(dataPartita: domani)];
    await apriPagina(tester);

    await tester.fling(find.text("Le mie partite"), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();

    expect(repo.chiamateMie, 2);
  });

  testWidgets("su un telefono piccolo con un campo dal nome lungo non va in overflow", (tester) async
  {
    repo.partiteMie = [partitaStoricoDiTest(nomeCampo: "Campo con un nome davvero lunghissimo", dataPartita: domani, stato: "confermata")];
    await apriPagina(tester, schermo: const Size(320, 568));

    expect(tester.takeException(), isNull);
  });
}
