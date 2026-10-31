import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thepadel/bloc/dettaglioPartita/dettaglioPartitaBloc.dart';
import 'package:thepadel/core/di/depInjection.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/domainLayer/enetity/postoPartita.dart';
import 'package:thepadel/ui/dettaglioPartita.dart';
import 'package:thepadel/useCase/dettaglioPartitaUseCase.dart';

import '../fake/fakePartitaRepo.dart';

void main()
{
  late FakePartitaRepo repo;

  setUp(() async
  {
    await sl.reset();
    repo = FakePartitaRepo();
    sl.registerFactory<DettaglioPartitaBloc>(() => DettaglioPartitaBloc(dettaglioPartitaUseCase: DettaglioPartitaUseCase(repo: repo)));
  });

  tearDown(() async
  {
    await sl.reset();
  });

  Future<void> apriPagina(WidgetTester tester) async
  {
    //schermo da telefono (390x844): con la superficie di default 800x600 i bottoni finiscono fuori vista
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: DettaglioPartitaPage(idPartita: 10)));
    await tester.pumpAndSettle();
  }

  testWidgets("mostra info, posti occupati, posti liberi ed etichetta Organizzatore", (tester) async
  {
    await apriPagina(tester);

    expect(repo.idRicevuto, 10);
    expect(find.text("Dettaglio partita"), findsOneWidget);
    expect(find.text("Campo Centrale"), findsOneWidget);
    expect(find.text("lunedì 02/11/2026"), findsOneWidget);
    expect(find.text("18:30 - 20:00"), findsOneWidget);
    expect(find.text("Pubblica"), findsOneWidget);
    expect(find.text("Creata"), findsOneWidget);

    expect(find.text("Mario Rossi"), findsOneWidget);
    expect(find.text("Livello 2.5 · Da confermare"), findsOneWidget);
    expect(find.text("Giocatore del campo"), findsOneWidget);
    expect(find.text("Posto libero"), findsNWidgets(2));
    //solo il creatore ha l'etichetta
    expect(find.text("Organizzatore"), findsOneWidget);
  });

  testWidgets("un partecipante che non e il creatore non ha l'etichetta Organizzatore", (tester) async
  {
    repo.risposta = dettaglioDiTest(posti: [
      PostoPartita(tipo: "UTENTE", telefono: "3331234567", nome: "Mario", cognome: "Rossi", livello: 2.5, confermata: true),
      PostoPartita(tipo: "UTENTE", telefono: "3339999999", nome: "Luca", cognome: "Bianchi", livello: null, confermata: false),
    ]);
    await apriPagina(tester);

    expect(find.text("Mario Rossi"), findsOneWidget);
    expect(find.text("Livello 2.5 · Confermato"), findsOneWidget);
    expect(find.text("Luca Bianchi"), findsOneWidget);
    expect(find.text("Da confermare"), findsOneWidget);
    expect(find.text("Organizzatore"), findsOneWidget);
    expect(find.text("Posto libero"), findsNWidgets(2));
  });

  testWidgets("azioni del creatore: Invita ed Elimina visibili, gli altri bottoni nascosti", (tester) async
  {
    await apriPagina(tester);

    expect(find.widgetWithText(ElevatedButton, "Invita"), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, "Elimina partita"), findsOneWidget);
    expect(find.text("Conferma"), findsNothing);
    expect(find.text("Registra risultato"), findsNothing);
    expect(find.text("Esci dalla partita"), findsNothing);
  });

  testWidgets("azioni di un partecipante: Esci e Conferma visibili, Invita ed Elimina nascosti", (tester) async
  {
    repo.risposta = dettaglioDiTest(azioni: azioniDiTest(puoUscire: true, puoConfermare: true));
    await apriPagina(tester);

    expect(find.widgetWithText(ElevatedButton, "Esci dalla partita"), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, "Conferma"), findsOneWidget);
    expect(find.text("Invita"), findsNothing);
    expect(find.text("Elimina partita"), findsNothing);
    expect(find.text("Registra risultato"), findsNothing);
  });

  testWidgets("con puoRegistrareRisultato compare solo Registra risultato", (tester) async
  {
    repo.risposta = dettaglioDiTest(azioni: azioniDiTest(puoRegistrareRisultato: true));
    await apriPagina(tester);

    expect(find.byType(ElevatedButton), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, "Registra risultato"), findsOneWidget);
  });

  testWidgets("nessuna azione: nessun bottone", (tester) async
  {
    repo.risposta = dettaglioDiTest(azioni: azioniDiTest());
    await apriPagina(tester);

    expect(find.byType(ElevatedButton), findsNothing);
  });

  testWidgets("il tocco su un bottone mostra Funzione in arrivo", (tester) async
  {
    await apriPagina(tester);

    await tester.tap(find.text("Invita"));
    await tester.pump();

    expect(find.widgetWithText(SnackBar, "Funzione in arrivo"), findsOneWidget);
  });

  testWidgets("errore: mostra il messaggio e Riprova rifa la richiesta", (tester) async
  {
    repo.errore = PartitaNonTrovata(messaggio: "Partita non trovata");
    await apriPagina(tester);

    expect(find.text("Partita non trovata"), findsOneWidget);
    expect(find.text("Riprova"), findsOneWidget);
    expect(find.text("Giocatori"), findsNothing);
    expect(repo.chiamate, 1);

    //al secondo tentativo il server risponde
    repo.errore = null;
    await tester.tap(find.text("Riprova"));
    await tester.pumpAndSettle();

    expect(repo.chiamate, 2);
    expect(find.text("Partita non trovata"), findsNothing);
    expect(find.text("Mario Rossi"), findsOneWidget);
  });
}
