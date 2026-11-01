import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thepadel/bloc/bachecaInviti/bachecaInvitiBloc.dart';
import 'package:thepadel/bloc/dettaglioPartita/dettaglioPartitaBloc.dart';
import 'package:thepadel/core/di/depInjection.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/ui/bachecaInviti.dart';
import 'package:thepadel/ui/dettaglioPartita.dart';
import 'package:thepadel/useCase/bachecaInvitiUseCase.dart';
import 'package:thepadel/useCase/dettaglioPartitaUseCase.dart';

import '../fake/fakePartitaRepo.dart';

void main()
{
  late FakePartitaRepo repo;

  setUp(() async
  {
    await sl.reset();
    repo = FakePartitaRepo();
    sl.registerFactory<BachecaInvitiBloc>(() => BachecaInvitiBloc(bachecaInvitiUseCase: BachecaInvitiUseCase(repo: repo)));
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

    await tester.pumpWidget(const MaterialApp(home: BachecaInvitiPage()));
    await tester.pumpAndSettle();
  }

  testWidgets("mostra la card con campo, data, orario, chi ha invitato, tipo e stato", (tester) async
  {
    await apriPagina(tester);

    expect(repo.chiamateInviti, 1);
    expect(find.text("Inviti ricevuti"), findsOneWidget);
    expect(find.text("Campo Centrale"), findsOneWidget);
    expect(find.text("lunedì 02/11/2026"), findsOneWidget);
    expect(find.text("18:30 - 20:00"), findsOneWidget);
    expect(find.text("Invitato da"), findsOneWidget);
    expect(find.text("Mario Rossi"), findsOneWidget);
    expect(find.text("Privata"), findsOneWidget);
    expect(find.text("Creata"), findsOneWidget);
    expect(find.text("Non hai inviti al momento"), findsNothing);
  });

  testWidgets("partita pubblica e confermata: tipo Pubblica e badge Confermata", (tester) async
  {
    repo.partiteInviti = [
      partitaInvitoDiTest(id: 10, nomeCampo: "Campo Uno"),
      partitaInvitoDiTest(id: 11, nomeCampo: "Campo Due", stato: "confermata", tipo: "PUBBLICA"),
    ];
    await apriPagina(tester);

    expect(find.text("Campo Uno"), findsOneWidget);
    expect(find.text("Campo Due"), findsOneWidget);
    expect(find.text("Pubblica"), findsOneWidget);
    expect(find.text("Privata"), findsOneWidget);
    expect(find.text("Confermata"), findsOneWidget);
    expect(find.text("Creata"), findsOneWidget);
  });

  testWidgets("nessun invito: mostra il messaggio della lista vuota", (tester) async
  {
    repo.partiteInviti = [];
    await apriPagina(tester);

    expect(find.text("Non hai inviti al momento"), findsOneWidget);
    expect(find.text("Invitato da"), findsNothing);
  });

  testWidgets("errore di caricamento: messaggio e Riprova rifa la richiesta", (tester) async
  {
    repo.erroreInviti = ErroreGenericoServer();
    await apriPagina(tester);

    expect(find.text(ErroreGenericoServer().messaggio), findsOneWidget);
    expect(find.text("Riprova"), findsOneWidget);

    repo.erroreInviti = null;
    await tester.tap(find.text("Riprova"));
    await tester.pumpAndSettle();

    expect(repo.chiamateInviti, 2);
    expect(find.text("Campo Centrale"), findsOneWidget);
  });

  testWidgets("pull-to-refresh ricarica la bacheca, anche quando e vuota", (tester) async
  {
    repo.partiteInviti = [];
    await apriPagina(tester);

    repo.partiteInviti = [partitaInvitoDiTest()];
    await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();

    expect(repo.chiamateInviti, 2);
    expect(find.text("Campo Centrale"), findsOneWidget);
  });

  testWidgets("il tocco su una card apre il dettaglio e al ritorno ricarica la bacheca", (tester) async
  {
    repo.partiteInviti = [partitaInvitoDiTest(id: 12)];
    await apriPagina(tester);

    await tester.tap(find.text("Campo Centrale"));
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
}
