import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thepadel/core/di/depInjection.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/domainLayer/enetity/campo.dart';
import 'package:thepadel/ui/gestioneCampi.dart';
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

  late FakeCampoRepo repo;

  setUp(() async
  {
    await sl.reset();
    await registraPreferenzeDiTest();
    repo = FakeCampoRepo();
    registraBlocDiTest(repoPartita: FakePartitaRepo(), repoCampo: repo, repoPrenotazione: FakePrenotazioneRepo(), repoUtente: FakeUtenteRepo());
  });

  tearDown(() async
  {
    await sl.reset();
  });

  Future<void> apriPagina(WidgetTester tester) async
  {
    tester.view.physicalSize = const Size(390, 844) * 3.0;
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(theme: temaDiTest(), home: const GestioneCampiPage()));
  }

  testWidgets("durante il caricamento mostra lo scheletro", (tester) async
  {
    await apriPagina(tester);

    expect(find.byType(BarraGrigia), findsNWidgets(3));
    expect(find.text("Nuovo campo"), findsNothing);

    await tester.pumpAndSettle();
  });

  testWidgets("mostra nome, orari e copertura di ogni campo", (tester) async
  {
    repo.campi = [
      campoDiTest(id: 1, nome: "Uno", alCoperto: true),
      Campo(id: 2, nome: "Due", alCoperto: false, oraApertura: const TimeOfDay(hour: 10, minute: 30), oraChiusura: const TimeOfDay(hour: 1, minute: 0)),
    ];
    await apriPagina(tester);
    await tester.pumpAndSettle();

    expect(find.text("Uno"), findsOneWidget);
    expect(find.text("09:00 - 23:00"), findsOneWidget);
    expect(find.text("Al coperto"), findsOneWidget);
    expect(find.text("Due"), findsOneWidget);
    expect(find.text("10:30 - 01:00"), findsOneWidget);
    expect(find.text("All'aperto"), findsOneWidget);
    expect(find.text("Nuovo campo"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets("senza campi lo dice e si puo comunque crearne uno", (tester) async
  {
    repo.campi = [];
    await apriPagina(tester);
    await tester.pumpAndSettle();

    expect(find.textContaining("Non ci sono ancora campi"), findsOneWidget);
    expect(find.text("Nuovo campo"), findsOneWidget);
  });

  testWidgets("con tanti campi l'elenco scorre senza overflow", (tester) async
  {
    repo.campi = [for(int i = 1; i <= 12; i++) campoDiTest(id: i, nome: "Campo $i")];
    await apriPagina(tester);
    await tester.pumpAndSettle();

    expect(find.text("Campo 1"), findsOneWidget);
    expect(find.text("Nuovo campo"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets("in errore mostra la card e Riprova ricarica", (tester) async
  {
    repo.erroreCampi = ErroreGenericoServer();
    await apriPagina(tester);
    await tester.pumpAndSettle();

    expect(find.text("Non siamo riusciti a caricare i campi"), findsOneWidget);
    expect(find.text("Nuovo campo"), findsNothing);

    repo.erroreCampi = null;
    await tester.tap(find.text("Riprova"));
    await tester.pumpAndSettle();

    expect(repo.chiamateCampi, 2);
    expect(find.text("Campo Centrale"), findsOneWidget);
  });

  testWidgets("toccare un campo apre il form di modifica con i suoi dati", (tester) async
  {
    await apriPagina(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text("Campo Centrale"));
    await tester.pumpAndSettle();

    expect(find.text("Modifica campo"), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, "Campo Centrale");
  });

  testWidgets("Nuovo campo apre il form vuoto", (tester) async
  {
    await apriPagina(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text("Nuovo campo"));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ElevatedButton, "Salva"), findsOneWidget);
    expect(find.text("Elimina campo"), findsNothing);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, "");
  });
}
