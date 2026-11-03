import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thepadel/core/di/depInjection.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/domainLayer/enetity/postoPartita.dart';
import 'package:thepadel/ui/dettaglioAdmin.dart';
import 'package:thepadel/ui/modificaPartecipanti.dart';

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
  late FakePartitaRepo repoPartita;

  setUp(() async
  {
    await sl.reset();
    await registraPreferenzeDiTest();
    repo = FakeAdminRepo();
    repo.utenti = [
      utenteAdminDiTest(telefono: "3335550001", nome: "Luca", cognome: "Bianchi", livello: 3.0),
      utenteAdminDiTest(telefono: "3335559999", nome: "Elena", cognome: "Gialli", livello: 1.5),
    ];
    repoPartita = FakePartitaRepo();
    repoPartita.risposta = dettaglioDiTest(posti: quattroPostiDiTest(), stato: "confermata");
    registraBlocDiTest(repoPartita: repoPartita, repoCampo: FakeCampoRepo(), repoPrenotazione: FakePrenotazioneRepo(), repoUtente: FakeUtenteRepo(), repoAdmin: repo);
  });

  tearDown(() async
  {
    await sl.reset();
  });

  //si passa dal dettaglio: la pagina riceve il suo stesso bloc, gia con la partita caricata
  Future<void> apriPagina(WidgetTester tester) async
  {
    tester.view.physicalSize = const Size(1170, 3600);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(theme: temaDiTest(), home: const DettaglioAdminPage(idPartita: 10)));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, "Modifica partecipanti"));
    await tester.pumpAndSettle();
  }

  Finder rimuoviDi(String nome)
  {
    final riga = find.ancestor(of: find.text(nome), matching: find.byType(Row)).first;
    return find.descendant(of: riga, matching: find.widgetWithText(TextButton, "Rimuovi"));
  }

  Finder aggiungiDi(String nome)
  {
    final riga = find.ancestor(of: find.text(nome), matching: find.byType(Row)).first;
    return find.descendant(of: riga, matching: find.widgetWithText(TextButton, "Aggiungi"));
  }

  testWidgets("all'apertura mostra i partecipanti e carica la ricerca", (tester) async
  {
    await apriPagina(tester);

    expect(find.text("Giocatori, 4 su 4"), findsOneWidget);
    expect(find.text("Mario Rossi"), findsOneWidget);
    expect(find.text("Luca Bianchi"), findsOneWidget);
    expect(find.text("Anna Verdi"), findsOneWidget);
    expect(find.text("Giocatore del campo"), findsOneWidget);
    expect(repo.cercaRicevuti, [""]);
  });

  group("rimuovi", ()
  {
    testWidgets("tutti gli utenti si possono rimuovere, creatore compreso, il posto del campo no", (tester) async
    {
      await apriPagina(tester);

      expect(find.text("Organizzatore"), findsOneWidget);
      expect(rimuoviDi("Mario Rossi"), findsOneWidget);
      expect(rimuoviDi("Giocatore del campo"), findsNothing);
      expect(find.widgetWithText(TextButton, "Rimuovi"), findsNWidgets(3));
    });

    testWidgets("togliere un giocatore aggiorna il conto e lo ripropone nella ricerca, senza chiamare il server", (tester) async
    {
      await apriPagina(tester);
      //Luca e gia in partita: non e tra quelli da aggiungere
      expect(aggiungiDi("Elena Gialli"), findsOneWidget);
      expect(find.widgetWithText(TextButton, "Aggiungi"), findsOneWidget);

      await tester.tap(rimuoviDi("Luca Bianchi"));
      await tester.pumpAndSettle();

      expect(find.text("Giocatori, 3 su 4"), findsOneWidget);
      expect(rimuoviDi("Luca Bianchi"), findsNothing);
      expect(aggiungiDi("Luca Bianchi"), findsOneWidget);
      expect(repo.chiamatePartecipanti, 0);
    });
  });

  group("limite di 4", ()
  {
    testWidgets("con 4 giocatori Aggiungi e spento, togliendone uno si accende", (tester) async
    {
      await apriPagina(tester);

      expect(tester.widget<TextButton>(aggiungiDi("Elena Gialli")).onPressed, isNull);

      await tester.tap(rimuoviDi("Anna Verdi"));
      await tester.pumpAndSettle();

      expect(tester.widget<TextButton>(aggiungiDi("Elena Gialli")).onPressed, isNotNull);
    });

    testWidgets("i posti del campo contano nel limite", (tester) async
    {
      repoPartita.risposta = dettaglioDiTest(posti: [
        PostoPartita(idPosto: 11, tipo: "UTENTE", telefono: "3331234567", nome: "Mario", cognome: "Rossi", livello: 2.5, confermata: true, squadra: null),
        PostoPartita(idPosto: 12, tipo: "CAMPO", telefono: null, nome: null, cognome: null, livello: null, confermata: false, squadra: null),
        PostoPartita(idPosto: 13, tipo: "CAMPO", telefono: null, nome: null, cognome: null, livello: null, confermata: false, squadra: null),
        PostoPartita(idPosto: 14, tipo: "CAMPO", telefono: null, nome: null, cognome: null, livello: null, confermata: false, squadra: null),
      ], stato: "creata");
      await apriPagina(tester);

      expect(find.text("Giocatori, 4 su 4"), findsOneWidget);
      expect(tester.widget<TextButton>(aggiungiDi("Elena Gialli")).onPressed, isNull);
    });

    testWidgets("aggiungendo fino a 4 gli altri restano spenti", (tester) async
    {
      repoPartita.risposta = dettaglioDiTest(stato: "creata");
      repo.utenti = [
        utenteAdminDiTest(telefono: "1", nome: "Elena", cognome: "Gialli"),
        utenteAdminDiTest(telefono: "2", nome: "Paola", cognome: "Neri"),
        utenteAdminDiTest(telefono: "3", nome: "Sara", cognome: "Blu"),
      ];
      await apriPagina(tester);
      expect(find.text("Giocatori, 2 su 4"), findsOneWidget);

      await tester.tap(aggiungiDi("Elena Gialli"));
      await tester.pumpAndSettle();
      await tester.tap(aggiungiDi("Paola Neri"));
      await tester.pumpAndSettle();

      expect(find.text("Giocatori, 4 su 4"), findsOneWidget);
      expect(aggiungiDi("Elena Gialli"), findsNothing);
      expect(tester.widget<TextButton>(aggiungiDi("Sara Blu")).onPressed, isNull);
    });
  });

  group("ricerca", ()
  {
    testWidgets("parte 400 ms dopo l'ultima lettera", (tester) async
    {
      await apriPagina(tester);

      await tester.enterText(find.byType(TextField), "el");
      await tester.pump(const Duration(milliseconds: 399));
      expect(repo.cercaRicevuti, [""]);

      await tester.pump(const Duration(milliseconds: 1));
      await tester.pumpAndSettle();
      expect(repo.cercaRicevuti, ["", "el"]);
    });

    testWidgets("nessun altro utente da proporre", (tester) async
    {
      repo.utenti = [utenteAdminDiTest(telefono: "3335550001", nome: "Luca", cognome: "Bianchi")];
      await apriPagina(tester);

      expect(find.text("Nessun utente trovato"), findsOneWidget);
    });

    testWidgets("in errore mostra il messaggio e Riprova ricarica", (tester) async
    {
      repo.erroreUtenti = ErroreGenericoServer();
      await apriPagina(tester);

      expect(find.text("Non siamo riusciti a caricare gli utenti"), findsOneWidget);

      repo.erroreUtenti = null;
      await tester.tap(find.text("Riprova"));
      await tester.pumpAndSettle();

      expect(aggiungiDi("Elena Gialli"), findsOneWidget);
    });
  });

  group("salva", ()
  {
    testWidgets("manda solo i telefoni degli utenti, torna al dettaglio aggiornato con una sola SnackBar", (tester) async
    {
      repo.rispostaPartecipanti = dettaglioDiTest(stato: "confermata");
      await apriPagina(tester);

      await tester.tap(rimuoviDi("Luca Bianchi"));
      await tester.pumpAndSettle();
      await tester.tap(aggiungiDi("Elena Gialli"));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, "Salva"));
      await tester.pump();

      expect(repo.idPartecipantiRicevuto, 10);
      expect(repo.telefoniRicevuti, ["3331234567", "3335550002", "3335559999"]);

      await tester.pumpAndSettle();

      expect(find.byType(ModificaPartecipantiPage), findsNothing);
      expect(find.byType(DettaglioAdminPage), findsOneWidget);
      expect(find.widgetWithText(SnackBar, "Partecipanti aggiornati"), findsOneWidget);
      //il dettaglio sotto usa lo stesso bloc: mostra i partecipanti nuovi senza richiederli
      expect(find.text("Giocatori, 2 su 4"), findsOneWidget);
      expect(repoPartita.chiamate, 1);
    });

    testWidgets("durante il salvataggio il bottone mostra lo spinner e non si puo toccare nulla", (tester) async
    {
      repo.attesaPartecipanti = Completer<void>();
      await apriPagina(tester);

      await tester.tap(find.widgetWithText(ElevatedButton, "Salva"));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text("Salva"), findsNothing);
      expect(tester.widget<TextButton>(rimuoviDi("Luca Bianchi")).onPressed, isNull);

      repo.attesaPartecipanti!.complete();
      await tester.pumpAndSettle();
    });

    testWidgets("rifiutato: una sola SnackBar col messaggio del server, si resta sulla pagina con le modifiche", (tester) async
    {
      repo.errorePartecipanti = OperazioneRifiutata(messaggio: "Un amministratore non può partecipare");
      await apriPagina(tester);

      await tester.tap(rimuoviDi("Luca Bianchi"));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, "Salva"));
      await tester.pumpAndSettle();

      expect(find.byType(ModificaPartecipantiPage), findsOneWidget);
      expect(find.widgetWithText(SnackBar, "Un amministratore non può partecipare"), findsOneWidget);
      expect(find.text("Giocatori, 3 su 4"), findsOneWidget);
      expect(repoPartita.chiamate, 2);
    });
  });

  testWidgets("la freccia torna al dettaglio senza inviare nulla e il bloc resta vivo", (tester) async
  {
    await apriPagina(tester);

    await tester.tap(rimuoviDi("Luca Bianchi"));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
    await tester.pumpAndSettle();

    expect(repo.chiamatePartecipanti, 0);
    expect(find.text("Giocatori, 4 su 4"), findsOneWidget);

    //BlocProvider.value non deve aver chiuso il bloc del dettaglio
    await tester.tap(find.widgetWithText(ElevatedButton, "Modifica stato"));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(Dialog), matching: find.text("Giocata")));
    await tester.pumpAndSettle();

    expect(repo.statoRicevuto, "giocata");
    expect(tester.takeException(), isNull);
  });

  group("creatore", ()
  {
    const String spiegazione = "Se togli l'organizzatore, la partita passa a te";

    testWidgets("la riga di spiegazione c'e finche l'organizzatore e tra i partecipanti", (tester) async
    {
      await apriPagina(tester);
      expect(find.text(spiegazione), findsOneWidget);

      await tester.tap(rimuoviDi("Mario Rossi"));
      await tester.pumpAndSettle();

      expect(find.text(spiegazione), findsNothing);
      expect(find.text("Organizzatore"), findsNothing);
      expect(find.text("Mario Rossi"), findsNothing);
      expect(find.text("Giocatori, 3 su 4"), findsOneWidget);
      expect(repo.chiamatePartecipanti, 0);
    });

    testWidgets("se il creatore e gia un admin fuori dai posti non c'e ne etichetta ne spiegazione", (tester) async
    {
      repoPartita.risposta = dettaglioDiTest(posti: quattroPostiDiTest(), stato: "confermata", telefonoCreatore: "3330000000");
      await apriPagina(tester);

      expect(tester.takeException(), isNull);
      expect(find.text("Organizzatore"), findsNothing);
      expect(find.text(spiegazione), findsNothing);
      expect(find.widgetWithText(TextButton, "Rimuovi"), findsNWidgets(3));
    });

    testWidgets("togliendo il creatore e salvando i telefoni non lo contengono", (tester) async
    {
      repo.rispostaPartecipanti = dettaglioDiTest(stato: "confermata", telefonoCreatore: "3330000000", posti: [
        PostoPartita(idPosto: 12, tipo: "UTENTE", telefono: "3335550001", nome: "Luca", cognome: "Bianchi", livello: 3.0, confermata: true, squadra: null),
        PostoPartita(idPosto: 13, tipo: "UTENTE", telefono: "3335550002", nome: "Anna", cognome: "Verdi", livello: 2.5, confermata: true, squadra: null),
      ]);
      await apriPagina(tester);

      await tester.tap(rimuoviDi("Mario Rossi"));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, "Salva"));
      await tester.pumpAndSettle();

      expect(repo.chiamatePartecipanti, 1);
      expect(repo.idPartecipantiRicevuto, 10);
      expect(repo.telefoniRicevuti, ["3335550001", "3335550002"]);

      //il dettaglio mostra la risposta del server: la partita ora e dell'admin
      expect(find.byType(DettaglioAdminPage), findsOneWidget);
      expect(find.widgetWithText(SnackBar, "Partecipanti aggiornati"), findsOneWidget);
      expect(find.text("Mario Rossi"), findsNothing);
      expect(find.textContaining("Organizzatore"), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets("il creatore tolto per sbaglio si puo riaggiungere dalla ricerca", (tester) async
    {
      repo.utenti = [utenteAdminDiTest(telefono: "3331234567", nome: "Mario", cognome: "Rossi", livello: 2.5)];
      await apriPagina(tester);
      expect(find.widgetWithText(TextButton, "Aggiungi"), findsNothing);

      await tester.tap(rimuoviDi("Mario Rossi"));
      await tester.pumpAndSettle();
      expect(find.text("Organizzatore"), findsNothing);

      await tester.tap(aggiungiDi("Mario Rossi"));
      await tester.pumpAndSettle();
      expect(find.text("Organizzatore"), findsOneWidget);
      expect(find.text(spiegazione), findsOneWidget);

      await tester.tap(find.widgetWithText(ElevatedButton, "Salva"));
      await tester.pumpAndSettle();
      expect(repo.telefoniRicevuti, contains("3331234567"));
    });
  });

  group("nessun utente rimasto", ()
  {
    const String messaggio = "almeno un giocatore deve essere un utente";

    testWidgets("resta solo il posto del campo: errore dello use case e nessuna chiamata al server", (tester) async
    {
      await apriPagina(tester);

      await tester.tap(rimuoviDi("Mario Rossi"));
      await tester.pumpAndSettle();
      await tester.tap(rimuoviDi("Luca Bianchi"));
      await tester.pumpAndSettle();
      await tester.tap(rimuoviDi("Anna Verdi"));
      await tester.pumpAndSettle();

      expect(find.text("Giocatori, 1 su 4"), findsOneWidget);
      expect(find.text("Giocatore del campo"), findsOneWidget);
      expect(find.text("Nessun giocatore"), findsNothing);

      await tester.tap(find.widgetWithText(ElevatedButton, "Salva"));
      await tester.pumpAndSettle();

      expect(repo.chiamatePartecipanti, 0);
      expect(find.byType(ModificaPartecipantiPage), findsOneWidget);
      expect(find.widgetWithText(SnackBar, messaggio), findsOneWidget);
      //il server non e stato chiamato: il dettaglio non viene ricaricato
      expect(repoPartita.chiamate, 1);
    });

    testWidgets("card vuota: dice Nessun giocatore, l'errore non chiude la pagina e si puo correggere", (tester) async
    {
      repoPartita.risposta = dettaglioDiTest(stato: "confermata", posti: [
        PostoPartita(idPosto: 11, tipo: "UTENTE", telefono: "3331234567", nome: "Mario", cognome: "Rossi", livello: 2.5, confermata: true, squadra: null),
      ]);
      repo.rispostaPartecipanti = dettaglioDiTest(stato: "confermata");
      await apriPagina(tester);
      expect(find.text("Nessun giocatore"), findsNothing);

      await tester.tap(rimuoviDi("Mario Rossi"));
      await tester.pumpAndSettle();

      expect(find.text("Giocatori, 0 su 4"), findsOneWidget);
      expect(find.text("Nessun giocatore"), findsOneWidget);

      await tester.tap(find.widgetWithText(ElevatedButton, "Salva"));
      await tester.pumpAndSettle();

      expect(repo.chiamatePartecipanti, 0);
      expect(find.widgetWithText(SnackBar, messaggio), findsOneWidget);
      expect(find.byType(ModificaPartecipantiPage), findsOneWidget);

      //la SnackBar copre il bottone Salva: la tolgo per poter riprovare
      tester.state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger)).removeCurrentSnackBar();
      await tester.pumpAndSettle();

      await tester.tap(aggiungiDi("Elena Gialli"));
      await tester.pumpAndSettle();
      expect(find.text("Nessun giocatore"), findsNothing);

      await tester.tap(find.widgetWithText(ElevatedButton, "Salva"));
      await tester.pumpAndSettle();

      expect(repo.chiamatePartecipanti, 1);
      expect(repo.telefoniRicevuti, ["3335559999"]);
    });
  });
}
