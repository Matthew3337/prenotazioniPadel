import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thepadel/core/di/depInjection.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/domainLayer/enetity/postoPartita.dart';
import 'package:thepadel/domainLayer/enetity/risultatoPartita.dart';
import 'package:thepadel/domainLayer/enetity/setPartita.dart';
import 'package:thepadel/ui/dettaglioAdmin.dart';
import 'package:thepadel/ui/modificaPartecipanti.dart';
import 'package:thepadel/ui/modificaRisultato.dart';

import '../fake/blocDiTest.dart';
import '../fake/fakeAdminRepo.dart';
import '../fake/fakeCampoRepo.dart';
import '../fake/fakePartitaRepo.dart';
import '../fake/fakePreferenze.dart';
import '../fake/fakePrenotazioneRepo.dart';
import '../fake/fakeUtenteRepo.dart';
import '../fake/temaDiTest.dart';

const String partecipanti = "Modifica partecipanti";
const String risultato = "Modifica risultato";
const String statoBottone = "Modifica stato";
const String annulla = "Annulla partita";

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
    repoPartita = FakePartitaRepo();
    repoPartita.risposta = dettaglioDiTest(posti: quattroPostiDiTest(), stato: "confermata");
    registraBlocDiTest(repoPartita: repoPartita, repoCampo: FakeCampoRepo(), repoPrenotazione: FakePrenotazioneRepo(), repoUtente: FakeUtenteRepo(), repoAdmin: repo);
  });

  tearDown(() async
  {
    await sl.reset();
  });

  Future<void> apriPagina(WidgetTester tester, {bool aspetta = true}) async
  {
    tester.view.physicalSize = const Size(1170, 3600);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(theme: temaDiTest(), home: const DettaglioAdminPage(idPartita: 10)));
    if(aspetta)
    {
      await tester.pumpAndSettle();
    }
  }

  Finder bottone(String testo)
  {
    return find.widgetWithText(ElevatedButton, testo);
  }

  Finder link(String testo)
  {
    return find.widgetWithText(TextButton, testo);
  }

  Finder nelDialog(String testo)
  {
    return find.descendant(of: find.byType(Dialog), matching: find.text(testo));
  }

  testWidgets("mostra data, orario, campo, stato, tipo e giocatori", (tester) async
  {
    await apriPagina(tester);

    expect(repoPartita.idRicevuto, 10);
    expect(find.text("Lunedì 2 novembre"), findsOneWidget);
    expect(find.text("18:30 - 20:00 · Campo Centrale"), findsOneWidget);
    expect(find.text("Confermata"), findsOneWidget);
    expect(find.text("Pubblica"), findsOneWidget);
    expect(find.text("Giocatori, 4 su 4"), findsOneWidget);
    expect(find.text("Mario Rossi"), findsOneWidget);
    expect(find.text("Organizzatore · Livello 2.5"), findsOneWidget);
    expect(find.text("Giocatore del campo"), findsOneWidget);
  });

  testWidgets("creatore admin assente dai posti: nessuna etichetta Organizzatore e nessun errore", (tester) async
  {
    repoPartita.risposta = dettaglioDiTest(telefonoCreatore: "3330000000", stato: "creata", posti: [
      PostoPartita(idPosto: 21, tipo: "UTENTE", telefono: "3335550001", nome: "Luca", cognome: "Bianchi", livello: 3.0, confermata: false, squadra: null),
      PostoPartita(idPosto: 22, tipo: "UTENTE", telefono: "3335550002", nome: "Anna", cognome: "Verdi", livello: 2.5, confermata: false, squadra: null),
    ]);
    await apriPagina(tester);

    expect(tester.takeException(), isNull);
    expect(find.text("Giocatori, 2 su 4"), findsOneWidget);
    expect(find.text("Luca Bianchi"), findsOneWidget);
    expect(find.text("Anna Verdi"), findsOneWidget);
    expect(find.text("Posto libero"), findsNWidgets(2));
    expect(find.textContaining("Organizzatore"), findsNothing);
  });

  testWidgets("i posti che mancano compaiono come liberi", (tester) async
  {
    repoPartita.risposta = dettaglioDiTest(stato: "creata");
    await apriPagina(tester);

    expect(find.text("Giocatori, 2 su 4"), findsOneWidget);
    expect(find.text("Posto libero"), findsNWidgets(2));
  });

  testWidgets("il risultato mostra i set e i nomi delle squadre", (tester) async
  {
    repoPartita.risposta = dettaglioDiTest(
      posti: quattroPostiDiTest(conSquadre: true),
      stato: "giocata",
      risultato: RisultatoPartita(set: [SetPartita(squadra1: 6, squadra2: 4), SetPartita(squadra1: 3, squadra2: 6)], squadraUtente: null, esito: null, puntiAssegnati: 10),
    );
    await apriPagina(tester);

    expect(find.text("Risultato"), findsOneWidget);
    expect(find.text("Set 1"), findsOneWidget);
    expect(find.text("Set 2"), findsOneWidget);
    expect(find.text("Mario e Luca"), findsOneWidget);
    expect(find.text("Anna e Giocatore del campo"), findsOneWidget);
  });

  testWidgets("errore: messaggio e Riprova ricarica", (tester) async
  {
    repoPartita.errore = PartitaNonTrovata(messaggio: "Partita non trovata");
    await apriPagina(tester);

    expect(find.text("Non siamo riusciti a caricare la partita"), findsOneWidget);
    expect(find.text("Partita non trovata"), findsOneWidget);

    repoPartita.errore = null;
    await tester.tap(find.text("Riprova"));
    await tester.pumpAndSettle();

    expect(find.text("Mario Rossi"), findsOneWidget);
    expect(repoPartita.chiamate, 2);
  });

  group("bottoni per stato", ()
  {
    final attesi = {
      "creata": [true, false, true, true],
      "confermata": [true, true, true, true],
      "giocata": [false, true, true, true],
      "annullata": [false, false, true, false],
    };
    attesi.forEach((stato, visibili)
    {
      testWidgets(stato, (tester) async
      {
        repoPartita.risposta = dettaglioDiTest(stato: stato);
        await apriPagina(tester);

        expect(bottone(partecipanti), visibili[0] ? findsOneWidget : findsNothing);
        expect(bottone(risultato), visibili[1] ? findsOneWidget : findsNothing);
        expect(bottone(statoBottone), visibili[2] ? findsOneWidget : findsNothing);
        expect(link(annulla), visibili[3] ? findsOneWidget : findsNothing);
      });
    });
  });

  group("dialog stato", ()
  {
    testWidgets("mostra i 4 stati con quello attuale segnato, e Chiudi non cambia nulla", (tester) async
    {
      await apriPagina(tester);

      await tester.tap(bottone(statoBottone));
      await tester.pumpAndSettle();

      expect(nelDialog("Creata"), findsOneWidget);
      expect(nelDialog("Confermata"), findsOneWidget);
      expect(nelDialog("Annullata"), findsOneWidget);
      expect(nelDialog("Giocata"), findsOneWidget);
      expect(nelDialog("Attuale"), findsOneWidget);

      await tester.tap(nelDialog("Chiudi"));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsNothing);
      expect(repo.chiamateStato, 0);
    });

    testWidgets("lo stato attuale non si puo scegliere", (tester) async
    {
      await apriPagina(tester);

      await tester.tap(bottone(statoBottone));
      await tester.pumpAndSettle();
      await tester.tap(nelDialog("Confermata"));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsOneWidget);
      expect(repo.chiamateStato, 0);
    });

    testWidgets("scegliendo uno stato lo manda al server, la pagina si aggiorna e compare la SnackBar", (tester) async
    {
      await apriPagina(tester);

      await tester.tap(bottone(statoBottone));
      await tester.pumpAndSettle();
      await tester.tap(nelDialog("Giocata"));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsNothing);
      expect(repo.idStatoRicevuto, 10);
      expect(repo.statoRicevuto, "giocata");
      expect(find.widgetWithText(SnackBar, "Stato aggiornato"), findsOneWidget);
      expect(find.text("Giocata"), findsOneWidget);
      expect(bottone(partecipanti), findsNothing);
    });

    testWidgets("rifiutato: SnackBar col messaggio del server e la partita si ricarica", (tester) async
    {
      repo.erroreStato = OperazioneRifiutata(messaggio: "Lo slot è già occupato da un'altra partita");
      await apriPagina(tester);

      await tester.tap(bottone(statoBottone));
      await tester.pumpAndSettle();
      await tester.tap(nelDialog("Creata"));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(SnackBar, "Lo slot è già occupato da un'altra partita"), findsOneWidget);
      expect(repoPartita.chiamate, 2);
      expect(find.text("Confermata"), findsOneWidget);
    });

    testWidgets("durante l'operazione i bottoni sono spenti e c'e lo spinner", (tester) async
    {
      repo.attesaStato = Completer<void>();
      await apriPagina(tester);

      await tester.tap(bottone(statoBottone));
      await tester.pumpAndSettle();
      await tester.tap(nelDialog("Giocata"));
      //lo spinner gira sempre: pumpAndSettle non finirebbe mai, basta far chiudere il dialog
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(tester.widget<ElevatedButton>(bottone(partecipanti)).onPressed, isNull);
      expect(tester.widget<ElevatedButton>(bottone(risultato)).onPressed, isNull);
      expect(tester.widget<ElevatedButton>(bottone(statoBottone)).onPressed, isNull);
      expect(tester.widget<TextButton>(link(annulla)).onPressed, isNull);

      repo.attesaStato!.complete();
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  group("dialog annulla", ()
  {
    testWidgets("spiega cosa succede, e Indietro non annulla", (tester) async
    {
      await apriPagina(tester);

      await tester.tap(link(annulla));
      await tester.pumpAndSettle();

      expect(nelDialog("Annullare la partita?"), findsOneWidget);
      expect(nelDialog("La partita di 2 novembre alle 18:30 sul Campo Centrale verrà annullata per tutti i giocatori."), findsOneWidget);

      await tester.tap(nelDialog("Indietro"));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsNothing);
      expect(repo.chiamateAnnulla, 0);
    });

    testWidgets("confermando annulla, la pagina si aggiorna e il bottone sparisce", (tester) async
    {
      repo.rispostaAnnulla = dettaglioDiTest(stato: "annullata");
      await apriPagina(tester);

      await tester.tap(link(annulla));
      await tester.pumpAndSettle();
      await tester.tap(nelDialog(annulla));
      await tester.pumpAndSettle();

      expect(repo.idAnnullaRicevuto, 10);
      expect(find.widgetWithText(SnackBar, "Partita annullata"), findsOneWidget);
      expect(find.text("Annullata"), findsOneWidget);
      expect(link(annulla), findsNothing);
    });

    testWidgets("rifiutato: SnackBar col messaggio del server", (tester) async
    {
      repo.erroreAnnulla = OperazioneRifiutata(messaggio: "La partita è già annullata");
      await apriPagina(tester);

      await tester.tap(link(annulla));
      await tester.pumpAndSettle();
      await tester.tap(nelDialog(annulla));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(SnackBar, "La partita è già annullata"), findsOneWidget);
      expect(repoPartita.chiamate, 2);
    });
  });

  group("pagine di modifica", ()
  {
    testWidgets("Modifica partecipanti apre la sua pagina", (tester) async
    {
      await apriPagina(tester);

      await tester.tap(bottone(partecipanti));
      await tester.pumpAndSettle();

      expect(find.byType(ModificaPartecipantiPage), findsOneWidget);
    });

    testWidgets("Modifica risultato apre la sua pagina", (tester) async
    {
      await apriPagina(tester);

      await tester.tap(bottone(risultato));
      await tester.pumpAndSettle();

      expect(find.byType(ModificaRisultatoPage), findsOneWidget);
    });
  });
}
