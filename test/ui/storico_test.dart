import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thepadel/bloc/dettaglioPartita/dettaglioPartitaBloc.dart';
import 'package:thepadel/bloc/storico/storicoBloc.dart';
import 'package:thepadel/core/di/depInjection.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/domainLayer/enetity/risultatoPartita.dart';
import 'package:thepadel/domainLayer/enetity/setPartita.dart';
import 'package:thepadel/ui/dettaglioPartita.dart';
import 'package:thepadel/ui/storico.dart';
import 'package:thepadel/useCase/dettaglioPartitaUseCase.dart';
import 'package:thepadel/useCase/storicoUseCase.dart';

import '../fake/fakePartitaRepo.dart';

void main()
{
  late FakePartitaRepo repo;

  setUp(() async
  {
    await sl.reset();
    repo = FakePartitaRepo();
    sl.registerFactory<StoricoBloc>(() => StoricoBloc(storicoUseCase: StoricoUseCase(repo: repo)));
    //serve per l'apertura del dettaglio dal tocco su una card
    sl.registerFactory<DettaglioPartitaBloc>(() => DettaglioPartitaBloc(dettaglioPartitaUseCase: DettaglioPartitaUseCase(repo: repo), eliminaPartitaUseCase: EliminaPartitaUseCase(repo: repo), esciDaPartitaUseCase: EsciDaPartitaUseCase(repo: repo)));
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

    await tester.pumpWidget(const MaterialApp(home: StoricoPage()));
    await tester.pumpAndSettle();
  }

  testWidgets("mostra la card con campo, data, orario e badge di stato, senza risultato", (tester) async
  {
    await apriPagina(tester);

    expect(repo.chiamateStorico, 1);
    expect(find.text("Storico partite"), findsOneWidget);
    expect(find.text("Campo Centrale"), findsOneWidget);
    expect(find.text("lunedì 02/11/2026"), findsOneWidget);
    expect(find.text("18:30 - 20:00"), findsOneWidget);
    expect(find.text("Creata"), findsOneWidget);
    expect(find.text("Risultato"), findsNothing);
    expect(find.text("Non hai ancora partite nello storico"), findsNothing);
  });

  testWidgets("badge di stato confermata e giocata", (tester) async
  {
    repo.partiteStorico = [
      partitaStoricoDiTest(id: 10, nomeCampo: "Campo Uno", stato: "confermata"),
      partitaStoricoDiTest(id: 11, nomeCampo: "Campo Due", stato: "giocata"),
    ];
    await apriPagina(tester);

    expect(find.text("Confermata"), findsOneWidget);
    expect(find.text("Giocata"), findsOneWidget);
  });

  testWidgets("risultato compatto con squadraUtente 1: 6-4 3-6 6-2 · Vinta e +12 punti", (tester) async
  {
    repo.partiteStorico = [partitaStoricoDiTest(stato: "giocata", risultato: risultatoDiTest())];
    await apriPagina(tester);

    expect(find.text("Risultato"), findsOneWidget);
    expect(find.text("6-4 3-6 6-2 · Vinta · +12 punti"), findsOneWidget);
    expect(find.textContaining("6-4 3-6 6-2 · Vinta"), findsOneWidget);
  });

  testWidgets("con squadraUtente 2 i set sono girati dal punto di vista dell'utente", (tester) async
  {
    repo.partiteStorico = [
      partitaStoricoDiTest(stato: "giocata", risultato: risultatoDiTest(squadraUtente: 2, esito: "PERSA", puntiAssegnati: null)),
    ];
    await apriPagina(tester);

    expect(find.text("4-6 6-3 2-6 · Persa"), findsOneWidget);
  });

  testWidgets("partita persa con punti negativi: Persa e -7 punti", (tester) async
  {
    final risultato = RisultatoPartita(
      set: [SetPartita(squadra1: 6, squadra2: 1), SetPartita(squadra1: 6, squadra2: 3)],
      squadraUtente: 2,
      esito: "PERSA",
      puntiAssegnati: -7,
    );
    repo.partiteStorico = [partitaStoricoDiTest(stato: "giocata", risultato: risultato)];
    await apriPagina(tester);

    expect(find.text("1-6 3-6 · Persa · -7 punti"), findsOneWidget);
    expect(find.textContaining("Vinta"), findsNothing);
  });

  testWidgets("con esito null mostra solo i set", (tester) async
  {
    repo.partiteStorico = [
      partitaStoricoDiTest(stato: "giocata", risultato: risultatoDiTest(squadraUtente: null, esito: null, puntiAssegnati: null)),
    ];
    await apriPagina(tester);

    expect(find.text("6-4 3-6 6-2"), findsOneWidget);
    expect(find.textContaining("Vinta"), findsNothing);
    expect(find.textContaining("Persa"), findsNothing);
    expect(find.textContaining("punti"), findsNothing);
  });

  testWidgets("storico vuoto: mostra il messaggio e nessuna card", (tester) async
  {
    repo.partiteStorico = [];
    await apriPagina(tester);

    expect(find.text("Non hai ancora partite nello storico"), findsOneWidget);
    expect(find.text("Campo Centrale"), findsNothing);
  });

  testWidgets("errore di caricamento: messaggio e Riprova rifa la richiesta", (tester) async
  {
    repo.erroreStorico = ErroreGenericoServer();
    await apriPagina(tester);

    expect(find.text(ErroreGenericoServer().messaggio), findsOneWidget);
    expect(find.text("Riprova"), findsOneWidget);

    repo.erroreStorico = null;
    await tester.tap(find.text("Riprova"));
    await tester.pumpAndSettle();

    expect(repo.chiamateStorico, 2);
    expect(find.text("Campo Centrale"), findsOneWidget);
  });

  testWidgets("il tocco su una card apre il dettaglio e al ritorno lo storico si ricarica", (tester) async
  {
    repo.partiteStorico = [partitaStoricoDiTest(id: 10)];
    await apriPagina(tester);

    await tester.tap(find.text("Campo Centrale"));
    await tester.pumpAndSettle();

    expect(find.byType(DettaglioPartitaPage), findsOneWidget);
    expect(find.text("Dettaglio partita"), findsOneWidget);
    expect(repo.idRicevuto, 10);

    repo.partiteStorico = [];
    final NavigatorState navigator = tester.state(find.byType(Navigator));
    navigator.pop();
    await tester.pumpAndSettle();

    expect(find.byType(DettaglioPartitaPage), findsNothing);
    expect(repo.chiamateStorico, 2);
    expect(find.text("Non hai ancora partite nello storico"), findsOneWidget);
  });
}
