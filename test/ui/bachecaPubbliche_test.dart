import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thepadel/bloc/bachecaInviti/bachecaInvitiBloc.dart';
import 'package:thepadel/bloc/bachecaPubbliche/bachecaPubblicheBloc.dart';
import 'package:thepadel/bloc/dettaglioPartita/dettaglioPartitaBloc.dart';
import 'package:thepadel/core/di/depInjection.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/domainLayer/enetity/dettaglioPartita.dart';
import 'package:thepadel/domainLayer/enetity/partitaPubblica.dart';
import 'package:thepadel/ui/bachecaInviti.dart';
import 'package:thepadel/ui/bachecaPubbliche.dart';
import 'package:thepadel/ui/campoPadel.dart';
import 'package:thepadel/ui/dettaglioPartita.dart';
import 'package:thepadel/ui/stileApp.dart';
import 'package:thepadel/useCase/bachecaInvitiUseCase.dart';
import 'package:thepadel/useCase/bachecaPubblicheUseCase.dart';
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
    sl.registerFactory<BachecaPubblicheBloc>(() => BachecaPubblicheBloc(
      partitePubblicheUseCase: PartitePubblicheUseCase(repo: repo),
      entraInPartitaUseCase: EntraInPartitaUseCase(repo: repo),
    ));
    //serve per la navigazione al dettaglio dopo un ingresso riuscito
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

    await tester.pumpWidget(MaterialApp(theme: temaDiTest(), home: const BachecaPubblichePage()));
    await tester.pumpAndSettle();
  }

  testWidgets("mostra la card con campo, data, orario, creatore, livello e posti liberi", (tester) async
  {
    await apriPagina(tester);

    expect(repo.chiamatePubbliche, 1);
    //il titolo della pagina e la voce della barra
    //il titolo della pagina e la voce della barra si chiamano Bacheca; "Partite" e la voce delle mie partite
    expect(find.text("Bacheca"), findsNWidgets(2));
    expect(find.text("1 aperta"), findsOneWidget);
    expect(find.text("Campo Centrale · ${giornoEMese(DateTime(2026, 11, 2))}, 18:30 - 20:00"), findsOneWidget);
    expect(find.text("2 posti liberi"), findsOneWidget);
    expect(find.text("Mario Rossi · Livello 2.5"), findsOneWidget);
    expect(find.byType(MiniCampo), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, "Entra"), findsOneWidget);
    expect(find.text("Nessuna partita pubblica disponibile al momento"), findsNothing);
  });

  testWidgets("creatore admin: mostra il nome senza livello e si puo entrare", (tester) async
  {
    repo.partitePubbliche = [partitaPubblicaDiTest(livelloCreatore: null)];
    await apriPagina(tester);

    expect(tester.takeException(), isNull);
    expect(find.text("Mario Rossi"), findsOneWidget);
    expect(find.textContaining("Livello"), findsNothing);
    expect(find.textContaining("null"), findsNothing);
    expect(find.widgetWithText(ElevatedButton, "Entra"), findsOneWidget);
  });

  testWidgets("il sottotitolo non parla piu di livello simile", (tester) async
  {
    await apriPagina(tester);

    expect(find.text("Partite aperte a cui puoi unirti"), findsOneWidget);
    expect(find.textContaining("livello simile"), findsNothing);
  });

  testWidgets("una partita di oggi non ripete la data", (tester) async
  {
    final oggi = DateTime.now();
    repo.partitePubbliche = [PartitaPubblica(id: 10, idCampo: 3, nomeCampo: "Campo Centrale", dataPartita: oggi, oraInizio: const TimeOfDay(hour: 18, minute: 30), oraFine: const TimeOfDay(hour: 20, minute: 0), nomeCreatore: "Mario", cognomeCreatore: "Rossi", livelloCreatore: 2.5, postiLiberi: 2)];
    await apriPagina(tester);

    expect(find.text("Oggi, 18:30"), findsOneWidget);
    expect(find.text("Campo Centrale · 18:30 - 20:00"), findsOneWidget);
  });

  testWidgets("con un solo posto libero il badge e al singolare", (tester) async
  {
    repo.partitePubbliche = [partitaPubblicaDiTest(postiLiberi: 1)];
    await apriPagina(tester);

    expect(find.text("1 posto libero"), findsOneWidget);
  });

  testWidgets("la scheda Inviti apre la bacheca degli inviti", (tester) async
  {
    sl.registerFactory<BachecaInvitiBloc>(() => BachecaInvitiBloc(invitiConStatoUseCase: InvitiConStatoUseCase(repo: repo), confermaPartitaUseCase: ConfermaPartitaUseCase(repo: repo)));
    await apriPagina(tester);

    await tester.tap(find.text("Inviti"));
    await tester.pumpAndSettle();

    expect(find.byType(BachecaInvitiPage), findsOneWidget);
    expect(find.byType(BachecaPubblichePage), findsNothing);
  });

  testWidgets("bacheca vuota: mostra il messaggio e nessun bottone Entra", (tester) async
  {
    repo.partitePubbliche = [];
    await apriPagina(tester);

    expect(find.text("Nessuna partita pubblica disponibile al momento"), findsOneWidget);
    expect(find.text("Prenota un campo"), findsOneWidget);
    expect(find.text("0 aperte"), findsOneWidget);
    expect(find.text("Entra"), findsNothing);
  });

  testWidgets("errore di caricamento: messaggio e Riprova rifa la richiesta", (tester) async
  {
    repo.errorePubbliche = ErroreGenericoServer();
    await apriPagina(tester);

    expect(find.text("Non siamo riusciti a caricare le partite"), findsOneWidget);
    expect(find.text(ErroreGenericoServer().messaggio), findsOneWidget);

    repo.errorePubbliche = null;
    await tester.tap(find.text("Riprova"));
    await tester.pumpAndSettle();

    expect(repo.chiamatePubbliche, 2);
    expect(find.widgetWithText(ElevatedButton, "Entra"), findsOneWidget);
  });

  testWidgets("durante l'ingresso lo spinner compare solo sulla card scelta", (tester) async
  {
    repo.partitePubbliche = [
      partitaPubblicaDiTest(id: 10, nomeCampo: "Campo Centrale"),
      partitaPubblicaDiTest(id: 11, nomeCampo: "Campo Due"),
    ];
    repo.attesaEntra = Completer<DettaglioPartita>();
    await apriPagina(tester);

    expect(find.text("Entra"), findsNWidgets(2));

    await tester.tap(find.text("Entra").first);
    await tester.pump();

    expect(repo.idEntraRicevuto, 10);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    //un ingresso per volta: anche la seconda card ha il bottone spento, ma senza spinner
    expect(find.text("Entra"), findsOneWidget);
    final bottoni = tester.widgetList<ElevatedButton>(find.byType(ElevatedButton)).toList();
    expect(bottoni.length, 2);
    expect(bottoni[0].onPressed, isNull);
    expect(bottoni[1].onPressed, isNull);
    //lo spinner sta nel bottone della prima card
    expect(find.descendant(of: find.byWidget(bottoni[0]), matching: find.byType(CircularProgressIndicator)), findsOneWidget);

    //chiudo la richiesta in sospeso con un errore, cosi il test non apre il dettaglio
    repo.attesaEntra!.completeError(IngressoRifiutato(messaggio: "La partita è al completo"));
    await tester.pumpAndSettle();
  });

  testWidgets("ingresso 409: SnackBar col messaggio e bacheca ricaricata", (tester) async
  {
    await apriPagina(tester);

    repo.erroreEntra = IngressoRifiutato(messaggio: "La partita è al completo");
    repo.partitePubbliche = [];
    await tester.tap(find.text("Entra"));
    await tester.pump();
    await tester.pump();

    expect(find.widgetWithText(SnackBar, "La partita è al completo"), findsOneWidget);

    await tester.pumpAndSettle();
    expect(repo.chiamateEntra, 1);
    expect(repo.chiamatePubbliche, 2);
    expect(find.text("Nessuna partita pubblica disponibile al momento"), findsOneWidget);
  });

  testWidgets("ingresso riuscito: apre il dettaglio della partita e al ritorno ricarica la bacheca", (tester) async
  {
    await apriPagina(tester);

    await tester.tap(find.text("Entra"));
    await tester.pumpAndSettle();

    expect(repo.idEntraRicevuto, 10);
    expect(find.byType(DettaglioPartitaPage), findsOneWidget);
    expect(find.text("Dettaglio partita"), findsOneWidget);
    expect(repo.idRicevuto, 10);

    //al ritorno la partita in cui l'utente e entrato non compare piu
    repo.partitePubbliche = [];
    final NavigatorState navigator = tester.state(find.byType(Navigator));
    navigator.pop();
    await tester.pumpAndSettle();

    expect(find.byType(DettaglioPartitaPage), findsNothing);
    expect(repo.chiamatePubbliche, 2);
    expect(find.text("Nessuna partita pubblica disponibile al momento"), findsOneWidget);
  });
}
