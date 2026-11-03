import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thepadel/core/di/depInjection.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/domainLayer/enetity/setPartita.dart';
import 'package:thepadel/ui/dettaglioAdmin.dart';
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
  late FakePartitaRepo repoPartita;

  DateTime oggi()
  {
    final adesso = DateTime.now();
    return DateTime(adesso.year, adesso.month, adesso.day);
  }

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

    await tester.pumpWidget(MaterialApp(theme: temaDiTest(), home: const PartiteGiornoPage()));
    if(aspetta)
    {
      await tester.pumpAndSettle();
    }
  }

  IconButton freccia(WidgetTester tester, String tooltip)
  {
    return tester.widget<IconButton>(find.widgetWithIcon(IconButton, tooltip == "Giorno precedente" ? Icons.chevron_left : Icons.chevron_right));
  }

  testWidgets("all'apertura chiede le partite di oggi e mostra la data", (tester) async
  {
    await apriPagina(tester);

    expect(repo.dateRicevute, [oggi()]);
    expect(find.text("Partite del giorno"), findsOneWidget);
    expect(find.text(conMaiuscola(dataEstesa(oggi()))), findsOneWidget);
  });

  group("cambio data", ()
  {
    testWidgets("le frecce spostano di un giorno e richiedono le partite", (tester) async
    {
      await apriPagina(tester);
      final oggiPage = oggi();
      final domani = DateTime(oggiPage.year, oggiPage.month, oggiPage.day + 1);
      final ieri = DateTime(oggiPage.year, oggiPage.month, oggiPage.day - 1);

      await tester.tap(find.byTooltip("Giorno successivo"));
      await tester.pumpAndSettle();

      expect(repo.dateRicevute.last, domani);
      expect(find.text(conMaiuscola(dataEstesa(domani))), findsOneWidget);

      await tester.tap(find.byTooltip("Giorno precedente"));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip("Giorno precedente"));
      await tester.pumpAndSettle();

      expect(repo.dateRicevute.last, ieri);
      expect(find.text(conMaiuscola(dataEstesa(ieri))), findsOneWidget);
    });

    testWidgets("il tocco sulla data apre il calendario e il giorno scelto viene richiesto", (tester) async
    {
      await apriPagina(tester);
      final base = oggi();
      final int giornoScelto = base.day == 15 ? 16 : 15;

      await tester.tap(find.text(conMaiuscola(dataEstesa(base))));
      await tester.pumpAndSettle();

      expect(find.text("Scegli il giorno"), findsOneWidget);

      await tester.tap(find.text("$giornoScelto"));
      await tester.pump();
      await tester.tap(find.text("Conferma"));
      await tester.pumpAndSettle();

      final scelta = DateTime(base.year, base.month, giornoScelto);
      expect(repo.dateRicevute.last, scelta);
      expect(find.text(conMaiuscola(dataEstesa(scelta))), findsOneWidget);
    });

    testWidgets("Chiudi sul calendario non cambia nulla", (tester) async
    {
      await apriPagina(tester);

      await tester.tap(find.text(conMaiuscola(dataEstesa(oggi()))));
      await tester.pumpAndSettle();
      await tester.tap(find.text("Chiudi"));
      await tester.pumpAndSettle();

      expect(repo.dateRicevute.length, 1);
    });

    testWidgets("durante il caricamento le frecce sono spente, cosi non si rischia il giorno sbagliato", (tester) async
    {
      repo.attesaPartite = Completer<void>();
      await apriPagina(tester, aspetta: false);
      await tester.pump();

      expect(freccia(tester, "Giorno precedente").onPressed, isNull);
      expect(freccia(tester, "Giorno successivo").onPressed, isNull);
      expect(find.byType(BarraGrigia), findsWidgets);

      repo.attesaPartite!.complete();
      await tester.pumpAndSettle();

      expect(freccia(tester, "Giorno precedente").onPressed, isNotNull);
      expect(freccia(tester, "Giorno successivo").onPressed, isNotNull);
    });
  });

  group("campi e partite", ()
  {
    testWidgets("un campo senza partite compare con Nessuna partita", (tester) async
    {
      repo.campi = [
        campoAdminDiTest(nomeCampo: "Campo Centrale"),
        campoAdminDiTest(idCampo: 2, nomeCampo: "Campo Vuoto", partite: []),
      ];
      await apriPagina(tester);

      expect(find.text("Campo Centrale"), findsOneWidget);
      expect(find.text("Campo Vuoto"), findsOneWidget);
      expect(find.text("Nessuna partita"), findsOneWidget);
    });

    testWidgets("senza campi lo dice", (tester) async
    {
      await apriPagina(tester);

      expect(find.text("Nessun campo disponibile"), findsOneWidget);
    });

    testWidgets("una partita mostra orario, stato, giocatori e posti liberi", (tester) async
    {
      repo.campi = [campoAdminDiTest()];
      await apriPagina(tester);

      expect(find.text("18:30 - 20:00"), findsOneWidget);
      expect(find.text("Creata"), findsOneWidget);
      expect(find.text("Mario Rossi, Giocatore del campo"), findsOneWidget);
      expect(find.text("2 posti liberi"), findsOneWidget);
    });

    testWidgets("le annullate compaiono con il loro stato", (tester) async
    {
      repo.campi = [campoAdminDiTest(partite: [partitaAdminDiTest(stato: "annullata")])];
      await apriPagina(tester);

      expect(find.text("Annullata"), findsOneWidget);
      expect(find.text("18:30 - 20:00"), findsOneWidget);
    });

    testWidgets("una partita senza giocatori e senza posti liberi", (tester) async
    {
      repo.campi = [campoAdminDiTest(partite: [partitaAdminDiTest(giocatori: [], postiLiberi: 0)])];
      await apriPagina(tester);

      expect(find.text("Nessun giocatore"), findsOneWidget);
      expect(find.text("Nessun posto libero"), findsOneWidget);
    });

    testWidgets("il risultato si legge set per set", (tester) async
    {
      repo.campi = [campoAdminDiTest(partite: [partitaAdminDiTest(stato: "giocata", risultato: [SetPartita(squadra1: 6, squadra2: 4), SetPartita(squadra1: 3, squadra2: 6)])])];
      await apriPagina(tester);

      expect(find.text("6-4 3-6"), findsOneWidget);
      expect(find.text("Giocata"), findsOneWidget);
    });

    testWidgets("il tocco apre il dettaglio admin e al ritorno la lista si ricarica", (tester) async
    {
      repo.campi = [campoAdminDiTest(partite: [partitaAdminDiTest(id: 42)])];
      repoPartita.risposta = dettaglioDiTest(id: 42);
      await apriPagina(tester);

      await tester.tap(find.text("18:30 - 20:00"));
      await tester.pumpAndSettle();

      expect(find.byType(DettaglioAdminPage), findsOneWidget);
      expect(repoPartita.idRicevuto, 42);

      await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
      await tester.pumpAndSettle();

      expect(find.byType(PartiteGiornoPage), findsOneWidget);
      expect(repo.dateRicevute.length, 2);
    });
  });

  group("errore", ()
  {
    testWidgets("mostra il messaggio e Riprova ricarica la stessa data", (tester) async
    {
      repo.errorePartite = OperazioneRifiutata(messaggio: "Data non valida");
      await apriPagina(tester);
      await tester.tap(find.byTooltip("Giorno successivo"));
      await tester.pumpAndSettle();

      expect(find.text("Non siamo riusciti a caricare le partite"), findsOneWidget);
      expect(find.text("Data non valida"), findsOneWidget);

      repo.errorePartite = null;
      repo.campi = [campoAdminDiTest()];
      final dataMostrata = repo.dateRicevute.last;
      await tester.tap(find.text("Riprova"));
      await tester.pumpAndSettle();

      expect(repo.dateRicevute.last, dataMostrata);
      expect(find.text("Campo Centrale"), findsOneWidget);
    });
  });
}
