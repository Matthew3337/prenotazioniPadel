import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thepadel/core/di/depInjection.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/domainLayer/enetity/dettaglioPartita.dart';
import 'package:thepadel/domainLayer/enetity/postoPartita.dart';
import 'package:thepadel/domainLayer/enetity/risultatoPartita.dart';
import 'package:thepadel/ui/dettaglioPartita.dart';
import 'package:thepadel/ui/home.dart';
import 'package:thepadel/ui/invitaUtenti.dart';
import 'package:thepadel/ui/registraRisultato.dart';
import 'package:thepadel/ui/stileApp.dart';
import 'package:thepadel/ui/storico.dart';

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

  late FakePartitaRepo repo;

  setUp(() async
  {
    await sl.reset();
    await registraPreferenzeDiTest();
    repo = FakePartitaRepo();
    registraBlocDiTest(repoPartita: repo, repoCampo: FakeCampoRepo(), repoPrenotazione: FakePrenotazioneRepo(), repoUtente: FakeUtenteRepo());
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

    await tester.pumpWidget(MaterialApp(theme: temaDiTest(), home: const DettaglioPartitaPage(idPartita: 10)));
    await tester.pumpAndSettle();
  }

  testWidgets("mostra titolo, data, stato, giocatori, posti liberi ed etichetta Organizzatore", (tester) async
  {
    final dettaglio = dettaglioDiTest();
    await apriPagina(tester);

    expect(repo.idRicevuto, 10);
    expect(find.text("Dettaglio partita"), findsOneWidget);
    expect(find.text("${conMaiuscola(giornoRelativo(dettaglio.dataPartita))} alle 18:30"), findsOneWidget);
    expect(find.text("${giornoEMese(dettaglio.dataPartita)}, 18:30 - 20:00 · Campo Centrale"), findsOneWidget);
    expect(find.text("Mancano 2 giocatori"), findsOneWidget);
    expect(find.text("Pubblica"), findsOneWidget);

    expect(find.text("Giocatori, 2 su 4"), findsOneWidget);
    expect(find.text("Mario Rossi"), findsOneWidget);
    expect(find.text("Organizzatore · Livello 2.5"), findsOneWidget);
    expect(find.text("Da confermare"), findsOneWidget);
    expect(find.text("Giocatore del campo"), findsOneWidget);
    expect(find.text("Posto libero"), findsNWidgets(2));
    //sul campo disegnato il mio posto dice Tu
    expect(find.text("Tu"), findsOneWidget);
    expect(find.text("Del campo"), findsOneWidget);
  });

  testWidgets("un partecipante che non e il creatore non ha l'etichetta Organizzatore", (tester) async
  {
    repo.risposta = dettaglioDiTest(posti: [
      PostoPartita(idPosto: null, tipo: "UTENTE", telefono: "3331234567", nome: "Mario", cognome: "Rossi", livello: 2.5, confermata: true, squadra: null),
      PostoPartita(idPosto: null, tipo: "UTENTE", telefono: "3339999999", nome: "Luca", cognome: "Bianchi", livello: 3.0, confermata: false, squadra: null),
    ]);
    await apriPagina(tester);

    expect(find.text("Mario Rossi"), findsOneWidget);
    expect(find.text("Organizzatore · Livello 2.5"), findsOneWidget);
    expect(find.text("Confermato"), findsOneWidget);
    expect(find.text("Luca Bianchi"), findsOneWidget);
    expect(find.text("Livello 3.0"), findsOneWidget);
    expect(find.text("Da confermare"), findsOneWidget);
    expect(find.text("Posto libero"), findsNWidgets(2));
  });

  testWidgets("creatore admin assente dai posti: nessuna etichetta Organizzatore e nessun errore", (tester) async
  {
    repo.risposta = dettaglioDiTest(telefonoCreatore: "3330000000", posti: [
      PostoPartita(idPosto: 21, tipo: "UTENTE", telefono: "3335550001", nome: "Luca", cognome: "Bianchi", livello: 3.0, confermata: false, squadra: null),
      PostoPartita(idPosto: 22, tipo: "UTENTE", telefono: "3335550002", nome: "Anna", cognome: "Verdi", livello: 2.5, confermata: false, squadra: null),
    ]);
    await apriPagina(tester);

    expect(tester.takeException(), isNull);
    expect(find.text("Giocatori, 2 su 4"), findsOneWidget);
    expect(find.text("Luca Bianchi"), findsOneWidget);
    expect(find.text("Livello 3.0"), findsOneWidget);
    expect(find.text("Anna Verdi"), findsOneWidget);
    expect(find.text("Livello 2.5"), findsOneWidget);
    expect(find.text("Posto libero"), findsNWidgets(2));
    expect(find.textContaining("Organizzatore"), findsNothing);
  });

  group("stato della partita", ()
  {
    testWidgets("un solo posto libero: Manca un giocatore", (tester) async
    {
      repo.risposta = dettaglioConInvitati(2);
      await apriPagina(tester);

      expect(find.text("Manca un giocatore"), findsOneWidget);
    });

    testWidgets("posti pieni ma conferme mancanti: In attesa di conferma", (tester) async
    {
      repo.risposta = dettaglioConInvitati(3);
      await apriPagina(tester);

      expect(find.text("In attesa di conferma"), findsOneWidget);
      expect(find.text("Posto libero"), findsNothing);
    });

    testWidgets("confermata: lo dice la pillola, il tipo non c'e e le conferme non interessano piu", (tester) async
    {
      repo.risposta = dettaglioDiTest(stato: "confermata", posti: quattroPostiDiTest());
      await apriPagina(tester);

      expect(find.text("Confermata, ci sono tutti"), findsOneWidget);
      expect(find.text("Pubblica"), findsNothing);
      expect(find.text("Confermato"), findsNothing);
      expect(find.textContaining("su 4"), findsNothing);
    });

    testWidgets("annullata: pillola Annullata e nessuna azione, qualunque cosa dica il server", (tester) async
    {
      repo.risposta = dettaglioDiTest(stato: "annullata", azioni: azioniDiTest(puoInvitare: true, puoEliminare: true, puoUscire: true, puoConfermare: true));
      await apriPagina(tester);

      expect(find.text("Annullata"), findsOneWidget);
      expect(find.byType(ElevatedButton), findsNothing);
      expect(find.text("Invita"), findsNothing);
      expect(find.text("Invita giocatori"), findsNothing);
      expect(find.text("Elimina partita"), findsNothing);
      expect(find.text("Esci dalla partita"), findsNothing);
    });
  });

  group("azioni", ()
  {
    testWidgets("creatore: Invita giocatori come bottone pieno, Elimina come link, gli altri nascosti", (tester) async
    {
      await apriPagina(tester);

      expect(find.widgetWithText(ElevatedButton, "Invita giocatori"), findsOneWidget);
      expect(find.widgetWithText(TextButton, "Elimina partita"), findsOneWidget);
      expect(find.text("Conferma"), findsNothing);
      expect(find.text("Registra risultato"), findsNothing);
      expect(find.text("Esci dalla partita"), findsNothing);
    });

    testWidgets("partecipante: Conferma come bottone pieno, Esci come link, Invita ed Elimina nascosti", (tester) async
    {
      repo.risposta = dettaglioDiTest(azioni: azioniDiTest(puoUscire: true, puoConfermare: true));
      await apriPagina(tester);

      expect(find.widgetWithText(ElevatedButton, "Conferma"), findsOneWidget);
      expect(find.widgetWithText(TextButton, "Esci dalla partita"), findsOneWidget);
      expect(find.text("Invita"), findsNothing);
      expect(find.text("Invita giocatori"), findsNothing);
      expect(find.text("Elimina partita"), findsNothing);
      expect(find.text("Registra risultato"), findsNothing);
    });

    testWidgets("solo la prima azione e un bottone pieno, le altre sono link", (tester) async
    {
      repo.risposta = dettaglioDiTest(azioni: azioniDiTest(puoConfermare: true, puoRegistrareRisultato: true, puoInvitare: true));
      await apriPagina(tester);

      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, "Conferma"), findsOneWidget);
      expect(find.widgetWithText(TextButton, "Registra risultato"), findsOneWidget);
      expect(find.widgetWithText(TextButton, "Invita giocatori"), findsOneWidget);
    });

    testWidgets("con puoRegistrareRisultato compare solo Registra risultato", (tester) async
    {
      repo.risposta = dettaglioDiTest(azioni: azioniDiTest(puoRegistrareRisultato: true));
      await apriPagina(tester);

      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, "Registra risultato"), findsOneWidget);
    });

    testWidgets("nessuna azione: nessun bottone e nessun Invita sui posti liberi", (tester) async
    {
      repo.risposta = dettaglioDiTest(azioni: azioniDiTest());
      await apriPagina(tester);

      expect(find.byType(ElevatedButton), findsNothing);
      expect(find.text("Invita"), findsNothing);
    });

    testWidgets("Registra risultato apre la pagina del form con la partita a schermo", (tester) async
    {
      repo.risposta = dettaglioDiTest(azioni: azioniDiTest(puoRegistrareRisultato: true), posti: quattroPostiDiTest(), stato: "confermata");
      await apriPagina(tester);

      await tester.tap(find.text("Registra risultato"));
      await tester.pumpAndSettle();

      expect(find.byType(RegistraRisultatoPage), findsOneWidget);
      expect(tester.widget<RegistraRisultatoPage>(find.byType(RegistraRisultatoPage)).dettaglio.id, 10);
      expect(find.text("Salva risultato"), findsOneWidget);
    });
  });

  group("invita", ()
  {
    testWidgets("Invita giocatori apre la pagina degli inviti e al ritorno con la freccia il dettaglio si ricarica", (tester) async
    {
      await apriPagina(tester);
      expect(repo.chiamate, 1);

      await tester.tap(find.text("Invita giocatori"));
      await tester.pumpAndSettle();

      expect(find.byType(InvitaUtentiPage), findsOneWidget);
      expect(repo.idInvitabiliRicevuto, 10);
      //anche la pagina degli inviti legge il dettaglio per i posti liberi
      expect(repo.chiamate, 2);

      //intanto e entrato un invitato
      repo.risposta = dettaglioDiTest(posti: [
        PostoPartita(idPosto: null, tipo: "UTENTE", telefono: "3331234567", nome: "Mario", cognome: "Rossi", livello: 2.5, confermata: false, squadra: null),
        PostoPartita(idPosto: null, tipo: "CAMPO", telefono: null, nome: null, cognome: null, livello: null, confermata: false, squadra: null),
        PostoPartita(idPosto: null, tipo: "UTENTE", telefono: "3335550001", nome: "Luca", cognome: "Bianchi", livello: 3.0, confermata: false, squadra: null),
      ]);
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
      await tester.pumpAndSettle();

      expect(find.byType(InvitaUtentiPage), findsNothing);
      expect(find.text("Dettaglio partita"), findsOneWidget);
      expect(repo.chiamate, 3);
      expect(repo.idRicevuto, 10);
      expect(find.text("Luca Bianchi"), findsOneWidget);
      expect(find.text("Posto libero"), findsOneWidget);
    });

    testWidgets("anche il link Invita sul posto libero apre gli inviti", (tester) async
    {
      await apriPagina(tester);

      await tester.tap(find.widgetWithText(TextButton, "Invita").first);
      await tester.pumpAndSettle();

      expect(find.byType(InvitaUtentiPage), findsOneWidget);
    });

    testWidgets("anche il posto libero sul campo disegnato apre gli inviti", (tester) async
    {
      await apriPagina(tester);

      await tester.tap(find.text("+").first);
      await tester.pumpAndSettle();

      expect(find.byType(InvitaUtentiPage), findsOneWidget);
    });

    testWidgets("l'invito che riempie la partita mostra il completo e tornando il dettaglio si ricarica", (tester) async
    {
      repo.risposta = dettaglioConInvitati(2);
      await apriPagina(tester);

      await tester.tap(find.text("Invita giocatori"));
      await tester.pumpAndSettle();
      expect(find.byType(InvitaUtentiPage), findsOneWidget);

      repo.rispostaInvita = dettaglioConInvitati(3);
      repo.risposta = dettaglioConInvitati(3);
      await tester.tap(find.descendant(of: find.byType(InvitaUtentiPage), matching: find.text("Invita")).first);
      await tester.pumpAndSettle();

      expect(repo.chiamateInvita, 1);
      expect(find.text("La partita è al completo"), findsOneWidget);
      expect(find.widgetWithText(SnackBar, "Utente invitato"), findsOneWidget);

      //la SnackBar copre il bottone: si aspetta che sparisca
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await tester.tap(find.text("Torna alla partita"));
      await tester.pumpAndSettle();

      expect(find.byType(InvitaUtentiPage), findsNothing);
      expect(find.text("Dettaglio partita"), findsOneWidget);
      expect(repo.chiamate, 3);
      expect(find.text("Posto libero"), findsNothing);
    });
  });

  group("errore di caricamento", ()
  {
    testWidgets("errore generico: messaggio e Riprova rifa la richiesta", (tester) async
    {
      repo.errore = ErroreGenericoServer();
      await apriPagina(tester);

      expect(find.text("Non siamo riusciti a caricare la partita"), findsOneWidget);
      expect(find.text(ErroreGenericoServer().messaggio), findsOneWidget);
      expect(find.text("Riprova"), findsOneWidget);
      expect(repo.chiamate, 1);

      //al secondo tentativo il server risponde
      repo.errore = null;
      await tester.tap(find.text("Riprova"));
      await tester.pumpAndSettle();

      expect(repo.chiamate, 2);
      expect(find.text("Non siamo riusciti a caricare la partita"), findsNothing);
      expect(find.text("Mario Rossi"), findsOneWidget);
    });

    testWidgets("partita non trovata: niente Riprova, si torna alla home togliendo tutto il resto", (tester) async
    {
      repo.errore = PartitaNonTrovata(messaggio: "Partita non trovata");
      await apriPagina(tester);

      expect(find.text("Partita non trovata"), findsOneWidget);
      expect(find.text("Questa partita non esiste più, oppure non puoi vederla."), findsOneWidget);
      expect(find.text("Riprova"), findsNothing);

      await tester.tap(find.text("Torna alla home"));
      await tester.pumpAndSettle();

      expect(find.byType(HomePage), findsOneWidget);
      expect(find.byType(DettaglioPartitaPage), findsNothing);
    });
  });

  //i bottoni in fondo possono finire sotto la piega: prima li porto in vista con lo scroll, poi li tocco
  Future<void> toccaAzione(WidgetTester tester, String testo) async
  {
    await tester.ensureVisible(find.text(testo));
    await tester.pumpAndSettle();
    await tester.tap(find.text(testo));
    await tester.pumpAndSettle();
  }

  //apre il dettaglio sopra una schermata finta, cosi si puo controllare cosa restituisce con il pop
  Future<List<bool?>> apriDaPaginaPrecedente(WidgetTester tester) async
  {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final risultati = <bool?>[];
    await tester.pumpWidget(MaterialApp(
      theme: temaDiTest(),
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async
            {
              final r = await Navigator.push<bool>(
                context,
                MaterialPageRoute<bool>(builder: (_) => const DettaglioPartitaPage(idPartita: 10)),
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

  group("elimina partita", ()
  {
    testWidgets("il tocco su Elimina apre il dialog con titolo, testo e i bottoni Annulla ed Elimina", (tester) async
    {
      final dettaglio = dettaglioDiTest();
      await apriPagina(tester);

      await toccaAzione(tester, "Elimina partita");

      expect(find.byType(Dialog), findsOneWidget);
      expect(find.text("Eliminare la partita?"), findsOneWidget);
      //l'unico altro posto e un giocatore del campo: non c'e nessuno da nominare
      expect(find.text("La partita verrà annullata e il Campo Centrale tornerà libero ${giornoRelativo(dettaglio.dataPartita)} alle 18:30."), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, "Annulla"), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, "Elimina"), findsOneWidget);
      //finche l'utente non conferma il server non viene chiamato
      expect(repo.chiamateElimina, 0);
    });

    testWidgets("il testo del dialog nomina gli altri giocatori, senza chi sta eliminando", (tester) async
    {
      repo.risposta = dettaglioDiTest(posti: quattroPostiDiTest());
      await apriPagina(tester);

      await toccaAzione(tester, "Elimina partita");

      expect(find.textContaining("La partita verrà annullata per Luca e Anna,"), findsOneWidget);
    });

    testWidgets("Annulla chiude il dialog senza chiamare il server e resta sul dettaglio", (tester) async
    {
      final risultati = await apriDaPaginaPrecedente(tester);

      await toccaAzione(tester, "Elimina partita");
      await tester.tap(find.text("Annulla"));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsNothing);
      expect(repo.chiamateElimina, 0);
      expect(risultati, isEmpty);
      expect(find.text("Dettaglio partita"), findsOneWidget);
      expect(find.widgetWithText(TextButton, "Elimina partita"), findsOneWidget);
    });

    testWidgets("il tocco fuori dal dialog equivale ad Annulla", (tester) async
    {
      final risultati = await apriDaPaginaPrecedente(tester);

      await toccaAzione(tester, "Elimina partita");
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsNothing);
      expect(repo.chiamateElimina, 0);
      expect(risultati, isEmpty);
    });

    testWidgets("Elimina: elimina la partita, torna indietro con true e mostra Partita eliminata", (tester) async
    {
      final risultati = await apriDaPaginaPrecedente(tester);

      await toccaAzione(tester, "Elimina partita");
      await tester.tap(find.widgetWithText(ElevatedButton, "Elimina"));
      await tester.pumpAndSettle();

      expect(repo.chiamateElimina, 1);
      expect(repo.idEliminaRicevuto, 10);
      expect(risultati, [true]);
      expect(find.text("Dettaglio partita"), findsNothing);
      expect(find.text("apri"), findsOneWidget);
      //lo ScaffoldMessenger e quello della MaterialApp, quindi la SnackBar resta sulla pagina precedente
      expect(find.widgetWithText(SnackBar, "Partita eliminata"), findsOneWidget);
    });

    testWidgets("durante l'eliminazione i bottoni sono disabilitati e il bottone pieno mostra il caricamento", (tester) async
    {
      repo.attesaElimina = Completer<void>();
      await apriDaPaginaPrecedente(tester);

      await toccaAzione(tester, "Elimina partita");
      await tester.tap(find.widgetWithText(ElevatedButton, "Elimina"));
      await tester.pump();
      //il tempo che il dialog si chiuda: con lo spinner che gira pumpAndSettle non finirebbe mai
      await tester.pump(const Duration(milliseconds: 400));

      //il dettaglio resta a schermo
      expect(find.text("Mario Rossi"), findsOneWidget);
      expect(tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed, isNull);
      expect(find.descendant(of: find.byType(ElevatedButton), matching: find.byType(CircularProgressIndicator)), findsOneWidget);
      expect(tester.widget<TextButton>(find.widgetWithText(TextButton, "Elimina partita")).onPressed, isNull);

      repo.attesaElimina!.complete();
      await tester.pumpAndSettle();
    });

    testWidgets("errore: SnackBar col messaggio del server, il dettaglio resta a schermo e viene ricaricato", (tester) async
    {
      const messaggio = "L'eliminazione è chiusa: mancano meno di 24 ore all'inizio. Solo l'amministratore può annullare la partita";
      repo.erroreElimina = OperazioneRifiutata(messaggio: messaggio);
      final risultati = await apriDaPaginaPrecedente(tester);

      await toccaAzione(tester, "Elimina partita");
      await tester.tap(find.widgetWithText(ElevatedButton, "Elimina"));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(SnackBar, messaggio), findsOneWidget);
      expect(risultati, isEmpty);
      expect(find.text("Dettaglio partita"), findsOneWidget);
      expect(find.text("Mario Rossi"), findsOneWidget);
      //il dettaglio e stato chiesto di nuovo dopo l'errore e i bottoni sono tornati attivi
      expect(repo.chiamate, 2);
      final bottone = tester.widget<TextButton>(find.widgetWithText(TextButton, "Elimina partita"));
      expect(bottone.onPressed, isNotNull);
    });
  });

  group("esci dalla partita", ()
  {
    setUp(()
    {
      repo.risposta = dettaglioDiTest(azioni: azioniDiTest(puoUscire: true));
    });

    testWidgets("il tocco su Esci apre il dialog con titolo, testo e i bottoni Annulla ed Esci", (tester) async
    {
      await apriPagina(tester);

      await toccaAzione(tester, "Esci dalla partita");

      expect(find.byType(Dialog), findsOneWidget);
      expect(find.text("Uscire dalla partita?"), findsOneWidget);
      expect(find.text("Il tuo posto tornerà libero."), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, "Annulla"), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, "Esci"), findsOneWidget);
      expect(repo.chiamateEsci, 0);
    });

    testWidgets("Annulla chiude il dialog senza chiamare il server e resta sul dettaglio", (tester) async
    {
      final risultati = await apriDaPaginaPrecedente(tester);

      await toccaAzione(tester, "Esci dalla partita");
      await tester.tap(find.text("Annulla"));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsNothing);
      expect(repo.chiamateEsci, 0);
      expect(risultati, isEmpty);
      expect(find.widgetWithText(TextButton, "Esci dalla partita"), findsOneWidget);
    });

    testWidgets("Esci: esce dalla partita, torna indietro con true e mostra Sei uscito dalla partita", (tester) async
    {
      final risultati = await apriDaPaginaPrecedente(tester);

      await toccaAzione(tester, "Esci dalla partita");
      await tester.tap(find.widgetWithText(ElevatedButton, "Esci"));
      await tester.pumpAndSettle();

      expect(repo.chiamateEsci, 1);
      expect(repo.idEsciRicevuto, 10);
      expect(repo.chiamateElimina, 0);
      expect(risultati, [true]);
      expect(find.text("Dettaglio partita"), findsNothing);
      expect(find.widgetWithText(SnackBar, "Sei uscito dalla partita"), findsOneWidget);
    });

    testWidgets("durante l'uscita il link e disabilitato e, senza bottone pieno, lo spinner sta sopra", (tester) async
    {
      repo.attesaEsci = Completer<void>();
      await apriDaPaginaPrecedente(tester);

      await toccaAzione(tester, "Esci dalla partita");
      await tester.tap(find.widgetWithText(ElevatedButton, "Esci"));
      await tester.pump();
      //il tempo che il dialog si chiuda: con lo spinner che gira pumpAndSettle non finirebbe mai
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(ElevatedButton), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(tester.widget<TextButton>(find.widgetWithText(TextButton, "Esci dalla partita")).onPressed, isNull);

      repo.attesaEsci!.complete();
      await tester.pumpAndSettle();
    });

    testWidgets("errore: SnackBar col messaggio del server e il dettaglio resta a schermo", (tester) async
    {
      repo.erroreEsci = OperazioneRifiutata(messaggio: "L'uscita è chiusa: mancano meno di 24 ore all'inizio");
      final risultati = await apriDaPaginaPrecedente(tester);

      await toccaAzione(tester, "Esci dalla partita");
      await tester.tap(find.widgetWithText(ElevatedButton, "Esci"));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(SnackBar, "L'uscita è chiusa: mancano meno di 24 ore all'inizio"), findsOneWidget);
      expect(risultati, isEmpty);
      expect(find.text("Mario Rossi"), findsOneWidget);
      expect(repo.chiamate, 2);
    });

    testWidgets("errore e ricarica fallita: compare la schermata d'errore", (tester) async
    {
      repo.erroreEsci = ErroreGenericoServer();
      await apriDaPaginaPrecedente(tester);
      //da qui in poi anche il dettaglio non si carica piu
      repo.errore = PartitaNonTrovata(messaggio: "Partita non trovata");

      await toccaAzione(tester, "Esci dalla partita");
      await tester.tap(find.widgetWithText(ElevatedButton, "Esci"));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(SnackBar, ErroreGenericoServer().messaggio), findsOneWidget);
      expect(find.text("Partita non trovata"), findsOneWidget);
      expect(find.text("Torna alla home"), findsOneWidget);
      expect(find.text("Mario Rossi"), findsNothing);
    });
  });

  group("conferma partecipazione", ()
  {
    setUp(()
    {
      repo.risposta = dettaglioDiTest(azioni: azioniDiTest(puoConfermare: true, puoRegistrareRisultato: true));
    });

    //dopo la conferma il server restituisce Mario confermato e il bottone non c'e piu
    List<PostoPartita> postiConMarioConfermato()
    {
      return [
        PostoPartita(idPosto: null, tipo: "UTENTE", telefono: "3331234567", nome: "Mario", cognome: "Rossi", livello: 2.5, confermata: true, squadra: null),
        PostoPartita(idPosto: null, tipo: "CAMPO", telefono: null, nome: null, cognome: null, livello: null, confermata: false, squadra: null),
      ];
    }

    testWidgets("un solo tocco su Conferma chiama il server senza aprire dialog", (tester) async
    {
      repo.rispostaConferma = dettaglioDiTest(azioni: azioniDiTest(), posti: postiConMarioConfermato());
      await apriPagina(tester);

      await toccaAzione(tester, "Conferma");

      expect(find.byType(Dialog), findsNothing);
      expect(repo.chiamateConferma, 1);
      expect(repo.idConfermaRicevuto, 10);
      expect(repo.chiamateElimina, 0);
      expect(repo.chiamateEsci, 0);
    });

    testWidgets("successo: SnackBar Partecipazione confermata e dettaglio aggiornato senza ricaricare", (tester) async
    {
      repo.rispostaConferma = dettaglioDiTest(azioni: azioniDiTest(), posti: postiConMarioConfermato());
      await apriPagina(tester);
      expect(find.text("Da confermare"), findsOneWidget);

      await toccaAzione(tester, "Conferma");

      expect(find.widgetWithText(SnackBar, "Partecipazione confermata"), findsOneWidget);
      expect(find.text("Partita confermata: ci sono tutti!"), findsNothing);
      //il dettaglio a schermo e quello restituito dalla conferma
      expect(find.text("Confermato"), findsOneWidget);
      expect(find.text("Da confermare"), findsNothing);
      expect(find.widgetWithText(ElevatedButton, "Conferma"), findsNothing);
      expect(find.text("Dettaglio partita"), findsOneWidget);
      expect(repo.chiamate, 1);
    });

    testWidgets("successo con partita al completo: SnackBar Partita confermata e stato Confermata", (tester) async
    {
      repo.rispostaConferma = dettaglioDiTest(azioni: azioniDiTest(), posti: postiConMarioConfermato(), stato: "confermata");
      await apriPagina(tester);

      await toccaAzione(tester, "Conferma");

      expect(find.widgetWithText(SnackBar, "Partita confermata: ci sono tutti!"), findsOneWidget);
      expect(find.text("Partecipazione confermata"), findsNothing);
      expect(find.text("Confermata, ci sono tutti"), findsOneWidget);
    });

    testWidgets("durante la conferma i bottoni sono disabilitati e Conferma mostra il caricamento", (tester) async
    {
      repo.attesaConferma = Completer<DettaglioPartita>();
      await apriPagina(tester);

      await tester.ensureVisible(find.text("Conferma"));
      await tester.pumpAndSettle();
      await tester.tap(find.text("Conferma"));
      await tester.pump();
      await tester.pump();

      //il dettaglio resta a schermo
      expect(find.text("Mario Rossi"), findsOneWidget);
      expect(tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed, isNull);
      expect(find.text("Conferma"), findsNothing);
      expect(tester.widget<TextButton>(find.widgetWithText(TextButton, "Registra risultato")).onPressed, isNull);
      expect(find.descendant(of: find.byType(ElevatedButton), matching: find.byType(CircularProgressIndicator)), findsOneWidget);

      repo.attesaConferma!.complete(dettaglioDiTest(azioni: azioniDiTest(), posti: postiConMarioConfermato()));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(SnackBar, "Partecipazione confermata"), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets("errore: SnackBar col messaggio del server, il dettaglio resta a schermo e viene ricaricato", (tester) async
    {
      const messaggio = "La conferma è possibile solo tra 24 e 12 ore prima dell'inizio";
      repo.erroreConferma = OperazioneRifiutata(messaggio: messaggio);
      await apriPagina(tester);

      await toccaAzione(tester, "Conferma");

      expect(find.widgetWithText(SnackBar, messaggio), findsOneWidget);
      expect(find.text("Partecipazione confermata"), findsNothing);
      expect(find.text("Mario Rossi"), findsOneWidget);
      expect(repo.chiamate, 2);
      //dopo la ricarica il bottone e di nuovo attivo
      final bottone = tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, "Conferma"));
      expect(bottone.onPressed, isNotNull);
    });
  });

  group("risultato", ()
  {
    //la posizione verticale di un testo, per controllare l'ordine delle squadre a schermo
    double yDi(WidgetTester tester, String testo)
    {
      return tester.getTopLeft(find.text(testo)).dy;
    }

    testWidgets("senza risultato la card Risultato non compare", (tester) async
    {
      repo.risposta = dettaglioDiTest(posti: quattroPostiDiTest());
      await apriPagina(tester);

      expect(find.text("Risultato"), findsNothing);
      expect(find.text("La tua squadra"), findsNothing);
      expect(find.text("Vai allo storico"), findsNothing);
    });

    //il dettaglio com'era prima della nuova UI: "senza set non c'e' niente da mostrare, anche se il risultato esiste"
    testWidgets("risultato senza set: niente card ne link allo storico, resta la lista dei giocatori", (tester) async
    {
      repo.risposta = dettaglioDiTest(risultato: RisultatoPartita(set: const [], squadraUtente: 1, esito: "VINTA", puntiAssegnati: 3));
      await apriPagina(tester);

      expect(find.text("Risultato"), findsNothing);
      expect(find.text("Vai allo storico"), findsNothing);
      expect(find.text("Giocatori, 2 su 4"), findsOneWidget);
      expect(find.text("Mario Rossi"), findsOneWidget);
      expect(find.text("Giocatore del campo"), findsOneWidget);
      expect(find.text("Posto libero"), findsNWidgets(2));
    });

    testWidgets("utente in squadra 1: Hai vinto con +3 punti, la sua squadra in alto e i set del server", (tester) async
    {
      repo.risposta = dettaglioDiTest(stato: "giocata", azioni: azioniDiTest(), posti: quattroPostiDiTest(conSquadre: true), risultato: risultatoDiTest(squadraUtente: 1, esito: "VINTA", puntiAssegnati: 3));
      await apriPagina(tester);

      expect(find.text("Hai vinto, +3 punti"), findsOneWidget);
      expect(find.text("Risultato"), findsOneWidget);
      expect(find.text("Set 1"), findsOneWidget);
      expect(find.text("Set 3"), findsOneWidget);
      expect(find.text("La tua squadra"), findsOneWidget);
      expect(find.text("Mario e Luca"), findsOneWidget);
      expect(find.text("Anna e Giocatore del campo"), findsOneWidget);
      expect(yDi(tester, "Mario e Luca"), lessThan(yDi(tester, "Anna e Giocatore del campo")));
      //i set della squadra 1, nell'ordine in cui arrivano dal server
      expect(tester.getCenter(find.text("6").first).dy, closeTo(tester.getCenter(find.text("3").first).dy, 1));
    });

    testWidgets("utente in squadra 2: Hai perso con -1 punti e la sua squadra va in alto", (tester) async
    {
      repo.risposta = dettaglioDiTest(stato: "giocata", azioni: azioniDiTest(), posti: quattroPostiDiTest(conSquadre: true), risultato: risultatoDiTest(squadraUtente: 2, esito: "PERSA", puntiAssegnati: -1));
      await apriPagina(tester);

      expect(find.text("Hai perso, -1 punti"), findsOneWidget);
      expect(yDi(tester, "Anna e Giocatore del campo"), lessThan(yDi(tester, "Mario e Luca")));
    });

    testWidgets("punti non ancora calcolati: si vede solo l'esito", (tester) async
    {
      repo.risposta = dettaglioDiTest(stato: "giocata", azioni: azioniDiTest(), risultato: risultatoDiTest(squadraUtente: 1, esito: "VINTA", puntiAssegnati: null));
      await apriPagina(tester);

      expect(find.text("Hai vinto"), findsOneWidget);
    });

    testWidgets("variazione zero: i punti compaiono col segno piu", (tester) async
    {
      repo.risposta = dettaglioDiTest(stato: "giocata", azioni: azioniDiTest(), risultato: risultatoDiTest(squadraUtente: 1, esito: "PERSA", puntiAssegnati: 0));
      await apriPagina(tester);

      expect(find.text("Hai perso, +0 punti"), findsOneWidget);
    });

    testWidgets("utente senza squadra: Partita giocata, nessuna squadra evidenziata", (tester) async
    {
      repo.risposta = dettaglioDiTest(stato: "giocata", azioni: azioniDiTest(), risultato: risultatoDiTest(squadraUtente: null, esito: null, puntiAssegnati: null));
      await apriPagina(tester);

      expect(find.text("Partita giocata"), findsOneWidget);
      expect(find.text("La tua squadra"), findsNothing);
      expect(find.textContaining("Hai vinto"), findsNothing);
      expect(find.textContaining("Hai perso"), findsNothing);
      //sui posti non ci sono squadre: resta solo il numero
      expect(find.text("Squadra 1"), findsOneWidget);
      expect(find.text("Squadra 2"), findsOneWidget);
    });

    testWidgets("Vai allo storico apre lo storico togliendo il dettaglio", (tester) async
    {
      repo.risposta = dettaglioDiTest(stato: "giocata", azioni: azioniDiTest(), posti: quattroPostiDiTest(conSquadre: true), risultato: risultatoDiTest());
      await apriPagina(tester);

      await tester.ensureVisible(find.text("Vai allo storico"));
      await tester.pumpAndSettle();
      await tester.tap(find.text("Vai allo storico"));
      await tester.pumpAndSettle();

      expect(find.byType(StoricoPage), findsOneWidget);
      expect(find.byType(DettaglioPartitaPage), findsNothing);
    });

    testWidgets("dopo il salvataggio il form si chiude e il dettaglio si ricarica col risultato", (tester) async
    {
      repo.risposta = dettaglioDiTest(azioni: azioniDiTest(puoRegistrareRisultato: true), posti: quattroPostiDiTest(), stato: "confermata");
      await apriPagina(tester);
      expect(repo.chiamate, 1);

      await tester.tap(find.text("Registra risultato"));
      await tester.pumpAndSettle();

      //il dettaglio ricaricato e quello che il server restituisce dopo la registrazione
      repo.risposta = dettaglioDiTest(azioni: azioniDiTest(), posti: quattroPostiDiTest(conSquadre: true), stato: "giocata", risultato: risultatoDiTest(squadraUtente: 1, esito: "VINTA", puntiAssegnati: null));

      //primo set 6-0 e secondo set 0-6: lo use case accetta solo punteggi validi
      for(int i = 0; i < 6; i++)
      {
        await tester.tap(find.text("+").at(0));
        await tester.pump();
        await tester.tap(find.text("+").at(3));
        await tester.pump();
      }
      await tester.tap(find.text("Salva risultato"));
      await tester.pumpAndSettle();

      expect(repo.chiamateRisultato, 1);
      expect(find.byType(RegistraRisultatoPage), findsNothing);
      expect(find.widgetWithText(SnackBar, "Risultato registrato"), findsOneWidget);
      expect(repo.chiamate, 2);
      expect(find.text("Risultato"), findsOneWidget);
      expect(find.text("Hai vinto"), findsOneWidget);
      expect(find.text("Registra risultato"), findsNothing);
    });

    testWidgets("uscendo dal form con la freccia il dettaglio non si ricarica", (tester) async
    {
      repo.risposta = dettaglioDiTest(azioni: azioniDiTest(puoRegistrareRisultato: true), posti: quattroPostiDiTest(), stato: "confermata");
      await apriPagina(tester);

      await tester.tap(find.text("Registra risultato"));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
      await tester.pumpAndSettle();

      expect(find.byType(RegistraRisultatoPage), findsNothing);
      expect(find.text("Dettaglio partita"), findsOneWidget);
      expect(repo.chiamate, 1);
    });
  });
}
