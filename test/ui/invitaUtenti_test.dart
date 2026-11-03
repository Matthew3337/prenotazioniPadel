import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thepadel/bloc/invitaUtenti/invitaUtentiBloc.dart';
import 'package:thepadel/core/di/depInjection.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/domainLayer/enetity/dettaglioPartita.dart';
import 'package:thepadel/ui/invitaUtenti.dart';
import 'package:thepadel/ui/stileApp.dart';
import 'package:thepadel/useCase/dettaglioPartitaUseCase.dart';
import 'package:thepadel/useCase/invitaUtentiUseCase.dart';

import '../fake/fakePartitaRepo.dart';
import '../fake/fakePreferenze.dart';
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
    sl.registerFactory<InvitaUtentiBloc>(() => InvitaUtentiBloc(invitabiliUseCase: InvitabiliUseCase(repo: repo), invitaUtenteUseCase: InvitaUtenteUseCase(repo: repo), dettaglioPartitaUseCase: DettaglioPartitaUseCase(repo: repo)));
  });

  tearDown(() async
  {
    await sl.reset();
  });

  void schermoTelefono(WidgetTester tester)
  {
    //schermo da telefono (390x844)
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
  }

  Future<void> apriPagina(WidgetTester tester, {DettaglioPartita? dettaglio}) async
  {
    schermoTelefono(tester);
    await tester.pumpWidget(MaterialApp(theme: temaDiTest(), home: InvitaUtentiPage(idPartita: 10, dettaglio: dettaglio)));
    await tester.pumpAndSettle();
  }

  //apre la pagina sopra una schermata finta, cosi si puo controllare cosa restituisce con il pop
  Future<List<bool?>> apriDaPaginaPrecedente(WidgetTester tester) async
  {
    schermoTelefono(tester);

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
                MaterialPageRoute<bool>(builder: (_) => const InvitaUtentiPage(idPartita: 10)),
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

  //la riga della card che contiene il nome indicato, con dentro anche il suo bottone
  Finder rigaDi(String nomeCompleto)
  {
    return find.ancestor(of: find.text(nomeCompleto), matching: find.byType(Row)).first;
  }

  testWidgets("mostra titolo, posti liberi e gli utenti con livello e link Invita", (tester) async
  {
    await apriPagina(tester);

    expect(repo.idInvitabiliRicevuto, 10);
    expect(repo.cercaRicevuti, [""]);
    //senza il dettaglio anche la testata dice Invita giocatori
    expect(find.text("Invita giocatori"), findsNWidgets(2));
    expect(find.text("Restano 2 posti liberi"), findsOneWidget);
    expect(find.text("Luca Bianchi"), findsOneWidget);
    expect(find.text("Livello 3.0"), findsOneWidget);
    expect(find.text("Anna Verdi"), findsOneWidget);
    expect(find.text("Livello 2.5"), findsOneWidget);
    expect(find.widgetWithText(TextButton, "Invita"), findsNWidgets(2));
    expect(find.text("Nessun utente trovato"), findsNothing);
  });

  testWidgets("col dettaglio la testata dice giorno, ora e campo", (tester) async
  {
    final dettaglio = dettaglioDiTest();
    await apriPagina(tester, dettaglio: dettaglio);

    expect(find.text("${conMaiuscola(giornoRelativo(dettaglio.dataPartita))} alle 18:30, Campo Centrale"), findsOneWidget);
    expect(find.text("Invita giocatori"), findsOneWidget);
  });

  testWidgets("con un solo posto libero scrive Resta 1 posto libero", (tester) async
  {
    repo.risposta = dettaglioConInvitati(2);
    await apriPagina(tester);

    expect(find.text("Resta 1 posto libero"), findsOneWidget);
  });

  testWidgets("nessun utente invitabile: mostra Nessun utente trovato", (tester) async
  {
    repo.invitabili = [];
    await apriPagina(tester);

    expect(find.text("Nessun utente trovato"), findsOneWidget);
    expect(find.widgetWithText(TextButton, "Invita"), findsNothing);
  });

  testWidgets("ricerca con debounce: la richiesta parte solo 400 ms dopo l'ultima lettera, col testo senza spazi ai bordi", (tester) async
  {
    await apriPagina(tester);

    await tester.enterText(find.byType(TextField), "an");
    await tester.pump(const Duration(milliseconds: 300));
    expect(repo.cercaRicevuti, [""]);

    //una nuova lettera fa ripartire il timer da capo
    await tester.enterText(find.byType(TextField), " ann ");
    await tester.pump(const Duration(milliseconds: 300));
    expect(repo.cercaRicevuti, [""]);

    repo.invitabili = [utenteInvitabileDiTest(telefono: "3335550002", nome: "Anna", cognome: "Verdi", livello: 2.5)];
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(repo.cercaRicevuti, ["", "ann"]);
    expect(find.text("Anna Verdi"), findsOneWidget);
    expect(find.text("Luca Bianchi"), findsNothing);
    //il testo scritto resta nel campo anche dopo il nuovo caricamento
    expect(find.text(" ann "), findsOneWidget);
  });

  testWidgets("durante un invito gli altri link sono disabilitati e lo spinner e solo su quello toccato", (tester) async
  {
    repo.attesaInvita = Completer<DettaglioPartita>();
    await apriPagina(tester);

    await tester.tap(find.descendant(of: rigaDi("Anna Verdi"), matching: find.text("Invita")));
    await tester.pump();

    expect(repo.telefonoInvitaRicevuto, "3335550002");
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.descendant(of: rigaDi("Anna Verdi"), matching: find.byType(CircularProgressIndicator)), findsOneWidget);
    expect(find.descendant(of: rigaDi("Anna Verdi"), matching: find.text("Invita")), findsNothing);
    expect(tester.widget<TextButton>(find.descendant(of: rigaDi("Luca Bianchi"), matching: find.byType(TextButton))).onPressed, isNull);

    repo.attesaInvita!.complete(dettaglioConInvitati(2));
    await tester.pumpAndSettle();
  });

  testWidgets("invito riuscito: SnackBar, l'utente resta con la scritta Invitato, i posti si aggiornano e la pagina resta aperta", (tester) async
  {
    repo.rispostaInvita = dettaglioConInvitati(2);
    final risultati = await apriDaPaginaPrecedente(tester);

    await tester.tap(find.descendant(of: rigaDi("Luca Bianchi"), matching: find.text("Invita")));
    await tester.pumpAndSettle();

    expect(repo.chiamateInvita, 1);
    expect(repo.idInvitaRicevuto, 10);
    expect(repo.telefonoInvitaRicevuto, "3335550001");
    expect(find.widgetWithText(SnackBar, "Utente invitato"), findsOneWidget);
    expect(find.descendant(of: rigaDi("Luca Bianchi"), matching: find.text("Invitato")), findsOneWidget);
    expect(find.descendant(of: rigaDi("Anna Verdi"), matching: find.text("Invita")), findsOneWidget);
    expect(find.text("Resta 1 posto libero · 1 invito inviato"), findsOneWidget);
    expect(risultati, isEmpty);
    //il link rimasto e di nuovo attivo
    expect(tester.widget<TextButton>(find.descendant(of: rigaDi("Anna Verdi"), matching: find.byType(TextButton))).onPressed, isNotNull);
  });

  testWidgets("un invitato che non corrisponde alla ricerca non si vede", (tester) async
  {
    repo.rispostaInvita = dettaglioConInvitati(2);
    await apriPagina(tester);
    await tester.tap(find.descendant(of: rigaDi("Luca Bianchi"), matching: find.text("Invita")));
    await tester.pumpAndSettle();

    repo.invitabili = [utenteInvitabileDiTest(telefono: "3335550002", nome: "Anna", cognome: "Verdi", livello: 2.5)];
    await tester.enterText(find.byType(TextField), "ann");
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text("Luca Bianchi"), findsNothing);
    expect(find.text("Anna Verdi"), findsOneWidget);
  });

  testWidgets("invito che occupa l'ultimo posto: compare La partita è al completo e Torna alla partita chiude con true", (tester) async
  {
    repo.risposta = dettaglioConInvitati(2);
    repo.rispostaInvita = dettaglioConInvitati(3);
    final risultati = await apriDaPaginaPrecedente(tester);

    await tester.tap(find.descendant(of: rigaDi("Luca Bianchi"), matching: find.text("Invita")));
    await tester.pumpAndSettle();

    expect(find.text("La partita è al completo"), findsOneWidget);
    expect(find.widgetWithText(SnackBar, "Utente invitato"), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(risultati, isEmpty);

    //la SnackBar copre il bottone: si aspetta che sparisca
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Torna alla partita"));
    await tester.pumpAndSettle();

    expect(risultati, [true]);
    expect(find.text("apri"), findsOneWidget);
  });

  testWidgets("partita gia al completo al caricamento: compare subito la pagina del completo", (tester) async
  {
    repo.risposta = dettaglioConInvitati(3);
    final risultati = await apriDaPaginaPrecedente(tester);

    expect(find.text("La partita è al completo"), findsOneWidget);
    expect(find.text("I quattro posti sono occupati: non servono altri inviti."), findsOneWidget);
    expect(risultati, isEmpty);
  });

  testWidgets("invito 409: SnackBar col messaggio, la lista resta e viene ricaricata", (tester) async
  {
    repo.erroreInvita = OperazioneRifiutata(messaggio: "L'utente partecipa già a questa partita");
    final risultati = await apriDaPaginaPrecedente(tester);

    //alla ricarica il server non manda piu l'utente che e gia in partita
    repo.invitabili = [utenteInvitabileDiTest(telefono: "3335550002", nome: "Anna", cognome: "Verdi", livello: 2.5)];
    await tester.tap(find.descendant(of: rigaDi("Luca Bianchi"), matching: find.text("Invita")));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(SnackBar, "L'utente partecipa già a questa partita"), findsOneWidget);
    expect(repo.chiamateInvitabili, 2);
    expect(find.text("Luca Bianchi"), findsNothing);
    expect(find.text("Anna Verdi"), findsOneWidget);
    expect(risultati, isEmpty);
  });

  testWidgets("invito 409 con la partita ormai piena: dopo la ricarica compare la pagina del completo", (tester) async
  {
    repo.erroreInvita = OperazioneRifiutata(messaggio: "La partita è al completo");
    await apriDaPaginaPrecedente(tester);

    repo.risposta = dettaglioConInvitati(3);
    await tester.tap(find.descendant(of: rigaDi("Luca Bianchi"), matching: find.text("Invita")));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(SnackBar, "La partita è al completo"), findsOneWidget);
    expect(find.text("La partita è al completo"), findsNWidgets(2));
  });

  testWidgets("errore di caricamento: messaggio e Riprova rifa la richiesta con lo stesso testo", (tester) async
  {
    repo.erroreInvitabili = OperazioneRifiutata(messaggio: "Solo il creatore può invitare");
    await apriPagina(tester);

    expect(find.text("Non siamo riusciti a caricare i giocatori"), findsOneWidget);
    expect(find.text("Solo il creatore può invitare"), findsOneWidget);
    expect(find.text("Riprova"), findsOneWidget);

    repo.erroreInvitabili = null;
    await tester.tap(find.text("Riprova"));
    await tester.pumpAndSettle();

    expect(repo.cercaRicevuti, ["", ""]);
    expect(find.text("Luca Bianchi"), findsOneWidget);
  });

  testWidgets("la freccia indietro chiude la pagina con true: la pagina sotto deve ricaricarsi", (tester) async
  {
    final risultati = await apriDaPaginaPrecedente(tester);

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
    await tester.pumpAndSettle();

    expect(risultati, [true]);
    expect(find.text("Invita giocatori"), findsNothing);
  });
}
