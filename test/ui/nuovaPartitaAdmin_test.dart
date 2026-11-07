import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thepadel/core/di/depInjection.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/domainLayer/enetity/slotOrario.dart';
import 'package:thepadel/ui/dettaglioAdmin.dart';
import 'package:thepadel/ui/nuovaPartitaAdmin.dart';
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
  late FakeCampoRepo repoCampo;
  late FakePartitaRepo repoPartita;

  final adesso = DateTime.now();
  //i test scelgono domani: nessuno slot risulta gia iniziato, qualunque sia l'ora in cui girano
  final domani = DateTime(adesso.year, adesso.month, adesso.day + 1);

  setUp(() async
  {
    await sl.reset();
    await registraPreferenzeDiTest();
    repo = FakeAdminRepo();
    repo.utenti = [
      utenteAdminDiTest(telefono: "1", nome: "Luca", cognome: "Bianchi"),
      utenteAdminDiTest(telefono: "2", nome: "Anna", cognome: "Verdi"),
      utenteAdminDiTest(telefono: "3", nome: "Paolo", cognome: "Neri"),
      utenteAdminDiTest(telefono: "4", nome: "Sara", cognome: "Gialli"),
      utenteAdminDiTest(telefono: "5", nome: "Marco", cognome: "Blu"),
    ];
    repoCampo = FakeCampoRepo();
    repoPartita = FakePartitaRepo();
    repoPartita.partiteStorico = [];
    registraBlocDiTest(repoPartita: repoPartita, repoCampo: repoCampo, repoPrenotazione: FakePrenotazioneRepo(), repoUtente: FakeUtenteRepo(), repoAdmin: repo);
  });

  tearDown(() async
  {
    await sl.reset();
  });

  //schermo alto: cosi tutta la pagina e visibile e i test non devono scorrerla
  Future<void> apriPagina(WidgetTester tester, {Size schermo = const Size(390, 1500)}) async
  {
    tester.view.physicalSize = schermo * 3.0;
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(theme: temaDiTest(), home: const NuovaPartitaAdminPage()));
    await tester.pumpAndSettle();

    await tester.tap(find.byWidgetPredicate((widget) => widget is Semantics && widget.properties.label == dataEstesa(domani)));
    await tester.pumpAndSettle();
  }

  bool creaAttivo(WidgetTester tester)
  {
    return tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, "Crea partita")).onPressed != null;
  }

  Finder aggiungi()
  {
    return find.widgetWithText(TextButton, "Aggiungi");
  }

  Future<void> tocca(WidgetTester tester, Finder bersaglio) async
  {
    await tester.tap(bersaglio);
    await tester.pumpAndSettle();
  }

  Future<void> aggiungiCampo(WidgetTester tester) async
  {
    await tocca(tester, find.byTooltip("Aggiungi un giocatore del campo"));
  }

  bool piuCampoAttivo(WidgetTester tester)
  {
    final Finder bottone = find.ancestor(of: find.byIcon(Icons.add_circle_outline), matching: find.byType(IconButton));
    return tester.widget<IconButton>(bottone).onPressed != null;
  }

  Future<void> compilaTutto(WidgetTester tester) async
  {
    await tocca(tester, find.text("Libero"));
    await tocca(tester, find.text("Pubblica"));
    await tocca(tester, aggiungi().first);
  }

  testWidgets("su un telefono piccolo la pagina non va in overflow", (tester) async
  {
    await apriPagina(tester, schermo: const Size(320, 568));

    expect(tester.takeException(), isNull);
    expect(find.widgetWithText(ElevatedButton, "Crea partita"), findsOneWidget);
  });

  group("bottone Crea partita", ()
  {
    testWidgets("all'inizio e spento", (tester) async
    {
      await apriPagina(tester);

      expect(creaAttivo(tester), false);
      expect(find.text("Giocatori, 0 su 4"), findsOneWidget);
    });

    testWidgets("serve slot, tipo e un utente: con due su tre resta spento", (tester) async
    {
      await apriPagina(tester);

      await tocca(tester, find.text("Libero"));
      expect(creaAttivo(tester), false);

      await tocca(tester, find.text("Pubblica"));
      expect(creaAttivo(tester), false);

      await tocca(tester, aggiungi().first);
      expect(creaAttivo(tester), true);
    });

    testWidgets("solo giocatori del campo non bastano", (tester) async
    {
      await apriPagina(tester);

      await tocca(tester, find.text("Libero"));
      await tocca(tester, find.text("Privata"));
      await aggiungiCampo(tester);

      expect(creaAttivo(tester), false);
    });

    testWidgets("togliendo l'unico utente si spegne di nuovo", (tester) async
    {
      await apriPagina(tester);
      await compilaTutto(tester);

      await tocca(tester, find.widgetWithText(TextButton, "Rimuovi"));

      expect(creaAttivo(tester), false);
    });

    testWidgets("togliendo lo slot si spegne di nuovo", (tester) async
    {
      await apriPagina(tester);
      await compilaTutto(tester);

      await tocca(tester, find.text("Scelto"));

      expect(creaAttivo(tester), false);
    });

    testWidgets("cambiando giorno lo slot scelto si perde", (tester) async
    {
      await apriPagina(tester);
      await compilaTutto(tester);
      expect(creaAttivo(tester), true);

      final dopodomani = DateTime(adesso.year, adesso.month, adesso.day + 2);
      await tocca(tester, find.byWidgetPredicate((widget) => widget is Semantics && widget.properties.label == dataEstesa(dopodomani)));

      expect(creaAttivo(tester), false);
      expect(find.text("Tocca uno slot libero per sceglierlo"), findsOneWidget);
    });
  });

  group("limite di 4 posti", ()
  {
    testWidgets("senza utenti i giocatori del campo arrivano al massimo a 3", (tester) async
    {
      await apriPagina(tester);

      await aggiungiCampo(tester);
      await aggiungiCampo(tester);
      expect(piuCampoAttivo(tester), true);
      await aggiungiCampo(tester);

      expect(find.text("Giocatori, 3 su 4"), findsOneWidget);
      expect(piuCampoAttivo(tester), false);
    });

    testWidgets("con 3 giocatori del campo si puo aggiungere un solo utente", (tester) async
    {
      await apriPagina(tester);
      await aggiungiCampo(tester);
      await aggiungiCampo(tester);
      await aggiungiCampo(tester);

      await tocca(tester, aggiungi().first);

      expect(find.text("Giocatori, 4 su 4"), findsOneWidget);
      for(final bottone in tester.widgetList<TextButton>(aggiungi()))
      {
        expect(bottone.onPressed, isNull);
      }
    });

    testWidgets("con 2 utenti i giocatori del campo si fermano a 2", (tester) async
    {
      await apriPagina(tester);
      await tocca(tester, aggiungi().first);
      await tocca(tester, aggiungi().first);

      await aggiungiCampo(tester);
      await aggiungiCampo(tester);

      expect(find.text("Giocatori, 4 su 4"), findsOneWidget);
      expect(piuCampoAttivo(tester), false);
    });

    testWidgets("con 4 utenti non si aggiunge nessun giocatore del campo e il quinto utente e spento", (tester) async
    {
      await apriPagina(tester);
      for(int i = 0; i < 4; i++)
      {
        await tocca(tester, aggiungi().first);
      }

      expect(find.text("Giocatori, 4 su 4"), findsOneWidget);
      expect(piuCampoAttivo(tester), false);
      expect(tester.widget<TextButton>(aggiungi()).onPressed, isNull);
    });

    testWidgets("togliere un giocatore del campo libera il posto", (tester) async
    {
      await apriPagina(tester);
      await aggiungiCampo(tester);
      await aggiungiCampo(tester);
      await aggiungiCampo(tester);

      await tocca(tester, find.byTooltip("Togli un giocatore del campo"));

      expect(find.text("Giocatori, 2 su 4"), findsOneWidget);
      expect(piuCampoAttivo(tester), true);
    });
  });

  group("ricerca utenti", ()
  {
    testWidgets("chi e gia scelto non viene riproposto, e torna se lo si toglie", (tester) async
    {
      repo.utenti = [utenteAdminDiTest(telefono: "1", nome: "Luca", cognome: "Bianchi")];
      await apriPagina(tester);

      await tocca(tester, aggiungi());

      expect(aggiungi(), findsNothing);
      expect(find.text("Nessun utente trovato"), findsOneWidget);
      expect(find.text("Luca Bianchi"), findsOneWidget);

      await tocca(tester, find.widgetWithText(TextButton, "Rimuovi"));

      expect(aggiungi(), findsOneWidget);
    });

    testWidgets("la ricerca parte solo dopo la pausa di scrittura", (tester) async
    {
      await apriPagina(tester);
      repo.cercaRicevuti.clear();

      await tester.enterText(find.byType(TextField), " lu ");
      await tester.pump(const Duration(milliseconds: 399));
      expect(repo.cercaRicevuti, isEmpty);

      await tester.pump(const Duration(milliseconds: 2));
      await tester.pumpAndSettle();
      expect(repo.cercaRicevuti, ["lu"]);
    });

    testWidgets("se la ricerca fallisce c'e la card con Riprova", (tester) async
    {
      repo.erroreUtenti = ErroreGenericoServer();
      await apriPagina(tester);

      expect(find.text("Non siamo riusciti a caricare gli utenti"), findsOneWidget);

      repo.erroreUtenti = null;
      await tocca(tester, find.text("Riprova"));

      expect(aggiungi(), findsWidgets);
    });
  });

  group("creazione", ()
  {
    testWidgets("manda i dati scelti e apre il dettaglio della partita creata", (tester) async
    {
      repo.rispostaCreaPartita = dettaglioDiTest(id: 33);
      repoPartita.risposta = dettaglioDiTest(id: 33);
      await apriPagina(tester);

      await tocca(tester, find.text("Libero"));
      await tocca(tester, find.text("Privata"));
      await tocca(tester, aggiungi().first);
      await aggiungiCampo(tester);
      await tocca(tester, find.widgetWithText(ElevatedButton, "Crea partita"));

      expect(repo.chiamateCreaPartita, 1);
      expect(repo.idCampoCreaRicevuto, 3);
      expect(repo.dataCreaRicevuta, domani);
      expect(repo.oraCreaRicevuta, "18:30:00");
      expect(repo.tipoCreaRicevuto, "PRIVATA");
      expect(repo.telefoniCreaRicevuti, ["1"]);
      expect(repo.giocatoriCampoCreaRicevuti, 1);

      expect(find.byType(NuovaPartitaAdminPage), findsNothing);
      expect(find.byType(DettaglioAdminPage), findsOneWidget);
      expect(repoPartita.idRicevuto, 33);
      expect(find.text("Partita creata"), findsOneWidget);
    });

    testWidgets("durante la creazione il bottone e spento con lo spinner", (tester) async
    {
      final attesa = Completer<void>();
      repo.attesaCreaPartita = attesa;
      await apriPagina(tester);
      await compilaTutto(tester);

      await tester.tap(find.widgetWithText(ElevatedButton, "Crea partita"));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text("Crea partita"), findsNothing);

      attesa.complete();
      await tester.pumpAndSettle();

      expect(find.byType(DettaglioAdminPage), findsOneWidget);
    });

    testWidgets("se il server rifiuta: messaggio nel riquadro, tabellone ricaricato, scelte tenute", (tester) async
    {
      repo.erroreCreaPartita = OperazioneRifiutata(messaggio: "Lo slot è occupato");
      await apriPagina(tester);
      await compilaTutto(tester);
      final int slotPrima = repoCampo.chiamateSlot;

      await tocca(tester, find.widgetWithText(ElevatedButton, "Crea partita"));

      expect(find.descendant(of: find.byType(RiquadroMessaggio), matching: find.text("Lo slot è occupato")), findsOneWidget);
      expect(find.byType(NuovaPartitaAdminPage), findsOneWidget);
      expect(repoCampo.chiamateSlot, slotPrima + 1);
      expect(creaAttivo(tester), true);
    });

    testWidgets("se lo slot scelto risulta occupato dopo il rifiuto non resta selezionato", (tester) async
    {
      repo.erroreCreaPartita = OperazioneRifiutata(messaggio: "Lo slot è occupato");
      await apriPagina(tester);
      await compilaTutto(tester);
      repoCampo.slots = [slotCampoDiTest(disponibile: false)];

      await tocca(tester, find.widgetWithText(ElevatedButton, "Crea partita"));

      expect(creaAttivo(tester), false);
      expect(find.text("Tocca uno slot libero per sceglierlo"), findsOneWidget);
    });
  });

  group("giorno e slot iniziali", ()
  {
    Future<void> apriConParametri(WidgetTester tester, {DateTime? giorno, SlotOrario? slot}) async
    {
      tester.view.physicalSize = const Size(390, 1500) * 3.0;
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(MaterialApp(theme: temaDiTest(), home: NuovaPartitaAdminPage(giornoIniziale: giorno, slotIniziale: slot)));
      await tester.pumpAndSettle();
    }

    testWidgets("senza parametri carica oggi e nessuno slot e scelto", (tester) async
    {
      await apriConParametri(tester);

      expect(repoCampo.dateRicevute, [DateTime(adesso.year, adesso.month, adesso.day)]);
      expect(find.text("Tocca uno slot libero per sceglierlo"), findsOneWidget);
      expect(find.text("Scelto"), findsNothing);
    });

    testWidgets("con giorno e slot carica solo quel giorno e lo slot risulta gia scelto", (tester) async
    {
      await apriConParametri(tester, giorno: domani, slot: slotCampoDiTest());

      expect(repoCampo.dateRicevute, [domani]);
      expect(find.text("Scelto"), findsOneWidget);
      expect(find.text("Campo Centrale, ${dataEstesa(domani)}, 18:30 - 20:00"), findsOneWidget);
    });

    testWidgets("con lo slot iniziale bastano tipo e utente e la partita parte con giorno e ora giusti", (tester) async
    {
      repo.rispostaCreaPartita = dettaglioDiTest(id: 33);
      repoPartita.risposta = dettaglioDiTest(id: 33);
      await apriConParametri(tester, giorno: domani, slot: slotCampoDiTest());

      await tocca(tester, find.text("Pubblica"));
      await tocca(tester, aggiungi().first);
      expect(creaAttivo(tester), true);

      await tocca(tester, find.widgetWithText(ElevatedButton, "Crea partita"));

      expect(repo.idCampoCreaRicevuto, 3);
      expect(repo.dataCreaRicevuta, domani);
      expect(repo.oraCreaRicevuta, "18:30:00");
    });

    testWidgets("se lo slot iniziale nel frattempo e stato occupato non resta scelto", (tester) async
    {
      repoCampo.slots = [slotCampoDiTest(disponibile: false)];
      await apriConParametri(tester, giorno: domani, slot: slotCampoDiTest());

      expect(find.text("Scelto"), findsNothing);
      expect(find.text("Tocca uno slot libero per sceglierlo"), findsOneWidget);
    });
  });
}
