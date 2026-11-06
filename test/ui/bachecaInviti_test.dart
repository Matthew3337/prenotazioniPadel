import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thepadel/bloc/bachecaInviti/bachecaInvitiBloc.dart';
import 'package:thepadel/bloc/dettaglioPartita/dettaglioPartitaBloc.dart';
import 'package:thepadel/core/di/depInjection.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/domainLayer/enetity/dettaglioPartita.dart';
import 'package:thepadel/ui/bachecaInviti.dart';
import 'package:thepadel/ui/dettaglioPartita.dart';
import 'package:thepadel/ui/stileApp.dart';
import 'package:thepadel/useCase/bachecaInvitiUseCase.dart';
import 'package:thepadel/useCase/dettaglioPartitaUseCase.dart';

import '../fake/fakePartitaRepo.dart';
import '../fake/fakePreferenze.dart';
import '../fake/temaDiTest.dart';

void main()
{
  setUpAll(caricaFontDellApp);

  late FakePartitaRepo repo;

  setUp(() async
  {
    await sl.reset();
    await registraPreferenzeDiTest();
    repo = FakePartitaRepo();
    sl.registerFactory<BachecaInvitiBloc>(() => BachecaInvitiBloc(invitiConStatoUseCase: InvitiConStatoUseCase(repo: repo), confermaPartitaUseCase: ConfermaPartitaUseCase(repo: repo)));
    //serve per l'apertura del dettaglio dal tocco su una card
    sl.registerFactory<DettaglioPartitaBloc>(() => DettaglioPartitaBloc(dettaglioPartitaUseCase: DettaglioPartitaUseCase(repo: repo), eliminaPartitaUseCase: EliminaPartitaUseCase(repo: repo), esciDaPartitaUseCase: EsciDaPartitaUseCase(repo: repo), confermaPartitaUseCase: ConfermaPartitaUseCase(repo: repo), cambiaTipoUseCase: CambiaTipoUseCase(repo: repo)));
  });

  tearDown(() async
  {
    await sl.reset();
  });

  Future<void> apriPagina(WidgetTester tester) async
  {
    //schermo da telefono (390x844)
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(theme: temaDiTest(), home: const BachecaInvitiPage()));
    await tester.pumpAndSettle();
  }

  testWidgets("mostra la card con chi ha invitato, quando, campo e tipo, e il conteggio nella scheda", (tester) async
  {
    repo.partiteInviti = [partitaInvitoDiTest()];
    repo.dettagliPerId = {10: dettaglioDiTest(azioni: azioniDiTest())};
    await apriPagina(tester);

    expect(repo.chiamateInviti, 1);
    //il titolo della pagina e la voce della barra si chiamano Bacheca; "Partite" e la voce delle mie partite
    expect(find.text("Bacheca"), findsNWidgets(2));
    expect(find.text("1 ricevuto"), findsOneWidget);
    expect(find.text("Mario Rossi ti ha invitato"), findsOneWidget);
    expect(find.text("MR"), findsOneWidget);
    expect(find.textContaining("Campo Centrale · ${giornoEMese(DateTime(2026, 11, 2))}, 18:30 - 20:00 · Privata"), findsOneWidget);
    expect(find.text("Vedi la partita"), findsOneWidget);
    expect(find.text("Non hai inviti al momento"), findsNothing);
  });

  testWidgets("con piu inviti il conteggio e al plurale e il tipo arriva dalla partita", (tester) async
  {
    repo.partiteInviti = [
      partitaInvitoDiTest(id: 10, nomeCampo: "Campo Uno"),
      partitaInvitoDiTest(id: 11, nomeCampo: "Campo Due", stato: "confermata", tipo: "PUBBLICA"),
    ];
    await apriPagina(tester);

    expect(find.text("2 ricevuti"), findsOneWidget);
    expect(find.textContaining("Campo Uno"), findsOneWidget);
    expect(find.textContaining("Campo Due"), findsOneWidget);
    expect(find.textContaining("· Privata"), findsOneWidget);
    expect(find.textContaining("· Pubblica"), findsOneWidget);
  });

  testWidgets("nessun invito: mostra il messaggio della lista vuota e il link alle pubbliche", (tester) async
  {
    repo.partiteInviti = [];
    await apriPagina(tester);

    expect(find.text("Non hai inviti al momento"), findsOneWidget);
    expect(find.text("Guarda le partite pubbliche"), findsOneWidget);
    expect(find.text("0 ricevuti"), findsOneWidget);
    expect(find.text("Vedi la partita"), findsNothing);
  });

  testWidgets("errore di caricamento: messaggio e Riprova rifa la richiesta", (tester) async
  {
    repo.erroreInviti = ErroreGenericoServer();
    await apriPagina(tester);

    expect(find.text("Non siamo riusciti a caricare gli inviti"), findsOneWidget);
    expect(find.text(ErroreGenericoServer().messaggio), findsOneWidget);
    expect(find.text("Riprova"), findsOneWidget);

    repo.erroreInviti = null;
    await tester.tap(find.text("Riprova"));
    await tester.pumpAndSettle();

    expect(repo.chiamateInviti, 2);
    expect(find.text("Vedi la partita"), findsOneWidget);
  });

  testWidgets("pull-to-refresh ricarica la bacheca, anche quando e vuota", (tester) async
  {
    repo.partiteInviti = [];
    await apriPagina(tester);

    repo.partiteInviti = [partitaInvitoDiTest()];
    await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();

    expect(repo.chiamateInviti, 2);
    expect(find.text("Vedi la partita"), findsOneWidget);
  });

  testWidgets("Vedi la partita apre il dettaglio e al ritorno ricarica la bacheca", (tester) async
  {
    repo.partiteInviti = [partitaInvitoDiTest(id: 12)];
    await apriPagina(tester);

    await tester.tap(find.text("Vedi la partita"));
    await tester.pumpAndSettle();

    expect(find.byType(DettaglioPartitaPage), findsOneWidget);
    expect(find.text("Dettaglio partita"), findsOneWidget);
    expect(repo.idRicevuto, 12);

    //intanto l'utente e uscito dalla partita
    repo.partiteInviti = [];
    final NavigatorState navigator = tester.state(find.byType(Navigator));
    navigator.pop();
    await tester.pumpAndSettle();

    expect(find.byType(DettaglioPartitaPage), findsNothing);
    expect(repo.chiamateInviti, 2);
    expect(find.text("Non hai inviti al momento"), findsOneWidget);
  });

  group("conferma dalla lista", ()
  {
    setUp(()
    {
      repo.partiteInviti = [partitaInvitoDiTest(id: 10)];
      repo.dettagliPerId = {10: dettaglioDiTest(azioni: azioniDiTest(puoConfermare: true))};
    });

    testWidgets("si puo confermare: compare il bottone e il tocco chiama il server, poi Confermato", (tester) async
    {
      await apriPagina(tester);

      expect(find.widgetWithText(ElevatedButton, "Conferma"), findsOneWidget);

      await tester.tap(find.text("Conferma"));
      await tester.pumpAndSettle();

      expect(repo.chiamateConferma, 1);
      expect(repo.idConfermaRicevuto, 10);
      expect(find.widgetWithText(SnackBar, "Partecipazione confermata"), findsOneWidget);
      expect(find.text("Confermato"), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, "Conferma"), findsNothing);
    });

    testWidgets("la conferma che completa la partita lo dice nella SnackBar", (tester) async
    {
      repo.rispostaConferma = dettaglioDiTest(stato: "confermata");
      await apriPagina(tester);

      await tester.tap(find.text("Conferma"));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(SnackBar, "Partita confermata: ci sono tutti!"), findsOneWidget);
    });

    testWidgets("durante la conferma lo spinner e solo su quel bottone, l'altro e disabilitato", (tester) async
    {
      repo.partiteInviti = [partitaInvitoDiTest(id: 10), partitaInvitoDiTest(id: 11)];
      repo.dettagliPerId = {
        10: dettaglioDiTest(azioni: azioniDiTest(puoConfermare: true)),
        11: dettaglioDiTest(id: 11, azioni: azioniDiTest(puoConfermare: true)),
      };
      repo.attesaConferma = Completer<DettaglioPartita>();
      await apriPagina(tester);

      await tester.tap(find.text("Conferma").first);
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text("Conferma"), findsOneWidget);
      for(final bottone in tester.widgetList<ElevatedButton>(find.byType(ElevatedButton)))
      {
        expect(bottone.onPressed, isNull);
      }

      repo.attesaConferma!.complete(dettaglioDiTest());
      await tester.pumpAndSettle();
    });

    testWidgets("errore: SnackBar col messaggio e il bottone resta", (tester) async
    {
      repo.erroreConferma = OperazioneRifiutata(messaggio: "La conferma è possibile solo tra 24 e 12 ore prima dell'inizio");
      await apriPagina(tester);

      await tester.tap(find.text("Conferma"));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(SnackBar, "La conferma è possibile solo tra 24 e 12 ore prima dell'inizio"), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, "Conferma"), findsOneWidget);
    });

    testWidgets("gia confermato: pillola Confermato e nessun bottone", (tester) async
    {
      repo.dettagliPerId = {10: dettaglioDiTest(azioni: azioniDiTest(), posti: quattroPostiDiTest())};
      await apriPagina(tester);

      expect(find.text("Confermato"), findsOneWidget);
      expect(find.text("Conferma"), findsNothing);
    });

    testWidgets("se il dettaglio dell'invito non arriva la card resta, senza azioni", (tester) async
    {
      repo.dettagliPerId = {};
      repo.dettagliInErrore = {10};
      await apriPagina(tester);

      expect(find.text("Vedi la partita"), findsOneWidget);
      expect(find.text("Conferma"), findsNothing);
      expect(find.text("Confermato"), findsNothing);
    });
  });
}
