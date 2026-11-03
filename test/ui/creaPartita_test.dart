import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thepadel/core/di/depInjection.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/domainLayer/enetity/prenotazione.dart';
import 'package:thepadel/ui/creaPartita.dart';
import 'package:thepadel/ui/prenota.dart';
import 'package:thepadel/ui/stileApp.dart';
import 'package:thepadel/useCase/eccezioniUseCase.dart';

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

  late FakePrenotazioneRepo repo;
  late FakeCampoRepo repoCampo;

  //una data nel futuro: gli slot alternativi non risultano gia iniziati, qualunque sia l'ora del test
  final oggi = DateTime.now();
  final data = DateTime(oggi.year, oggi.month, oggi.day + 3);

  setUp(() async
  {
    await sl.reset();
    await registraPreferenzeDiTest();
    repo = FakePrenotazioneRepo();
    repoCampo = FakeCampoRepo();
    registraBlocDiTest(repoPartita: FakePartitaRepo(), repoCampo: repoCampo, repoPrenotazione: repo, repoUtente: FakeUtenteRepo());
  });

  tearDown(() async
  {
    await sl.reset();
  });

  //apre la pagina sopra una schermata finta, cosi si puo controllare cosa restituisce con il pop
  Future<List<int?>> apriPagina(WidgetTester tester, {bool? alCoperto}) async
  {
    //schermo da telefono (390x844)
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final risultati = <int?>[];
    await tester.pumpWidget(MaterialApp(
      theme: temaDiTest(),
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async
            {
              final r = await Navigator.push<int>(
                context,
                MaterialPageRoute<int>(builder: (_) => CreaPartitaPage(slot: slotDiTest(), data: data, alCoperto: alCoperto)),
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

  ElevatedButton bottonePrenota(WidgetTester tester)
  {
    return tester.widget<ElevatedButton>(find.byType(ElevatedButton));
  }

  testWidgets("mostra il riepilogo dello slot, le due opzioni e il bottone Prenota", (tester) async
  {
    await apriPagina(tester);

    expect(find.text("Riepilogo partita"), findsOneWidget);
    expect(find.text("${conMaiuscola(giornoRelativo(data))} alle 18:30, Campo Centrale"), findsOneWidget);
    expect(find.text("${conMaiuscola(dataEstesa(data))}, 18:30 - 20:00"), findsOneWidget);
    expect(find.text("Partita pubblica"), findsOneWidget);
    expect(find.text("Partita privata"), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, "Prenota il campo"), findsOneWidget);
    expect(find.text("Tu"), findsOneWidget);
    expect(repo.chiamate, 0);
  });

  testWidgets("il sottotitolo dice se il campo e al coperto, quando si sa", (tester) async
  {
    await apriPagina(tester, alCoperto: true);

    expect(find.text("${conMaiuscola(dataEstesa(data))}, 18:30 - 20:00 · Al coperto"), findsOneWidget);
  });

  testWidgets("il sottotitolo dice se il campo e all'aperto", (tester) async
  {
    await apriPagina(tester, alCoperto: false);

    expect(find.text("${conMaiuscola(dataEstesa(data))}, 18:30 - 20:00 · All'aperto"), findsOneWidget);
  });

  testWidgets("Prenota senza scegliere il tipo mostra l'errore sopra il bottone e resta sulla pagina", (tester) async
  {
    final risultati = await apriPagina(tester);

    await tester.tap(find.text("Prenota il campo"));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(RiquadroMessaggio, TipoPartitaMancante().message), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
    expect(find.text("Riepilogo partita"), findsOneWidget);
    expect(repo.chiamate, 0);
    expect(risultati, isEmpty);
  });

  testWidgets("scegliere il tipo toglie l'errore", (tester) async
  {
    await apriPagina(tester);
    await tester.tap(find.text("Prenota il campo"));
    await tester.pumpAndSettle();

    await tester.tap(find.text("Partita pubblica"));
    await tester.pump();

    expect(find.byType(RiquadroMessaggio), findsNothing);
  });

  testWidgets("scelta del tipo: vale l'ultima toccata e arriva al repository; durante l'invio tutto e fermo", (tester) async
  {
    repo.attesa = Completer<Prenotazione>();
    await apriPagina(tester);

    await tester.tap(find.text("Partita privata"));
    await tester.pump();
    await tester.tap(find.text("Partita pubblica"));
    await tester.pump();

    await tester.tap(find.text("Prenota il campo"));
    await tester.pump();

    expect(repo.tipoRicevuto, "PUBBLICA");
    expect(repo.idCampoRicevuto, 3);
    //durante l'invio il bottone mostra il caricamento ed e disabilitato
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text("Prenota il campo"), findsNothing);
    expect(bottonePrenota(tester).onPressed, isNull);

    repo.attesa!.complete(prenotazioneDiTest());
    await tester.pumpAndSettle();
  });

  testWidgets("successo: la pagina si chiude restituendo l'id della partita creata e compare Partita creata", (tester) async
  {
    final risultati = await apriPagina(tester);

    await tester.tap(find.text("Partita pubblica"));
    await tester.pump();
    await tester.tap(find.text("Prenota il campo"));
    await tester.pumpAndSettle();

    //chi ha aperto la pagina riceve l'id della partita appena creata e aprira lui il dettaglio
    expect(risultati, [10]);
    expect(find.text("Riepilogo partita"), findsNothing);
    expect(find.text("apri"), findsOneWidget);
    expect(find.widgetWithText(SnackBar, "Partita creata"), findsOneWidget);
  });

  testWidgets("400: mostra il messaggio del server sopra il bottone, che torna attivo", (tester) async
  {
    repo.errore = PrenotazioneNonValida(messaggio: "Dati non validi");
    final risultati = await apriPagina(tester);

    await tester.tap(find.text("Partita privata"));
    await tester.pump();
    await tester.tap(find.text("Prenota il campo"));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(RiquadroMessaggio, "Dati non validi"), findsOneWidget);
    expect(find.text("Riepilogo partita"), findsOneWidget);
    expect(risultati, isEmpty);
    expect(bottonePrenota(tester).onPressed, isNotNull);
  });

  testWidgets("la freccia indietro chiude la pagina senza id", (tester) async
  {
    final risultati = await apriPagina(tester);

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
    await tester.pumpAndSettle();

    expect(risultati, [null]);
  });

  group("409: slot appena preso", ()
  {
    Future<void> prenota(WidgetTester tester) async
    {
      await tester.tap(find.text("Partita privata"));
      await tester.pump();
      await tester.tap(find.text("Prenota il campo"));
      await tester.pumpAndSettle();
    }

    setUp(()
    {
      repo.errore = SlotNonDisponibile(messaggio: "Lo slot selezionato è già occupato");
    });

    testWidgets("mostra il messaggio del server e gli altri slot liberi di quel giorno", (tester) async
    {
      repoCampo.slots = [slotCampoDiTest(oraInizio: "20:00:00", oraFine: "21:30:00")];
      final risultati = await apriPagina(tester);

      await prenota(tester);

      expect(find.text("Questo slot non è più disponibile"), findsOneWidget);
      expect(find.text("Lo slot selezionato è già occupato"), findsOneWidget);
      expect(find.text("Ancora liberi ${giornoRelativo(data)}"), findsOneWidget);
      expect(find.text("20:00 - 21:30"), findsOneWidget);
      expect(find.text("Prenota il campo"), findsNothing);
      expect(risultati, isEmpty);
    });

    testWidgets("senza alternative compare solo il messaggio e Vedi tutti gli orari", (tester) async
    {
      repoCampo.slots = [];
      await apriPagina(tester);

      await prenota(tester);

      expect(find.text("Questo slot non è più disponibile"), findsOneWidget);
      expect(find.textContaining("Ancora liberi"), findsNothing);
      expect(find.text("Vedi tutti gli orari"), findsOneWidget);
    });

    testWidgets("toccando un'alternativa si torna al riepilogo col nuovo slot, il tipo si sceglie di nuovo", (tester) async
    {
      repoCampo.slots = [slotCampoDiTest(oraInizio: "20:00:00", oraFine: "21:30:00")];
      await apriPagina(tester, alCoperto: true);
      await prenota(tester);

      await tester.tap(find.text("20:00 - 21:30"));
      await tester.pumpAndSettle();

      expect(find.text("${conMaiuscola(giornoRelativo(data))} alle 20:00, Campo Centrale"), findsOneWidget);
      //di questo slot non si sa se e al coperto
      expect(find.text("${conMaiuscola(dataEstesa(data))}, 20:00 - 21:30"), findsOneWidget);

      //il tipo va riscelto: senza, parte l'errore di validazione e il server non viene chiamato
      final chiamatePrima = repo.chiamate;
      await tester.tap(find.text("Prenota il campo"));
      await tester.pumpAndSettle();
      expect(repo.chiamate, chiamatePrima);
      expect(find.widgetWithText(RiquadroMessaggio, TipoPartitaMancante().message), findsOneWidget);

      //riprovando parte lo slot nuovo
      repo.errore = null;
      await prenota(tester);
      expect(repo.oraInizioRicevuta, "20:00:00");
    });

    testWidgets("Vedi tutti gli orari apre il tabellone sullo stesso giorno", (tester) async
    {
      repoCampo.slots = [];
      await apriPagina(tester);
      await prenota(tester);

      await tester.tap(find.text("Vedi tutti gli orari"));
      await tester.pumpAndSettle();

      expect(find.byType(PrenotaPage), findsOneWidget);
      expect(find.byType(CreaPartitaPage), findsNothing);
      expect(repoCampo.dateRicevute.last, data);
    });
  });
}
