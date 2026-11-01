import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thepadel/bloc/bachecaPubbliche/bachecaPubblicheBloc.dart';
import 'package:thepadel/bloc/dettaglioPartita/dettaglioPartitaBloc.dart';
import 'package:thepadel/core/di/depInjection.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/domainLayer/enetity/dettaglioPartita.dart';
import 'package:thepadel/ui/bachecaPubbliche.dart';
import 'package:thepadel/ui/dettaglioPartita.dart';
import 'package:thepadel/useCase/bachecaPubblicheUseCase.dart';
import 'package:thepadel/useCase/dettaglioPartitaUseCase.dart';

import '../fake/fakePartitaRepo.dart';

void main()
{
  late FakePartitaRepo repo;

  setUp(() async
  {
    await sl.reset();
    repo = FakePartitaRepo();
    sl.registerFactory<BachecaPubblicheBloc>(() => BachecaPubblicheBloc(
      partitePubblicheUseCase: PartitePubblicheUseCase(repo: repo),
      entraInPartitaUseCase: EntraInPartitaUseCase(repo: repo),
    ));
    //serve per la navigazione al dettaglio dopo un ingresso riuscito
    sl.registerFactory<DettaglioPartitaBloc>(() => DettaglioPartitaBloc(dettaglioPartitaUseCase: DettaglioPartitaUseCase(repo: repo), eliminaPartitaUseCase: EliminaPartitaUseCase(repo: repo), esciDaPartitaUseCase: EsciDaPartitaUseCase(repo: repo), confermaPartitaUseCase: ConfermaPartitaUseCase(repo: repo)));
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

    await tester.pumpWidget(const MaterialApp(home: BachecaPubblichePage()));
    await tester.pumpAndSettle();
  }

  testWidgets("mostra la card con campo, data, orario, creatore, livello e posti liberi", (tester) async
  {
    await apriPagina(tester);

    expect(repo.chiamatePubbliche, 1);
    expect(find.text("Partite pubbliche"), findsOneWidget);
    expect(find.text("Campo Centrale"), findsOneWidget);
    expect(find.text("2 posti liberi"), findsOneWidget);
    expect(find.text("lunedì 02/11/2026"), findsOneWidget);
    expect(find.text("18:30 - 20:00"), findsOneWidget);
    expect(find.text("Mario Rossi · Livello 2.5"), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, "Entra"), findsOneWidget);
    expect(find.text("Nessuna partita pubblica disponibile al momento"), findsNothing);
  });

  testWidgets("con un solo posto libero il badge e al singolare", (tester) async
  {
    repo.partitePubbliche = [partitaPubblicaDiTest(postiLiberi: 1)];
    await apriPagina(tester);

    expect(find.text("1 posto libero"), findsOneWidget);
  });

  testWidgets("bacheca vuota: mostra il messaggio e nessun bottone Entra", (tester) async
  {
    repo.partitePubbliche = [];
    await apriPagina(tester);

    expect(find.text("Nessuna partita pubblica disponibile al momento"), findsOneWidget);
    expect(find.text("Entra"), findsNothing);
  });

  testWidgets("errore di caricamento: messaggio e Riprova rifa la richiesta", (tester) async
  {
    repo.errorePubbliche = ErroreGenericoServer();
    await apriPagina(tester);

    expect(find.text(ErroreGenericoServer().messaggio), findsOneWidget);

    repo.errorePubbliche = null;
    await tester.tap(find.text("Riprova"));
    await tester.pumpAndSettle();

    expect(repo.chiamatePubbliche, 2);
    expect(find.text("Campo Centrale"), findsOneWidget);
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
    //la seconda card ha ancora il suo bottone attivo
    expect(find.text("Entra"), findsOneWidget);
    final bottoni = tester.widgetList<ElevatedButton>(find.byType(ElevatedButton)).toList();
    expect(bottoni.length, 2);
    expect(bottoni[0].onPressed, isNull);
    expect(bottoni[1].onPressed, isNotNull);
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
