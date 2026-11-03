import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thepadel/core/di/depInjection.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/domainLayer/enetity/postoPartita.dart';
import 'package:thepadel/ui/bachecaInviti.dart';
import 'package:thepadel/ui/bachecaPubbliche.dart';
import 'package:thepadel/ui/classifica.dart';
import 'package:thepadel/ui/creaPartita.dart';
import 'package:thepadel/ui/dettaglioPartita.dart';
import 'package:thepadel/ui/home.dart';
import 'package:thepadel/ui/invitaUtenti.dart';
import 'package:thepadel/ui/prenota.dart';
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

  late FakePrenotazioneRepo repoProssima;
  late FakeCampoRepo repoCampo;
  late FakeUtenteRepo repoUtente;
  late FakePartitaRepo repoPartita;

  setUp(() async
  {
    await sl.reset();
    await registraPreferenzeDiTest();
    repoProssima = FakePrenotazioneRepo();
    repoCampo = FakeCampoRepo();
    //con il campo aperto dalle 23:59 uno slot delle 00:00 e sempre di domani: non risulta mai gia iniziato
    repoCampo.campi = [campoDiTest(oraApertura: const TimeOfDay(hour: 23, minute: 59))];
    repoCampo.slots = [slotCampoDiTest(oraInizio: "00:00:00", oraFine: "01:30:00")];
    repoUtente = FakeUtenteRepo();
    repoPartita = FakePartitaRepo();
    repoPartita.partiteInviti = [];
    repoPartita.partitePubbliche = [];
    repoUtente.voci = [
      voceDiTest(posizione: 1, telefono: "1", nome: "Anna", cognome: "Verdi", punteggio: 50),
      voceDiTest(posizione: 7, telefono: "2", nome: "Mario", cognome: "Rossi", punteggio: 42, utenteCorrente: true),
    ];
    registraBlocDiTest(repoPartita: repoPartita, repoCampo: repoCampo, repoPrenotazione: repoProssima, repoUtente: repoUtente);
  });

  tearDown(() async
  {
    await sl.reset();
  });

  Future<void> apriHome(WidgetTester tester, {Size schermo = const Size(390, 1200)}) async
  {
    //di default un telefono alto: tutta la pagina sta a schermo
    tester.view.physicalSize = schermo * 3.0;
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(theme: temaDiTest(), home: const HomePage()));
    await tester.pumpAndSettle();
  }

  void chiudiPaginaInCima(WidgetTester tester)
  {
    final NavigatorState navigator = tester.state(find.byType(Navigator));
    navigator.pop();
  }

  void controllaChiamate(int attese)
  {
    expect(repoProssima.chiamateProssima, attese);
    expect(repoCampo.chiamateSlot, attese);
    expect(repoUtente.chiamate, attese);
    expect(repoPartita.chiamateInviti, attese);
    expect(repoPartita.chiamatePubbliche, attese);
  }

  group("intestazione e prossima partita", ()
  {
    testWidgets("senza partite: lo dice e propone le due strade", (tester) async
    {
      await apriHome(tester);

      controllaChiamate(1);
      expect(find.text("Nessuna partita in programma"), findsOneWidget);
      expect(find.text("Prenota un campo"), findsOneWidget);
      expect(find.text("Trova una partita"), findsOneWidget);
      expect(repoPartita.chiamate, 0);
    });

    testWidgets("Prenota un campo apre il tabellone al posto della home", (tester) async
    {
      await apriHome(tester);

      await tester.tap(find.text("Prenota un campo"));
      await tester.pumpAndSettle();

      expect(find.byType(PrenotaPage), findsOneWidget);
      expect(find.byType(HomePage), findsNothing);
    });

    testWidgets("Trova una partita apre la bacheca pubblica", (tester) async
    {
      await apriHome(tester);

      await tester.tap(find.text("Trova una partita"));
      await tester.pumpAndSettle();

      expect(find.byType(BachecaPubblichePage), findsOneWidget);
    });

    testWidgets("con una partita: titolo col giorno, nome del campo dal dettaglio e stato dei posti", (tester) async
    {
      final prossima = prenotazioneDiTest();
      repoProssima.prossima = prossima;
      await apriHome(tester);

      expect(find.text("${conMaiuscola(giornoRelativo(prossima.dataPrenotazione))} giochi alle 18:30"), findsOneWidget);
      expect(find.text("Campo Centrale · ${giornoEMese(prossima.dataPrenotazione)}, fino alle 20:00"), findsOneWidget);
      expect(repoPartita.idRicevuto, 10);
      expect(find.text("Mancano 2 giocatori"), findsOneWidget);
      expect(find.text("Non hai ancora confermato"), findsOneWidget);
    });

    testWidgets("lo stato dice chi manca e quando ci sono tutti", (tester) async
    {
      repoProssima.prossima = prenotazioneDiTest();
      repoPartita.risposta = dettaglioDiTest(azioni: azioniDiTest(), posti: [
        PostoPartita(idPosto: 1, tipo: "UTENTE", telefono: "3331234567", nome: "Mario", cognome: "Rossi", livello: 2.5, confermata: true, squadra: null),
        PostoPartita(idPosto: 2, tipo: "UTENTE", telefono: "3335550001", nome: "Luca", cognome: "Bianchi", livello: 2.5, confermata: false, squadra: null),
        PostoPartita(idPosto: 3, tipo: "UTENTE", telefono: "3335550002", nome: "Elena", cognome: "Verdi", livello: 2.5, confermata: false, squadra: null),
        PostoPartita(idPosto: 4, tipo: "CAMPO", telefono: null, nome: null, cognome: null, livello: null, confermata: false, squadra: null),
      ]);
      await apriHome(tester);

      expect(find.text("In attesa di conferma"), findsOneWidget);
      expect(find.text("Luca ed Elena non hanno ancora confermato"), findsOneWidget);
    });

    testWidgets("tutti confermati: Ci sono tutti", (tester) async
    {
      repoProssima.prossima = prenotazioneDiTest();
      repoPartita.risposta = dettaglioDiTest(azioni: azioniDiTest(), posti: [
        PostoPartita(idPosto: 1, tipo: "UTENTE", telefono: "3331234567", nome: "Mario", cognome: "Rossi", livello: 2.5, confermata: true, squadra: null),
        PostoPartita(idPosto: 2, tipo: "UTENTE", telefono: "3335550001", nome: "Luca", cognome: "Bianchi", livello: 2.5, confermata: true, squadra: null),
        PostoPartita(idPosto: 3, tipo: "CAMPO", telefono: null, nome: null, cognome: null, livello: null, confermata: false, squadra: null),
        PostoPartita(idPosto: 4, tipo: "CAMPO", telefono: null, nome: null, cognome: null, livello: null, confermata: false, squadra: null),
      ]);
      await apriHome(tester);

      expect(find.text("Ci sono tutti"), findsOneWidget);
      expect(find.text("Tutti hanno confermato"), findsOneWidget);
    });

    testWidgets("se si puo confermare il bottone Apri apre il dettaglio", (tester) async
    {
      repoProssima.prossima = prenotazioneDiTest();
      repoPartita.risposta = dettaglioDiTest(azioni: azioniDiTest(puoConfermare: true));
      await apriHome(tester);

      await tester.tap(find.widgetWithText(ElevatedButton, "Apri"));
      await tester.pumpAndSettle();

      expect(find.byType(DettaglioPartitaPage), findsOneWidget);
    });

    testWidgets("se si puo invitare il bottone Invita apre gli inviti e al ritorno la home si ricarica", (tester) async
    {
      repoProssima.prossima = prenotazioneDiTest();
      await apriHome(tester);

      await tester.tap(find.widgetWithText(ElevatedButton, "Invita"));
      await tester.pumpAndSettle();
      expect(find.byType(InvitaUtentiPage), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
      await tester.pumpAndSettle();

      expect(find.byType(InvitaUtentiPage), findsNothing);
      expect(repoProssima.chiamateProssima, 2);
    });

    testWidgets("senza azioni non c'e nessun bottone sulla card", (tester) async
    {
      repoProssima.prossima = prenotazioneDiTest();
      repoPartita.risposta = dettaglioDiTest(azioni: azioniDiTest());
      await apriHome(tester);

      expect(find.widgetWithText(ElevatedButton, "Apri"), findsNothing);
      expect(find.widgetWithText(ElevatedButton, "Invita"), findsNothing);
    });

    testWidgets("se il dettaglio non arriva resta la prenotazione, con Riprova che la rilegge", (tester) async
    {
      final prossima = prenotazioneDiTest();
      repoProssima.prossima = prossima;
      repoPartita.errore = ErroreGenericoServer();
      await apriHome(tester);

      expect(find.text("Prossima partita"), findsOneWidget);
      expect(find.text("Non siamo riusciti a caricare i giocatori."), findsOneWidget);
      expect(find.text("${giornoEMese(prossima.dataPrenotazione)}, fino alle 20:00"), findsOneWidget);

      repoPartita.errore = null;
      await tester.tap(find.text("Riprova"));
      await tester.pumpAndSettle();

      expect(repoProssima.chiamateProssima, 2);
      expect(repoCampo.chiamateSlot, 1);
      expect(find.text("Mancano 2 giocatori"), findsOneWidget);
    });

    testWidgets("errore sulla prossima partita: saluto col nome e Riprova ricarica solo quella", (tester) async
    {
      await sl<SharedPreferences>().setString("nome", "Mario");
      repoProssima.erroreProssima = ErroreGenericoServer();
      await apriHome(tester);

      expect(find.text("Ciao, Luca"), findsNothing);
      expect(find.text("Ciao, Mario"), findsOneWidget);
      expect(find.text("Prossima partita"), findsOneWidget);
      expect(find.text("Non siamo riusciti a caricarla."), findsOneWidget);

      repoProssima.erroreProssima = null;
      await tester.tap(find.text("Riprova"));
      await tester.pumpAndSettle();

      expect(find.text("Nessuna partita in programma"), findsOneWidget);
      expect(repoUtente.chiamate, 1);
    });

    testWidgets("l'avatar ha l'iniziale del nome salvato al login", (tester) async
    {
      await sl<SharedPreferences>().setString("nome", "Mario");
      await apriHome(tester);

      expect(find.text("M"), findsOneWidget);
    });

    testWidgets("senza nome salvato (login fatto con una versione vecchia) il saluto e senza nome e l'avatar e l'icona", (tester) async
    {
      repoUtente.voci = [voceDiTest(posizione: 1, nome: "Anna", cognome: "Verdi")];
      repoProssima.erroreProssima = ErroreGenericoServer();
      await apriHome(tester);

      expect(find.text("Ciao"), findsOneWidget);
      expect(find.byIcon(Icons.person_outline), findsOneWidget);
    });
  });

  group("contatori", ()
  {
    testWidgets("mostrano numero e testo al plurale", (tester) async
    {
      repoPartita.partiteInviti = [partitaInvitoDiTest(id: 1), partitaInvitoDiTest(id: 2)];
      repoPartita.partitePubbliche = [partitaPubblicaDiTest(id: 1), partitaPubblicaDiTest(id: 2), partitaPubblicaDiTest(id: 3)];
      await apriHome(tester);

      expect(find.text("2"), findsOneWidget);
      expect(find.text("inviti ricevuti"), findsOneWidget);
      expect(find.text("3"), findsOneWidget);
      expect(find.text("partite pubbliche aperte"), findsOneWidget);
    });

    testWidgets("con uno solo il testo e al singolare", (tester) async
    {
      repoPartita.partiteInviti = [partitaInvitoDiTest()];
      repoPartita.partitePubbliche = [partitaPubblicaDiTest()];
      await apriHome(tester);

      expect(find.text("invito ricevuto"), findsOneWidget);
      expect(find.text("partita pubblica aperta"), findsOneWidget);
    });

    testWidgets("il tocco sugli inviti apre la bacheca inviti", (tester) async
    {
      await apriHome(tester);

      await tester.tap(find.text("inviti ricevuti"));
      await tester.pumpAndSettle();

      expect(find.byType(BachecaInvitiPage), findsOneWidget);
    });

    testWidgets("il tocco sulle pubbliche apre la bacheca pubblica", (tester) async
    {
      await apriHome(tester);

      await tester.tap(find.text("partite pubbliche aperte"));
      await tester.pumpAndSettle();

      expect(find.byType(BachecaPubblichePage), findsOneWidget);
    });

    testWidgets("errore su un contatore: trattino e Riprova ricarica solo quello", (tester) async
    {
      repoPartita.erroreInviti = ErroreGenericoServer();
      await apriHome(tester);

      expect(find.text("–"), findsOneWidget);

      repoPartita.erroreInviti = null;
      repoPartita.partiteInviti = [partitaInvitoDiTest()];
      await tester.tap(find.text("Riprova"));
      await tester.pumpAndSettle();

      expect(repoPartita.chiamateInviti, 2);
      expect(repoPartita.chiamatePubbliche, 1);
      expect(find.text("invito ricevuto"), findsOneWidget);
    });
  });

  group("campi liberi oggi", ()
  {
    testWidgets("mostra solo gli orari liberi, col nome del campo", (tester) async
    {
      repoCampo.slots = [
        slotCampoDiTest(oraInizio: "00:00:00", oraFine: "01:30:00"),
        slotCampoDiTest(oraInizio: "01:30:00", oraFine: "03:00:00", disponibile: false),
      ];
      await apriHome(tester);

      expect(find.text("Campi liberi oggi"), findsOneWidget);
      expect(find.text("Campo Centrale"), findsOneWidget);
      expect(find.text("00:00"), findsOneWidget);
      expect(find.text("01:30"), findsNothing);
    });

    testWidgets("il tocco su un orario apre il riepilogo e, creata la partita, il suo dettaglio", (tester) async
    {
      await apriHome(tester);

      await tester.tap(find.text("00:00"));
      await tester.pumpAndSettle();
      expect(find.byType(CreaPartitaPage), findsOneWidget);

      await tester.tap(find.text("Partita pubblica"));
      await tester.pump();
      await tester.tap(find.text("Prenota il campo"));
      await tester.pumpAndSettle();

      expect(repoProssima.chiamate, 1);
      expect(find.byType(DettaglioPartitaPage), findsOneWidget);
      //la home si ricarica appena la partita e creata
      expect(repoProssima.chiamateProssima, 2);
    });

    testWidgets("senza slot lo dice, anche se ci sono solo slot occupati", (tester) async
    {
      repoCampo.slots = [slotCampoDiTest(oraInizio: "00:00:00", disponibile: false)];
      await apriHome(tester);

      expect(find.text("Nessuno slot disponibile per oggi."), findsOneWidget);
    });

    testWidgets("Altri giorni apre il tabellone", (tester) async
    {
      await apriHome(tester);

      await tester.tap(find.text("Altri giorni"));
      await tester.pumpAndSettle();

      expect(find.byType(PrenotaPage), findsOneWidget);
    });

    testWidgets("errore: messaggio e Riprova ricarica solo gli slot", (tester) async
    {
      repoCampo.erroreSlot = ErroreGenericoServer();
      await apriHome(tester);

      expect(find.text("Non siamo riusciti a caricarli."), findsOneWidget);

      repoCampo.erroreSlot = null;
      await tester.tap(find.text("Riprova"));
      await tester.pumpAndSettle();

      expect(find.text("00:00"), findsOneWidget);
      expect(repoProssima.chiamateProssima, 1);
    });
  });

  group("card classifica", ()
  {
    testWidgets("mostra posizione e punteggio reali dell'utente corrente, e quanto manca", (tester) async
    {
      await apriHome(tester);

      expect(find.text("7°"), findsOneWidget);
      expect(find.text("42 punti in classifica"), findsOneWidget);
      expect(find.text("Ti mancano 8 punti per il 1° posto"), findsOneWidget);
      expect(find.text("Classifica non disponibile"), findsNothing);
    });

    testWidgets("con un punto solo il testo e al singolare", (tester) async
    {
      repoUtente.voci = [
        voceDiTest(posizione: 1, telefono: "1", punteggio: 43),
        voceDiTest(posizione: 2, telefono: "2", punteggio: 42, utenteCorrente: true),
      ];
      await apriHome(tester);

      expect(find.text("Ti manca 1 punto per il 1° posto"), findsOneWidget);
    });

    testWidgets("chi e primo e in testa", (tester) async
    {
      repoUtente.voci = [voceDiTest(posizione: 1, punteggio: 43, utenteCorrente: true)];
      await apriHome(tester);

      expect(find.text("Sei in testa alla classifica"), findsOneWidget);
    });

    testWidgets("SectionEmpty: l'admin vede Classifica non disponibile", (tester) async
    {
      repoUtente.voci = [voceDiTest(posizione: 1, nome: "Anna", cognome: "Verdi")];
      await apriHome(tester);

      expect(find.text("Classifica non disponibile"), findsOneWidget);
      expect(find.textContaining("punti in classifica"), findsNothing);
    });

    testWidgets("SectionError: messaggio e Riprova ricarica solo la classifica, senza aprire la pagina", (tester) async
    {
      repoUtente.errore = ErroreGenericoServer();
      await apriHome(tester);

      expect(find.text("La tua posizione"), findsOneWidget);
      expect(find.text("Riprova"), findsOneWidget);

      repoUtente.errore = null;
      await tester.tap(find.text("Riprova"));
      await tester.pumpAndSettle();

      expect(find.byType(ClassificaPage), findsNothing);
      expect(repoUtente.chiamate, 2);
      expect(repoProssima.chiamateProssima, 1);
      expect(repoCampo.chiamateSlot, 1);
      expect(find.text("42 punti in classifica"), findsOneWidget);
    });

    testWidgets("il tocco sulla card apre la classifica al posto della home", (tester) async
    {
      await apriHome(tester);

      await tester.tap(find.text("42 punti in classifica"));
      await tester.pumpAndSettle();

      expect(find.byType(ClassificaPage), findsOneWidget);
      expect(find.byType(HomePage), findsNothing);
      expect(repoUtente.chiamate, 2); //quella della home e quella della pagina
    });
  });

  group("barra di navigazione", ()
  {
    final voci = <String, Type>{
      "Prenota": PrenotaPage,
      "Partite": BachecaPubblichePage,
      "Storico": StoricoPage,
      "Classifica": ClassificaPage,
    };
    for(final voce in voci.entries)
    {
      testWidgets("la voce ${voce.key} apre la pagina al posto della home", (tester) async
      {
        await apriHome(tester);

        await tester.tap(find.text(voce.key));
        await tester.pumpAndSettle();

        expect(find.byType(voce.value), findsOneWidget);
        expect(find.byType(HomePage), findsNothing);
      });
    }

    testWidgets("la voce Home e attiva: toccarla non ricarica", (tester) async
    {
      await apriHome(tester);

      await tester.tap(find.text("Home"));
      await tester.pumpAndSettle();

      controllaChiamate(1);
    });

    testWidgets("dallo storico si torna alla home e le sezioni si ricaricano", (tester) async
    {
      await apriHome(tester);

      await tester.tap(find.text("Storico"));
      await tester.pumpAndSettle();
      await tester.tap(find.text("Home"));
      await tester.pumpAndSettle();

      expect(find.byType(HomePage), findsOneWidget);
      expect(repoProssima.chiamateProssima, 2);
    });
  });

  group("ritorno dal dettaglio", ()
  {
    testWidgets("senza risultato (freccia indietro) ricarica comunque tutte le sezioni", (tester) async
    {
      repoProssima.prossima = prenotazioneDiTest();
      repoPartita.risposta = dettaglioDiTest(azioni: azioniDiTest());
      await apriHome(tester);
      controllaChiamate(1);

      await tester.tap(find.text("Non hai ancora confermato"));
      await tester.pumpAndSettle();
      expect(find.byType(DettaglioPartitaPage), findsOneWidget);
      expect(repoPartita.idRicevuto, 10);

      //il punteggio cambia mentre si e nel dettaglio, come dopo un risultato registrato
      repoUtente.voci = [voceDiTest(posizione: 2, punteggio: 45, utenteCorrente: true)];
      chiudiPaginaInCima(tester);
      await tester.pumpAndSettle();

      expect(find.byType(DettaglioPartitaPage), findsNothing);
      controllaChiamate(2);
      expect(find.text("45 punti in classifica"), findsOneWidget);
    });
  });

  group("layout", ()
  {
    testWidgets("su un telefono piccolo la pagina non va in overflow", (tester) async
    {
      repoProssima.prossima = prenotazioneDiTest();
      await apriHome(tester, schermo: const Size(320, 568));

      expect(tester.takeException(), isNull);
      expect(find.text("Mancano 2 giocatori"), findsOneWidget);
    });

    testWidgets("su telefono la bacheca pubblica non viene caricata due volte", (tester) async
    {
      await apriHome(tester);

      expect(repoPartita.chiamatePubbliche, 1);
      expect(find.text("Campi liberi oggi"), findsOneWidget);
    });

    testWidgets("su tablet mostra il tabellone di oggi e le partite pubbliche, senza overflow", (tester) async
    {
      repoProssima.prossima = prenotazioneDiTest();
      repoPartita.partitePubbliche = [partitaPubblicaDiTest(postiLiberi: 1), partitaPubblicaDiTest(id: 11)];
      repoCampo.slots = [
        slotCampoDiTest(oraInizio: "00:00:00"),
        slotCampoDiTest(oraInizio: "01:30:00", disponibile: false),
      ];
      await apriHome(tester, schermo: const Size(820, 1180));

      expect(tester.takeException(), isNull);
      expect(find.text("Campi di oggi"), findsOneWidget);
      expect(find.text("Campi liberi oggi"), findsNothing);
      expect(find.text("Libero"), findsOneWidget);
      expect(find.text("Occ."), findsOneWidget);
      expect(find.text("Partite pubbliche"), findsOneWidget);
      expect(find.text("1 posto libero"), findsOneWidget);
      expect(find.text("2 posti liberi"), findsOneWidget);
      expect(find.widgetWithText(TextButton, "Entra"), findsNWidgets(2));
    });

    testWidgets("su tablet Entra apre il dettaglio della partita", (tester) async
    {
      repoPartita.partitePubbliche = [partitaPubblicaDiTest()];
      await apriHome(tester, schermo: const Size(820, 1180));

      await tester.tap(find.text("Entra"));
      await tester.pumpAndSettle();

      expect(repoPartita.idEntraRicevuto, 10);
      expect(find.byType(DettaglioPartitaPage), findsOneWidget);
    });

    testWidgets("su tablet un ingresso rifiutato mostra la SnackBar", (tester) async
    {
      repoPartita.partitePubbliche = [partitaPubblicaDiTest()];
      repoPartita.erroreEntra = IngressoRifiutato(messaggio: "La partita è al completo");
      await apriHome(tester, schermo: const Size(820, 1180));

      await tester.tap(find.text("Entra"));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(SnackBar, "La partita è al completo"), findsOneWidget);
    });

    testWidgets("su tablet gli errori delle sezioni mostrano le loro card", (tester) async
    {
      repoCampo.erroreSlot = ErroreGenericoServer();
      repoPartita.errorePubbliche = ErroreGenericoServer();
      await apriHome(tester, schermo: const Size(820, 1180));

      expect(tester.takeException(), isNull);
      expect(find.text("Campi di oggi"), findsOneWidget);
      expect(find.text("Non siamo riusciti a caricarli."), findsOneWidget);
      expect(find.text("Non siamo riusciti a caricarle."), findsOneWidget);
    });
  });
}
