import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thepadel/core/di/depInjection.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/domainLayer/enetity/prenotazione.dart';
import 'package:thepadel/ui/creaPartita.dart';
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

  late FakePrenotazioneRepo repo;
  late FakeCampoRepo repoCampo;
  late FakePartitaRepo repoPartita;

  //una data nel futuro: gli slot alternativi non risultano gia iniziati, qualunque sia l'ora del test
  final oggi = DateTime.now();
  final data = DateTime(oggi.year, oggi.month, oggi.day + 3);

  setUp(() async
  {
    await sl.reset();
    await registraPreferenzeDiTest();
    repo = FakePrenotazioneRepo();
    repoCampo = FakeCampoRepo();
    repoPartita = FakePartitaRepo();
    registraBlocDiTest(repoPartita: repoPartita, repoCampo: repoCampo, repoPrenotazione: repo, repoUtente: FakeUtenteRepo());
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
    //nella pagina c'e un solo bottone pieno, durante l'invio senza testo
    return tester.widget<ElevatedButton>(find.byType(ElevatedButton));
  }

  //i posti vuoti del campo, quelli con il +: l'etichetta si unisce alla scritta Invita sotto il cerchio
  Finder postiLiberi()
  {
    return find.bySemanticsLabel(RegExp("^Posto libero"));
  }

  //sceglie il tipo e aspetta la fine della transizione verso il campo
  Future<void> scegliTipo(WidgetTester tester, String tipo) async
  {
    await tester.tap(find.text(tipo));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
  }

  //apre il foglio dal primo + libero del campo e aspetta la lista
  Future<void> apriFoglioInviti(WidgetTester tester) async
  {
    await tester.tap(postiLiberi().first);
    await tester.pumpAndSettle();
  }

  //il link Invita della riga di un utente nel foglio
  Finder invitaNelFoglio(String nomeCompleto)
  {
    final riga = find.ancestor(of: find.text(nomeCompleto), matching: find.byType(Row)).first;
    return find.descendant(of: riga, matching: find.text("Invita"));
  }

  Future<void> invita(WidgetTester tester, String nomeCompleto) async
  {
    await apriFoglioInviti(tester);
    await tester.tap(invitaNelFoglio(nomeCompleto));
    await tester.pumpAndSettle();
  }

  Future<void> prenota(WidgetTester tester) async
  {
    await tester.tap(find.text("Prenota il campo"));
    await tester.pumpAndSettle();
  }

  testWidgets("mostra una sola frase con data, orario e campo, le due opzioni e Prenota spento", (tester) async
  {
    await apriPagina(tester, alCoperto: true);

    expect(find.text("Riepilogo partita"), findsOneWidget);
    expect(find.text("${conMaiuscola(dataEstesa(data))}, 18:30 - 20:00, Campo Centrale"), findsOneWidget);
    expect(find.textContaining(" alle 18:30"), findsNothing);
    expect(find.textContaining("Al coperto"), findsNothing);
    expect(find.textContaining("posti liberi"), findsNothing);
    expect(find.text("Partita pubblica"), findsOneWidget);
    expect(find.text("Partita privata"), findsOneWidget);
    //il campo compare solo dopo la scelta del tipo
    expect(postiLiberi(), findsNothing);
    expect(bottonePrenota(tester).onPressed, isNull);
    expect(repo.chiamate, 0);
  });

  testWidgets("scelto il tipo i bottoni lasciano il posto al campo, e Prenota si accende solo a transizione finita", (tester) async
  {
    await apriPagina(tester);

    await tester.tap(find.text("Partita privata"));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    //a transizione in corso il bottone e ancora spento
    expect(bottonePrenota(tester).onPressed, isNull);

    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    expect(bottonePrenota(tester).onPressed, isNotNull);
    expect(find.text("Partita pubblica"), findsNothing);
    expect(find.text("Partita privata"), findsNothing);
    expect(find.text("Tu"), findsOneWidget);
    expect(postiLiberi(), findsNWidgets(3));
  });

  testWidgets("senza invitati la prenotazione parte con il tipo scelto e una lista vuota", (tester) async
  {
    repo.attesa = Completer<Prenotazione>();
    await apriPagina(tester);
    await scegliTipo(tester, "Partita pubblica");

    await tester.tap(find.text("Prenota il campo"));
    await tester.pump();

    expect(repo.tipoRicevuto, "PUBBLICA");
    expect(repo.idCampoRicevuto, 3);
    expect(repo.invitatiRicevuti, isEmpty);
    //durante l'invio il bottone mostra il caricamento ed e disabilitato
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(bottonePrenota(tester).onPressed, isNull);

    repo.attesa!.complete(prenotazioneDiTest());
    await tester.pumpAndSettle();
  });

  testWidgets("successo: si va in home, senza tornare indietro, e compare Partita creata", (tester) async
  {
    final risultati = await apriPagina(tester);
    await scegliTipo(tester, "Partita pubblica");

    await prenota(tester);

    expect(find.byType(HomePage), findsOneWidget);
    expect(find.text("Riepilogo partita"), findsNothing);
    expect(find.text("apri"), findsNothing);
    expect(find.widgetWithText(SnackBar, "Partita creata"), findsOneWidget);
    //la pagina non restituisce piu l'id a chi l'ha aperta
    expect(risultati.whereType<int>(), isEmpty);
    final NavigatorState navigator = tester.state(find.byType(Navigator));
    expect(navigator.canPop(), false);
  });

  group("invitati", ()
  {
    testWidgets("il + apre il foglio con gli utenti invitabili senza partita", (tester) async
    {
      await apriPagina(tester);
      await scegliTipo(tester, "Partita privata");

      await apriFoglioInviti(tester);

      expect(find.text("Invita un giocatore"), findsOneWidget);
      expect(find.text("Luca Bianchi"), findsOneWidget);
      expect(find.text("Anna Verdi"), findsOneWidget);
      expect(repoPartita.chiamateUtentiInvitabili, 1);
      expect(repoPartita.cercaUtentiRicevuti, [""]);
    });

    testWidgets("la ricerca parte dopo la pausa di scrittura", (tester) async
    {
      await apriPagina(tester);
      await scegliTipo(tester, "Partita privata");
      await apriFoglioInviti(tester);

      await tester.enterText(find.byType(TextField), "  ann ");
      await tester.pump(const Duration(milliseconds: 200));
      expect(repoPartita.cercaUtentiRicevuti, [""]);

      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(repoPartita.cercaUtentiRicevuti, ["", "ann"]);
    });

    testWidgets("l'utente scelto prende un posto, compare nella lista, non e piu proposto e parte con la prenotazione", (tester) async
    {
      await apriPagina(tester);
      await scegliTipo(tester, "Partita privata");

      await invita(tester, "Luca Bianchi");

      expect(find.text("Invita un giocatore"), findsNothing);
      expect(find.text("Luca Bianchi"), findsOneWidget);
      expect(find.text("Togli"), findsOneWidget);
      expect(postiLiberi(), findsNWidgets(2));

      //chi e gia stato scelto non viene riproposto
      await apriFoglioInviti(tester);
      expect(invitaNelFoglio("Anna Verdi"), findsOneWidget);
      expect(find.descendant(of: find.byType(BottomSheet), matching: find.text("Luca Bianchi")), findsNothing);
      await tester.tap(invitaNelFoglio("Anna Verdi"));
      await tester.pumpAndSettle();

      await prenota(tester);
      expect(repo.invitatiRicevuti, ["3335550001", "3335550002"]);
    });

    testWidgets("Togli libera di nuovo il posto e l'utente non parte con la prenotazione", (tester) async
    {
      await apriPagina(tester);
      await scegliTipo(tester, "Partita privata");
      await invita(tester, "Luca Bianchi");

      await tester.tap(find.text("Togli"));
      await tester.pumpAndSettle();

      expect(find.text("Luca Bianchi"), findsNothing);
      expect(postiLiberi(), findsNWidgets(3));

      await prenota(tester);
      expect(repo.invitatiRicevuti, isEmpty);
    });

    testWidgets("al massimo 3 invitati: con tre scelti non restano posti con il +", (tester) async
    {
      repoPartita.utentiInvitabili = [
        utenteInvitabileDiTest(telefono: "3335550001", nome: "Luca", cognome: "Bianchi"),
        utenteInvitabileDiTest(telefono: "3335550002", nome: "Anna", cognome: "Verdi"),
        utenteInvitabileDiTest(telefono: "3335550003", nome: "Sara", cognome: "Neri"),
        utenteInvitabileDiTest(telefono: "3335550004", nome: "Paolo", cognome: "Gialli"),
      ];
      await apriPagina(tester);
      await scegliTipo(tester, "Partita privata");

      await invita(tester, "Luca Bianchi");
      await invita(tester, "Anna Verdi");
      await invita(tester, "Sara Neri");

      expect(postiLiberi(), findsNothing);
      expect(find.text("Togli"), findsNWidgets(3));
      expect(tester.takeException(), isNull);

      await prenota(tester);
      expect(repo.invitatiRicevuti, ["3335550001", "3335550002", "3335550003"]);
    });

    testWidgets("errore nel caricare gli utenti: messaggio e Riprova nel foglio", (tester) async
    {
      repoPartita.erroreUtentiInvitabili = ErroreGenericoServer();
      await apriPagina(tester);
      await scegliTipo(tester, "Partita privata");
      await apriFoglioInviti(tester);

      expect(find.text("Non siamo riusciti a caricare i giocatori"), findsOneWidget);

      repoPartita.erroreUtentiInvitabili = null;
      await tester.tap(find.text("Riprova"));
      await tester.pumpAndSettle();

      expect(find.text("Luca Bianchi"), findsOneWidget);
    });
  });

  testWidgets("400: mostra il messaggio del server sopra il bottone, che torna attivo", (tester) async
  {
    repo.errore = PrenotazioneNonValida(messaggio: "Dati non validi");
    final risultati = await apriPagina(tester);
    await scegliTipo(tester, "Partita privata");

    await prenota(tester);

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
    setUp(()
    {
      repo.errore = SlotNonDisponibile(messaggio: "Lo slot selezionato è già occupato");
    });

    testWidgets("mostra il messaggio del server e gli altri slot liberi di quel giorno", (tester) async
    {
      repoCampo.slots = [slotCampoDiTest(oraInizio: "20:00:00", oraFine: "21:30:00")];
      final risultati = await apriPagina(tester);
      await scegliTipo(tester, "Partita privata");

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
      await scegliTipo(tester, "Partita privata");

      await prenota(tester);

      expect(find.text("Questo slot non è più disponibile"), findsOneWidget);
      expect(find.textContaining("Ancora liberi"), findsNothing);
      expect(find.text("Vedi tutti gli orari"), findsOneWidget);
    });

    testWidgets("toccando un'alternativa si torna al riepilogo col nuovo slot, tipo e invitati restano", (tester) async
    {
      repoCampo.slots = [slotCampoDiTest(oraInizio: "20:00:00", oraFine: "21:30:00")];
      await apriPagina(tester);
      await scegliTipo(tester, "Partita privata");
      await invita(tester, "Luca Bianchi");
      await prenota(tester);

      await tester.tap(find.text("20:00 - 21:30"));
      await tester.pumpAndSettle();

      expect(find.text("${conMaiuscola(dataEstesa(data))}, 20:00 - 21:30, Campo Centrale"), findsOneWidget);
      expect(find.text("Luca Bianchi"), findsOneWidget);
      expect(bottonePrenota(tester).onPressed, isNotNull);

      repo.errore = null;
      await prenota(tester);
      expect(repo.oraInizioRicevuta, "20:00:00");
      expect(repo.tipoRicevuto, "PRIVATA");
      expect(repo.invitatiRicevuti, ["3335550001"]);
    });

    testWidgets("Vedi tutti gli orari apre il tabellone sullo stesso giorno", (tester) async
    {
      repoCampo.slots = [];
      await apriPagina(tester);
      await scegliTipo(tester, "Partita privata");
      await prenota(tester);

      await tester.tap(find.text("Vedi tutti gli orari"));
      await tester.pumpAndSettle();

      expect(find.byType(PrenotaPage), findsOneWidget);
      expect(find.byType(CreaPartitaPage), findsNothing);
      expect(repoCampo.dateRicevute.last, data);
    });
  });
}
