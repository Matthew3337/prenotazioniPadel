import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thepadel/core/di/depInjection.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/ui/creaPartita.dart';
import 'package:thepadel/ui/dettaglioPartita.dart';
import 'package:thepadel/ui/home.dart';
import 'package:thepadel/ui/prenota.dart';
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

  late FakeCampoRepo repoCampo;
  late FakePartitaRepo repoPartita;
  late FakePrenotazioneRepo repoPrenotazione;

  final adesso = DateTime.now();
  final oggi = DateTime(adesso.year, adesso.month, adesso.day);
  //i test aprono domani: nessuno slot risulta gia iniziato, qualunque sia l'ora in cui girano
  final domani = DateTime(adesso.year, adesso.month, adesso.day + 1);

  setUp(() async
  {
    await sl.reset();
    await registraPreferenzeDiTest();
    repoCampo = FakeCampoRepo();
    repoPartita = FakePartitaRepo();
    repoPartita.partiteMie = [];
    repoPrenotazione = FakePrenotazioneRepo();
    registraBlocDiTest(repoPartita: repoPartita, repoCampo: repoCampo, repoPrenotazione: repoPrenotazione, repoUtente: FakeUtenteRepo());
  });

  tearDown(() async
  {
    await sl.reset();
  });

  Future<void> apriPagina(WidgetTester tester, {DateTime? giorno, Size schermo = const Size(390, 844)}) async
  {
    tester.view.physicalSize = schermo * 3.0;
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(theme: temaDiTest(), home: PrenotaPage(giornoIniziale: giorno)));
    await tester.pumpAndSettle();
  }

  //la casella di un giorno nella barra in alto
  Finder casellaGiorno(DateTime giorno)
  {
    return find.byWidgetPredicate((widget) => widget is Semantics && widget.properties.label == dataEstesa(giorno));
  }

  testWidgets("senza giorno iniziale apre oggi e mostra i 16 giorni selezionabili, senza sottotitolo", (tester) async
  {
    repoCampo.slots = [];
    await apriPagina(tester);

    expect(find.text("Prenota un campo"), findsOneWidget);
    expect(repoCampo.dateRicevute, [oggi]);
    for(int i = 0; i <= 15; i++)
    {
      expect(casellaGiorno(DateTime(oggi.year, oggi.month, oggi.day + i)), findsOneWidget);
    }
    expect(casellaGiorno(DateTime(oggi.year, oggi.month, oggi.day + 16)), findsNothing);
    expect(find.textContaining("slot liber"), findsNothing);
  });

  testWidgets("la barra dei 16 giorni scorre di lato e non va in overflow a 320 px", (tester) async
  {
    await apriPagina(tester, schermo: const Size(320, 568));
    final ultimo = DateTime(oggi.year, oggi.month, oggi.day + 15);

    expect(tester.takeException(), isNull);
    await tester.ensureVisible(casellaGiorno(ultimo));
    await tester.pumpAndSettle();
    await tester.tap(casellaGiorno(ultimo));
    await tester.pumpAndSettle();

    expect(repoCampo.dateRicevute.last, ultimo);
  });

  testWidgets("con il giorno iniziale apre quel giorno", (tester) async
  {
    await apriPagina(tester, giorno: domani);

    expect(repoCampo.dateRicevute, [domani]);
    expect(find.text("Libero"), findsOneWidget);
  });

  testWidgets("toccare un giorno carica quel giorno", (tester) async
  {
    await apriPagina(tester);
    final dopodomani = DateTime(oggi.year, oggi.month, oggi.day + 2);

    await tester.tap(casellaGiorno(dopodomani));
    await tester.pumpAndSettle();

    expect(repoCampo.dateRicevute.last, dopodomani);
    expect(find.text("Libero"), findsOneWidget);
  });

  group("tabellone", ()
  {
    testWidgets("mostra i campi con coperto o aperto, le ore e il conteggio dei liberi", (tester) async
    {
      repoCampo.campi = [campoDiTest(id: 1, nome: "Uno"), campoDiTest(id: 2, nome: "Due", alCoperto: false)];
      repoCampo.slots = [
        slotCampoDiTest(idCampo: 1, nomeCampo: "Uno", oraInizio: "18:00:00"),
        slotCampoDiTest(idCampo: 1, nomeCampo: "Uno", oraInizio: "19:30:00", disponibile: false),
        slotCampoDiTest(idCampo: 2, nomeCampo: "Due", oraInizio: "18:00:00"),
      ];
      await apriPagina(tester, giorno: domani);

      expect(find.text("Uno"), findsOneWidget);
      expect(find.text("Al coperto"), findsOneWidget);
      expect(find.text("Due"), findsOneWidget);
      expect(find.text("All'aperto"), findsOneWidget);
      expect(find.text("18:00"), findsOneWidget);
      expect(find.text("19:30"), findsOneWidget);
      expect(find.text("Libero"), findsNWidgets(2));
      expect(find.text("Occupato"), findsOneWidget);
      //gli occupati sono rossi
      expect(tester.widget<Text>(find.text("Occupato")).style!.color, Colori.rosso);
    });

    testWidgets("gli orari dopo mezzanotte stanno in fondo", (tester) async
    {
      repoCampo.slots = [slotCampoDiTest(oraInizio: "00:30:00"), slotCampoDiTest(oraInizio: "22:00:00")];
      await apriPagina(tester, giorno: domani);

      expect(tester.getTopLeft(find.text("22:00")).dy, lessThan(tester.getTopLeft(find.text("00:30")).dy));
    });

    testWidgets("se un campo a quell'ora e chiuso la casella resta vuota", (tester) async
    {
      repoCampo.campi = [campoDiTest(id: 1, nome: "Uno"), campoDiTest(id: 2, nome: "Due")];
      repoCampo.slots = [slotCampoDiTest(idCampo: 1, nomeCampo: "Uno", oraInizio: "18:00:00")];
      await apriPagina(tester, giorno: domani);

      expect(find.text("18:00"), findsOneWidget);
      expect(find.text("Libero"), findsOneWidget);
    });

    testWidgets("uno slot gia iniziato non viene costruito, anche se il server lo da per libero", (tester) async
    {
      repoCampo.campi = [campoDiTest(oraApertura: const TimeOfDay(hour: 0, minute: 0))];
      repoCampo.slots = [slotCampoDiTest(oraInizio: "00:00:00", oraFine: "01:00:00")];
      await apriPagina(tester);

      expect(find.text("Passato"), findsNothing);
      expect(find.text("00:00"), findsNothing);
      expect(find.text("Libero"), findsNothing);
      expect(find.text("Nessun orario disponibile per questo giorno."), findsOneWidget);
    });

    testWidgets("le righe partono dal primo slot non ancora iniziato, anche se occupato", (tester) async
    {
      repoCampo.campi = [campoDiTest(oraApertura: const TimeOfDay(hour: 0, minute: 0))];
      repoCampo.slots = [
        slotCampoDiTest(oraInizio: "00:00:00", oraFine: "01:00:00"),
        slotCampoDiTest(oraInizio: "23:59:00", oraFine: "01:00:00", disponibile: false),
      ];
      await apriPagina(tester);

      expect(find.text("00:00"), findsNothing);
      expect(find.text("23:59"), findsOneWidget);
      expect(find.text("Occupato"), findsOneWidget);
    });

    testWidgets("nessun orario per quel giorno: lo dice", (tester) async
    {
      repoCampo.slots = [];
      await apriPagina(tester, giorno: domani);

      expect(find.text("Nessun orario disponibile per questo giorno."), findsOneWidget);
    });

    testWidgets("con tanti campi il tabellone scorre e non va in overflow", (tester) async
    {
      repoCampo.campi = [for(int i = 1; i <= 6; i++) campoDiTest(id: i, nome: "Campo $i")];
      repoCampo.slots = [for(int i = 1; i <= 6; i++) slotCampoDiTest(idCampo: i, nomeCampo: "Campo $i")];
      await apriPagina(tester, giorno: domani, schermo: const Size(320, 568));

      expect(tester.takeException(), isNull);
      expect(find.text("Campo 1"), findsOneWidget);
    });

    testWidgets("la propria partita e La tua partita, non conta tra i liberi e apre il dettaglio", (tester) async
    {
      repoPartita.partiteMie = [partitaStoricoDiTest(id: 77, dataPartita: domani)];
      await apriPagina(tester, giorno: domani);

      expect(find.text("La tua partita"), findsOneWidget);
      expect(find.text("Libero"), findsNothing);

      await tester.tap(find.text("La tua partita"));
      await tester.pumpAndSettle();

      expect(find.byType(DettaglioPartitaPage), findsOneWidget);
      expect(repoPartita.idRicevuto, 77);

      //al ritorno il tabellone si ricarica
      final chiamatePrima = repoCampo.chiamateSlot;
      final NavigatorState navigator = tester.state(find.byType(Navigator));
      navigator.pop();
      await tester.pumpAndSettle();

      expect(repoCampo.chiamateSlot, chiamatePrima + 1);
    });

    testWidgets("una propria partita in un altro giorno non si vede", (tester) async
    {
      repoPartita.partiteMie = [partitaStoricoDiTest(dataPartita: oggi)];
      await apriPagina(tester, giorno: domani);

      expect(find.text("La tua partita"), findsNothing);
      expect(find.text("Libero"), findsOneWidget);
    });
  });

  group("scelta dello slot", ()
  {
    testWidgets("il tocco su Libero lo sceglie e mostra Continua col riepilogo", (tester) async
    {
      await apriPagina(tester, giorno: domani);
      expect(find.text("Continua"), findsNothing);

      await tester.tap(find.text("Libero"));
      await tester.pump();

      expect(find.text("Scelto"), findsOneWidget);
      expect(find.text("Libero"), findsNothing);
      expect(find.text("Campo Centrale, ${nomeGiorno(domani)} ${domani.day}"), findsOneWidget);
      expect(find.text("18:30 - 20:00"), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, "Continua"), findsOneWidget);
    });

    testWidgets("un secondo tocco toglie la scelta", (tester) async
    {
      await apriPagina(tester, giorno: domani);

      await tester.tap(find.text("Libero"));
      await tester.pump();
      await tester.tap(find.text("Scelto"));
      await tester.pump();

      expect(find.text("Libero"), findsOneWidget);
      expect(find.text("Continua"), findsNothing);
    });

    testWidgets("cambiare giorno toglie la scelta", (tester) async
    {
      await apriPagina(tester, giorno: domani);
      await tester.tap(find.text("Libero"));
      await tester.pump();

      await tester.tap(casellaGiorno(oggi));
      await tester.pumpAndSettle();

      expect(find.text("Continua"), findsNothing);
    });

    testWidgets("Continua apre il riepilogo col giorno e col dato del coperto", (tester) async
    {
      await apriPagina(tester, giorno: domani);
      await tester.tap(find.text("Libero"));
      await tester.pump();

      await tester.tap(find.text("Continua"));
      await tester.pumpAndSettle();

      expect(find.byType(CreaPartitaPage), findsOneWidget);
      final pagina = tester.widget<CreaPartitaPage>(find.byType(CreaPartitaPage));
      expect(pagina.data, domani);
      expect(pagina.slot.oraInizio, "18:30:00");
      expect(pagina.alCoperto, true);
    });

    testWidgets("tornando indietro senza creare la scelta resta e il tabellone non si ricarica", (tester) async
    {
      await apriPagina(tester, giorno: domani);
      await tester.tap(find.text("Libero"));
      await tester.pump();
      await tester.tap(find.text("Continua"));
      await tester.pumpAndSettle();

      final chiamatePrima = repoCampo.chiamateSlot;
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
      await tester.pumpAndSettle();

      expect(find.text("Scelto"), findsOneWidget);
      expect(repoCampo.chiamateSlot, chiamatePrima);
    });

    testWidgets("partita creata: si torna in home e non si apre il dettaglio", (tester) async
    {
      await apriPagina(tester, giorno: domani);
      await tester.tap(find.text("Libero"));
      await tester.pump();
      await tester.tap(find.text("Continua"));
      await tester.pumpAndSettle();

      await tester.tap(find.text("Partita pubblica"));
      //Prenota il campo si accende solo a transizione finita
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      await tester.tap(find.text("Prenota il campo"));
      await tester.pumpAndSettle();

      expect(repoPrenotazione.chiamate, 1);
      expect(repoPrenotazione.dataRicevuta, domani);
      expect(find.byType(HomePage), findsOneWidget);
      expect(find.byType(DettaglioPartitaPage), findsNothing);
      expect(find.byType(PrenotaPage), findsNothing);
      //la home non si puo chiudere tornando alla prenotazione
      final NavigatorState navigator = tester.state(find.byType(Navigator));
      expect(navigator.canPop(), false);
    });
  });

  group("errori", ()
  {
    testWidgets("errore di caricamento: messaggio col giorno, la barra dei giorni resta e Riprova ricarica", (tester) async
    {
      repoCampo.erroreSlot = ErroreGenericoServer();
      await apriPagina(tester, giorno: domani);

      expect(find.text("Non siamo riusciti a caricare gli orari di ${nomeGiorno(domani)}"), findsOneWidget);
      expect(find.text("Puoi riprovare o scegliere un altro giorno."), findsOneWidget);
      expect(casellaGiorno(oggi), findsOneWidget);

      repoCampo.erroreSlot = null;
      await tester.tap(find.text("Riprova"));
      await tester.pumpAndSettle();

      expect(find.text("Libero"), findsOneWidget);
      expect(find.text("Riprova"), findsNothing);
      expect(repoCampo.dateRicevute.last, domani);
    });

    testWidgets("se le mie partite non arrivano il tabellone si vede lo stesso", (tester) async
    {
      repoPartita.erroreMie = ErroreGenericoServer();
      await apriPagina(tester, giorno: domani);

      expect(find.text("Libero"), findsOneWidget);
    });
  });

  testWidgets("la voce Prenota della barra e attiva: toccarla non ricarica", (tester) async
  {
    await apriPagina(tester, giorno: domani);
    final chiamatePrima = repoCampo.chiamateSlot;

    await tester.tap(find.text("Prenota"));
    await tester.pumpAndSettle();

    expect(repoCampo.chiamateSlot, chiamatePrima);
  });
}
