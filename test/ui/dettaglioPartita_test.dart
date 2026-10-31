import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thepadel/bloc/dettaglioPartita/dettaglioPartitaBloc.dart';
import 'package:thepadel/core/di/depInjection.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/domainLayer/enetity/postoPartita.dart';
import 'package:thepadel/ui/dettaglioPartita.dart';
import 'package:thepadel/useCase/dettaglioPartitaUseCase.dart';

import '../fake/fakePartitaRepo.dart';

void main()
{
  late FakePartitaRepo repo;

  setUp(() async
  {
    await sl.reset();
    repo = FakePartitaRepo();
    sl.registerFactory<DettaglioPartitaBloc>(() => DettaglioPartitaBloc(dettaglioPartitaUseCase: DettaglioPartitaUseCase(repo: repo), eliminaPartitaUseCase: EliminaPartitaUseCase(repo: repo), esciDaPartitaUseCase: EsciDaPartitaUseCase(repo: repo)));
  });

  tearDown(() async
  {
    await sl.reset();
  });

  Future<void> apriPagina(WidgetTester tester) async
  {
    //schermo da telefono (390x844): con la superficie di default 800x600 i bottoni finiscono fuori vista
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: DettaglioPartitaPage(idPartita: 10)));
    await tester.pumpAndSettle();
  }

  testWidgets("mostra info, posti occupati, posti liberi ed etichetta Organizzatore", (tester) async
  {
    await apriPagina(tester);

    expect(repo.idRicevuto, 10);
    expect(find.text("Dettaglio partita"), findsOneWidget);
    expect(find.text("Campo Centrale"), findsOneWidget);
    expect(find.text("lunedì 02/11/2026"), findsOneWidget);
    expect(find.text("18:30 - 20:00"), findsOneWidget);
    expect(find.text("Pubblica"), findsOneWidget);
    expect(find.text("Creata"), findsOneWidget);

    expect(find.text("Mario Rossi"), findsOneWidget);
    expect(find.text("Livello 2.5 · Da confermare"), findsOneWidget);
    expect(find.text("Giocatore del campo"), findsOneWidget);
    expect(find.text("Posto libero"), findsNWidgets(2));
    //solo il creatore ha l'etichetta
    expect(find.text("Organizzatore"), findsOneWidget);
  });

  testWidgets("un partecipante che non e il creatore non ha l'etichetta Organizzatore", (tester) async
  {
    repo.risposta = dettaglioDiTest(posti: [
      PostoPartita(tipo: "UTENTE", telefono: "3331234567", nome: "Mario", cognome: "Rossi", livello: 2.5, confermata: true),
      PostoPartita(tipo: "UTENTE", telefono: "3339999999", nome: "Luca", cognome: "Bianchi", livello: null, confermata: false),
    ]);
    await apriPagina(tester);

    expect(find.text("Mario Rossi"), findsOneWidget);
    expect(find.text("Livello 2.5 · Confermato"), findsOneWidget);
    expect(find.text("Luca Bianchi"), findsOneWidget);
    expect(find.text("Da confermare"), findsOneWidget);
    expect(find.text("Organizzatore"), findsOneWidget);
    expect(find.text("Posto libero"), findsNWidgets(2));
  });

  testWidgets("azioni del creatore: Invita ed Elimina visibili, gli altri bottoni nascosti", (tester) async
  {
    await apriPagina(tester);

    expect(find.widgetWithText(ElevatedButton, "Invita"), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, "Elimina partita"), findsOneWidget);
    expect(find.text("Conferma"), findsNothing);
    expect(find.text("Registra risultato"), findsNothing);
    expect(find.text("Esci dalla partita"), findsNothing);
  });

  testWidgets("azioni di un partecipante: Esci e Conferma visibili, Invita ed Elimina nascosti", (tester) async
  {
    repo.risposta = dettaglioDiTest(azioni: azioniDiTest(puoUscire: true, puoConfermare: true));
    await apriPagina(tester);

    expect(find.widgetWithText(ElevatedButton, "Esci dalla partita"), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, "Conferma"), findsOneWidget);
    expect(find.text("Invita"), findsNothing);
    expect(find.text("Elimina partita"), findsNothing);
    expect(find.text("Registra risultato"), findsNothing);
  });

  testWidgets("con puoRegistrareRisultato compare solo Registra risultato", (tester) async
  {
    repo.risposta = dettaglioDiTest(azioni: azioniDiTest(puoRegistrareRisultato: true));
    await apriPagina(tester);

    expect(find.byType(ElevatedButton), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, "Registra risultato"), findsOneWidget);
  });

  testWidgets("nessuna azione: nessun bottone", (tester) async
  {
    repo.risposta = dettaglioDiTest(azioni: azioniDiTest());
    await apriPagina(tester);

    expect(find.byType(ElevatedButton), findsNothing);
  });

  testWidgets("il tocco su un bottone mostra Funzione in arrivo", (tester) async
  {
    await apriPagina(tester);

    await tester.tap(find.text("Invita"));
    await tester.pump();

    expect(find.widgetWithText(SnackBar, "Funzione in arrivo"), findsOneWidget);
  });

  testWidgets("errore: mostra il messaggio e Riprova rifa la richiesta", (tester) async
  {
    repo.errore = PartitaNonTrovata(messaggio: "Partita non trovata");
    await apriPagina(tester);

    expect(find.text("Partita non trovata"), findsOneWidget);
    expect(find.text("Riprova"), findsOneWidget);
    expect(find.text("Giocatori"), findsNothing);
    expect(repo.chiamate, 1);

    //al secondo tentativo il server risponde
    repo.errore = null;
    await tester.tap(find.text("Riprova"));
    await tester.pumpAndSettle();

    expect(repo.chiamate, 2);
    expect(find.text("Partita non trovata"), findsNothing);
    expect(find.text("Mario Rossi"), findsOneWidget);
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
    testWidgets("il tocco su Elimina apre il dialog con titolo, testo e i bottoni Annulla e Conferma", (tester) async
    {
      await apriPagina(tester);

      await toccaAzione(tester, "Elimina partita");

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text("Eliminare la partita?"), findsOneWidget);
      expect(find.text("La partita verrà annullata per tutti i partecipanti."), findsOneWidget);
      expect(find.widgetWithText(TextButton, "Annulla"), findsOneWidget);
      expect(find.widgetWithText(TextButton, "Conferma"), findsOneWidget);
      //finche l'utente non conferma il server non viene chiamato
      expect(repo.chiamateElimina, 0);
    });

    testWidgets("Annulla chiude il dialog senza chiamare il server e resta sul dettaglio", (tester) async
    {
      final risultati = await apriDaPaginaPrecedente(tester);

      await toccaAzione(tester, "Elimina partita");
      await tester.tap(find.text("Annulla"));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(repo.chiamateElimina, 0);
      expect(risultati, isEmpty);
      expect(find.text("Dettaglio partita"), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, "Elimina partita"), findsOneWidget);
    });

    testWidgets("il tocco fuori dal dialog equivale ad Annulla", (tester) async
    {
      final risultati = await apriDaPaginaPrecedente(tester);

      await toccaAzione(tester, "Elimina partita");
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(repo.chiamateElimina, 0);
      expect(risultati, isEmpty);
    });

    testWidgets("Conferma: elimina la partita, torna indietro con true e mostra Partita eliminata", (tester) async
    {
      final risultati = await apriDaPaginaPrecedente(tester);

      await toccaAzione(tester, "Elimina partita");
      await tester.tap(find.text("Conferma"));
      await tester.pumpAndSettle();

      expect(repo.chiamateElimina, 1);
      expect(repo.idEliminaRicevuto, 10);
      expect(risultati, [true]);
      expect(find.text("Dettaglio partita"), findsNothing);
      expect(find.text("apri"), findsOneWidget);
      //lo ScaffoldMessenger e quello della MaterialApp, quindi la SnackBar resta sulla pagina precedente
      expect(find.widgetWithText(SnackBar, "Partita eliminata"), findsOneWidget);
    });

    testWidgets("durante l'eliminazione i bottoni sono disabilitati e Elimina mostra il caricamento", (tester) async
    {
      repo.attesaElimina = Completer<void>();
      await apriDaPaginaPrecedente(tester);

      await toccaAzione(tester, "Elimina partita");
      await tester.tap(find.text("Conferma"));
      await tester.pump();
      await tester.pump();

      //il dettaglio resta a schermo
      expect(find.text("Mario Rossi"), findsOneWidget);
      final bottoni = tester.widgetList<ElevatedButton>(find.byType(ElevatedButton)).toList();
      expect(bottoni.length, 2);
      for (final bottone in bottoni)
      {
        expect(bottone.onPressed, isNull);
      }
      expect(find.text("Elimina partita"), findsNothing);
      expect(find.widgetWithText(ElevatedButton, "Invita"), findsOneWidget);
      expect(find.descendant(of: find.byType(ElevatedButton), matching: find.byType(CircularProgressIndicator)), findsOneWidget);

      repo.attesaElimina!.complete();
      await tester.pumpAndSettle();
    });

    testWidgets("errore: SnackBar col messaggio del server, il dettaglio resta a schermo e viene ricaricato", (tester) async
    {
      const messaggio = "L'eliminazione è chiusa: mancano meno di 24 ore all'inizio. Solo l'amministratore può annullare la partita";
      repo.erroreElimina = OperazioneRifiutata(messaggio: messaggio);
      final risultati = await apriDaPaginaPrecedente(tester);

      await toccaAzione(tester, "Elimina partita");
      await tester.tap(find.text("Conferma"));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(SnackBar, messaggio), findsOneWidget);
      expect(risultati, isEmpty);
      expect(find.text("Dettaglio partita"), findsOneWidget);
      expect(find.text("Mario Rossi"), findsOneWidget);
      //il dettaglio e stato chiesto di nuovo dopo l'errore e i bottoni sono tornati attivi
      expect(repo.chiamate, 2);
      final bottone = tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, "Elimina partita"));
      expect(bottone.onPressed, isNotNull);
    });
  });

  group("esci dalla partita", ()
  {
    setUp(()
    {
      repo.risposta = dettaglioDiTest(azioni: azioniDiTest(puoUscire: true));
    });

    testWidgets("il tocco su Esci apre il dialog con titolo, testo e i bottoni Annulla e Conferma", (tester) async
    {
      await apriPagina(tester);

      await toccaAzione(tester, "Esci dalla partita");

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text("Uscire dalla partita?"), findsOneWidget);
      expect(find.text("Il tuo posto tornerà libero."), findsOneWidget);
      expect(find.widgetWithText(TextButton, "Annulla"), findsOneWidget);
      expect(find.widgetWithText(TextButton, "Conferma"), findsOneWidget);
      expect(repo.chiamateEsci, 0);
    });

    testWidgets("Annulla chiude il dialog senza chiamare il server e resta sul dettaglio", (tester) async
    {
      final risultati = await apriDaPaginaPrecedente(tester);

      await toccaAzione(tester, "Esci dalla partita");
      await tester.tap(find.text("Annulla"));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(repo.chiamateEsci, 0);
      expect(risultati, isEmpty);
      expect(find.widgetWithText(ElevatedButton, "Esci dalla partita"), findsOneWidget);
    });

    testWidgets("Conferma: esce dalla partita, torna indietro con true e mostra Sei uscito dalla partita", (tester) async
    {
      final risultati = await apriDaPaginaPrecedente(tester);

      await toccaAzione(tester, "Esci dalla partita");
      await tester.tap(find.text("Conferma"));
      await tester.pumpAndSettle();

      expect(repo.chiamateEsci, 1);
      expect(repo.idEsciRicevuto, 10);
      expect(repo.chiamateElimina, 0);
      expect(risultati, [true]);
      expect(find.text("Dettaglio partita"), findsNothing);
      expect(find.widgetWithText(SnackBar, "Sei uscito dalla partita"), findsOneWidget);
    });

    testWidgets("durante l'uscita il bottone e disabilitato e mostra il caricamento", (tester) async
    {
      repo.attesaEsci = Completer<void>();
      await apriDaPaginaPrecedente(tester);

      await toccaAzione(tester, "Esci dalla partita");
      await tester.tap(find.text("Conferma"));
      await tester.pump();
      await tester.pump();

      final bottone = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(bottone.onPressed, isNull);
      expect(find.text("Esci dalla partita"), findsNothing);
      expect(find.descendant(of: find.byType(ElevatedButton), matching: find.byType(CircularProgressIndicator)), findsOneWidget);

      repo.attesaEsci!.complete();
      await tester.pumpAndSettle();
    });

    testWidgets("errore: SnackBar col messaggio del server e il dettaglio resta a schermo", (tester) async
    {
      repo.erroreEsci = OperazioneRifiutata(messaggio: "L'uscita è chiusa: mancano meno di 24 ore all'inizio");
      final risultati = await apriDaPaginaPrecedente(tester);

      await toccaAzione(tester, "Esci dalla partita");
      await tester.tap(find.text("Conferma"));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(SnackBar, "L'uscita è chiusa: mancano meno di 24 ore all'inizio"), findsOneWidget);
      expect(risultati, isEmpty);
      expect(find.text("Mario Rossi"), findsOneWidget);
      expect(repo.chiamate, 2);
    });

    testWidgets("errore e ricarica fallita: compare la schermata d'errore con Riprova", (tester) async
    {
      repo.erroreEsci = ErroreGenericoServer();
      await apriDaPaginaPrecedente(tester);
      //da qui in poi anche il dettaglio non si carica piu
      repo.errore = PartitaNonTrovata(messaggio: "Partita non trovata");

      await toccaAzione(tester, "Esci dalla partita");
      await tester.tap(find.text("Conferma"));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(SnackBar, ErroreGenericoServer().messaggio), findsOneWidget);
      expect(find.text("Partita non trovata"), findsOneWidget);
      expect(find.text("Riprova"), findsOneWidget);
      expect(find.text("Mario Rossi"), findsNothing);
    });
  });
}
