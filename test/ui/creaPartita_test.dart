import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thepadel/bloc/creaPartita/creaPartitaBloc.dart';
import 'package:thepadel/bloc/dettaglioPartita/dettaglioPartitaBloc.dart';
import 'package:thepadel/core/di/depInjection.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/domainLayer/enetity/prenotazione.dart';
import 'package:thepadel/ui/creaPartita.dart';
import 'package:thepadel/useCase/creaPartitaUseCase.dart';
import 'package:thepadel/useCase/dettaglioPartitaUseCase.dart';

import '../fake/fakePartitaRepo.dart';
import '../fake/fakePrenotazioneRepo.dart';

void main()
{
  late FakePrenotazioneRepo repo;
  late FakePartitaRepo repoPartita;

  setUp(() async
  {
    await sl.reset();
    repo = FakePrenotazioneRepo();
    repoPartita = FakePartitaRepo();
    sl.registerFactory<CreaPartitaBloc>(() => CreaPartitaBloc(creaPartitaUseCase: CreaPartitaUseCase(repo: repo)));
    //dopo la creazione la pagina viene sostituita dal dettaglio, che ha bisogno del suo bloc
    sl.registerFactory<DettaglioPartitaBloc>(() => DettaglioPartitaBloc(dettaglioPartitaUseCase: DettaglioPartitaUseCase(repo: repoPartita)));
  });

  tearDown(() async
  {
    await sl.reset();
  });

  //apre la pagina sopra una schermata finta, cosi si puo controllare cosa restituisce con il pop
  Future<List<bool?>> apriPagina(WidgetTester tester) async
  {
    //schermo da telefono (390x844): con la superficie di default 800x600 l'opzione Privata finisce fuori vista
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final risultati = <bool?>[];
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async
            {
              final r = await Navigator.push<bool>(
                context,
                MaterialPageRoute<bool>(builder: (_) => CreaPartitaPage(slot: slotDiTest(), data: DateTime(2026, 11, 2))),
              );
              risultati.add(r);
            },
            child: const Text("apri"),
          ),
        ),
      ),
    ));
    await tester.tap(find.text("apri"));
    await tester.pumpAndSettle();
    return risultati;
  }

  testWidgets("mostra il riepilogo dello slot, le due opzioni e il bottone Prenota", (tester) async
  {
    await apriPagina(tester);

    expect(find.text("Riepilogo partita"), findsOneWidget);
    expect(find.text("Campo Centrale"), findsOneWidget);
    expect(find.text("lunedì 02/11/2026"), findsOneWidget);
    expect(find.text("18:30 - 20:00"), findsOneWidget);
    expect(find.text("Pubblica"), findsOneWidget);
    expect(find.text("Privata"), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, "Prenota"), findsOneWidget);
    //all'inizio nessun tipo e selezionato
    expect(find.byIcon(Icons.radio_button_checked), findsNothing);
    expect(find.byIcon(Icons.radio_button_unchecked), findsNWidgets(2));
  });

  testWidgets("Prenota senza scegliere il tipo mostra la SnackBar di errore e resta sulla pagina", (tester) async
  {
    final risultati = await apriPagina(tester);

    await tester.tap(find.text("Prenota"));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(SnackBar, "scegliere se la partita è pubblica o privata"), findsOneWidget);
    expect(find.text("Riepilogo partita"), findsOneWidget);
    expect(repo.chiamate, 0);
    expect(risultati, isEmpty);
  });

  testWidgets("scelta del tipo: il tocco seleziona l'opzione e il tipo arriva al repository", (tester) async
  {
    repo.attesa = Completer<Prenotazione>();
    await apriPagina(tester);

    await tester.tap(find.text("Privata"));
    await tester.pump();
    expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);

    await tester.tap(find.text("Pubblica"));
    await tester.pump();
    expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);

    await tester.tap(find.text("Prenota"));
    await tester.pump();

    expect(repo.tipoRicevuto, "PUBBLICA");
    expect(repo.idCampoRicevuto, 3);
    //durante l'invio il bottone mostra il caricamento ed e disabilitato
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text("Prenota"), findsNothing);
    final bottone = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(bottone.onPressed, isNull);

    repo.attesa!.complete(prenotazioneDiTest());
    await tester.pumpAndSettle();
  });

  testWidgets("successo: la pagina viene sostituita dal dettaglio della partita creata e la home riceve true", (tester) async
  {
    final risultati = await apriPagina(tester);

    await tester.tap(find.text("Pubblica"));
    await tester.pump();
    await tester.tap(find.text("Prenota"));
    await tester.pumpAndSettle();

    //la home riceve true subito, mentre l'utente e ancora sul dettaglio
    expect(risultati, [true]);
    expect(find.text("Riepilogo partita"), findsNothing);
    expect(find.text("Dettaglio partita"), findsOneWidget);
    //il dettaglio chiede proprio la partita appena creata (id 10 di prenotazioneDiTest)
    expect(repoPartita.idRicevuto, 10);
    expect(find.text("Mario Rossi"), findsOneWidget);
    expect(find.widgetWithText(SnackBar, "Partita creata"), findsOneWidget);
  });

  testWidgets("409: mostra la SnackBar col messaggio del server e resta sulla pagina", (tester) async
  {
    repo.errore = SlotNonDisponibile(messaggio: "Lo slot selezionato è già occupato");
    final risultati = await apriPagina(tester);

    await tester.tap(find.text("Privata"));
    await tester.pump();
    await tester.tap(find.text("Prenota"));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(SnackBar, "Lo slot selezionato è già occupato"), findsOneWidget);
    expect(find.text("Riepilogo partita"), findsOneWidget);
    expect(risultati, isEmpty);
    //dopo l'errore il bottone torna attivo
    expect(find.widgetWithText(ElevatedButton, "Prenota"), findsOneWidget);
  });
}
