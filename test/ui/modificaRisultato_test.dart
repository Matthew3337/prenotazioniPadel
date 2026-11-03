import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thepadel/core/di/depInjection.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/domainLayer/enetity/postoPartita.dart';
import 'package:thepadel/domainLayer/enetity/risultatoPartita.dart';
import 'package:thepadel/domainLayer/enetity/setPartita.dart';
import 'package:thepadel/ui/dettaglioAdmin.dart';
import 'package:thepadel/ui/modificaRisultato.dart';
import 'package:thepadel/ui/stileApp.dart';
import 'package:thepadel/useCase/eccezioniUseCase.dart';

import '../fake/blocDiTest.dart';
import '../fake/fakeAdminRepo.dart';
import '../fake/fakeCampoRepo.dart';
import '../fake/fakePartitaRepo.dart';
import '../fake/fakePreferenze.dart';
import '../fake/fakePrenotazioneRepo.dart';
import '../fake/fakeUtenteRepo.dart';
import '../fake/temaDiTest.dart';

RisultatoPartita risultatoDiTest(List<SetPartita> set)
{
  return RisultatoPartita(set: set, squadraUtente: null, esito: null, puntiAssegnati: 10);
}

//Luca e Anna in squadra 1 anche se nell'elenco del server il primo posto e di Mario:
//cosi si vede che il form divide le squadre come il risultato salvato
List<PostoPartita> postiConSquadreMescolate()
{
  return [
    PostoPartita(idPosto: 11, tipo: "UTENTE", telefono: "3331234567", nome: "Mario", cognome: "Rossi", livello: 2.5, confermata: true, squadra: 2),
    PostoPartita(idPosto: 12, tipo: "UTENTE", telefono: "3335550001", nome: "Luca", cognome: "Bianchi", livello: 3.0, confermata: true, squadra: 1),
    PostoPartita(idPosto: 13, tipo: "UTENTE", telefono: "3335550002", nome: "Anna", cognome: "Verdi", livello: 2.5, confermata: true, squadra: 1),
    PostoPartita(idPosto: 14, tipo: "CAMPO", telefono: null, nome: null, cognome: null, livello: null, confermata: false, squadra: 2),
  ];
}

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
    await tester.tap(find.widgetWithText(ElevatedButton, "Modifica risultato"));
    await tester.pumpAndSettle();
  }

  Future<void> salva(WidgetTester tester) async
  {
    await tester.tap(find.widgetWithText(ElevatedButton, "Salva risultato"));
    await tester.pumpAndSettle();
  }

  group("parte dai dati esistenti", ()
  {
    testWidgets("squadre, set e terzo set: salvando subito rimanda gli stessi dati", (tester) async
    {
      repoPartita.risposta = dettaglioDiTest(
        posti: postiConSquadreMescolate(),
        stato: "giocata",
        risultato: risultatoDiTest([SetPartita(squadra1: 6, squadra2: 4), SetPartita(squadra1: 3, squadra2: 6), SetPartita(squadra1: 6, squadra2: 1)]),
      );
      await apriPagina(tester);

      expect(find.text("Modifica risultato, Campo Centrale"), findsOneWidget);
      expect(find.text("Luca e Anna"), findsOneWidget);
      expect(find.text("Mario e Giocatore del campo"), findsOneWidget);
      expect(find.text("Togli il terzo set"), findsOneWidget);

      await salva(tester);

      expect(repo.idRisultatoRicevuto, 10);
      expect(repo.squadra1Ricevuta, [12, 13]);
      expect(repo.squadra2Ricevuta, [11, 14]);
      expect(repo.setRicevuti!.map((s) => "${s.squadra1}-${s.squadra2}").toList(), ["6-4", "3-6", "6-1"]);
    });

    testWidgets("con due set il terzo resta da aggiungere", (tester) async
    {
      repoPartita.risposta = dettaglioDiTest(
        posti: quattroPostiDiTest(conSquadre: true),
        stato: "giocata",
        risultato: risultatoDiTest([SetPartita(squadra1: 6, squadra2: 4), SetPartita(squadra1: 6, squadra2: 2)]),
      );
      await apriPagina(tester);

      expect(find.text("Aggiungi il terzo set"), findsOneWidget);

      await salva(tester);

      expect(repo.setRicevuti!.length, 2);
    });

    testWidgets("senza risultato il form parte vuoto e Salva e spento", (tester) async
    {
      repoPartita.risposta = dettaglioDiTest(posti: quattroPostiDiTest(), stato: "confermata");
      await apriPagina(tester);

      expect(tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, "Salva risultato")).onPressed, isNull);
      expect(find.text("Mario e Luca"), findsOneWidget);
    });
  });

  group("salvataggio", ()
  {
    Future<void> preparaGiocata() async
    {
      repoPartita.risposta = dettaglioDiTest(
        posti: quattroPostiDiTest(conSquadre: true),
        stato: "giocata",
        risultato: risultatoDiTest([SetPartita(squadra1: 6, squadra2: 4), SetPartita(squadra1: 6, squadra2: 2)]),
      );
    }

    testWidgets("riuscito: torna al dettaglio aggiornato con una sola SnackBar", (tester) async
    {
      await preparaGiocata();
      repo.rispostaRisultato = dettaglioDiTest(
        posti: quattroPostiDiTest(conSquadre: true),
        stato: "giocata",
        risultato: risultatoDiTest([SetPartita(squadra1: 6, squadra2: 0), SetPartita(squadra1: 6, squadra2: 0)]),
      );
      await apriPagina(tester);

      await salva(tester);

      expect(find.byType(ModificaRisultatoPage), findsNothing);
      expect(find.byType(DettaglioAdminPage), findsOneWidget);
      expect(find.widgetWithText(SnackBar, "Risultato aggiornato"), findsOneWidget);
      expect(find.text("0"), findsNWidgets(2));
      expect(repoPartita.chiamate, 1);
    });

    testWidgets("rifiutato: l'errore sta sopra il bottone, niente SnackBar, si resta sulla pagina", (tester) async
    {
      await preparaGiocata();
      repo.erroreRisultato = OperazioneRifiutata(messaggio: "Il risultato si può modificare solo per le partite confermate o giocate");
      await apriPagina(tester);

      await salva(tester);

      expect(find.byType(ModificaRisultatoPage), findsOneWidget);
      expect(find.widgetWithText(RiquadroMessaggio, "Il risultato si può modificare solo per le partite confermate o giocate"), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
      expect(repoPartita.chiamate, 2);
    });

    testWidgets("toccando di nuovo il form l'errore sparisce", (tester) async
    {
      await preparaGiocata();
      repo.erroreRisultato = ErroreGenericoServer();
      await apriPagina(tester);
      await salva(tester);
      expect(find.text(ErroreGenericoServer().messaggio), findsOneWidget);

      await tester.tap(find.text("Aggiungi il terzo set"));
      await tester.pumpAndSettle();

      expect(find.text(ErroreGenericoServer().messaggio), findsNothing);
    });
  });

  group("senza quattro giocatori", ()
  {
    testWidgets("spiega cosa manca e Torna indietro riporta al dettaglio", (tester) async
    {
      repoPartita.risposta = dettaglioDiTest(stato: "confermata");
      await apriPagina(tester);

      expect(find.text("Non si può inserire il risultato"), findsOneWidget);
      expect(find.text("Servono quattro giocatori: completa prima i partecipanti."), findsOneWidget);
      expect(find.text("Salva risultato"), findsNothing);

      await tester.tap(find.text("Torna indietro"));
      await tester.pumpAndSettle();

      expect(find.byType(DettaglioAdminPage), findsOneWidget);
      expect(find.byType(ModificaRisultatoPage), findsNothing);
    });
  });

  group("regola dei set", ()
  {
    testWidgets("un risultato esistente con 7-5 e 7-6 arriva al repository", (tester) async
    {
      repoPartita.risposta = dettaglioDiTest(
        posti: quattroPostiDiTest(conSquadre: true),
        stato: "giocata",
        risultato: risultatoDiTest([SetPartita(squadra1: 7, squadra2: 5), SetPartita(squadra1: 6, squadra2: 7), SetPartita(squadra1: 7, squadra2: 6)]),
      );
      await apriPagina(tester);

      await salva(tester);

      expect(repo.setRicevuti!.map((s) => "${s.squadra1}-${s.squadra2}").toList(), ["7-5", "6-7", "7-6"]);
    });

    testWidgets("un set non valido si puo salvare ma lo use case lo ferma: messaggio nel riquadro e niente chiamata", (tester) async
    {
      repoPartita.risposta = dettaglioDiTest(
        posti: quattroPostiDiTest(conSquadre: true),
        stato: "giocata",
        risultato: risultatoDiTest([SetPartita(squadra1: 5, squadra2: 4), SetPartita(squadra1: 6, squadra2: 2)]),
      );
      await apriPagina(tester);

      await salva(tester);

      expect(find.widgetWithText(RiquadroMessaggio, SetNonValido().message), findsOneWidget);
      expect(repo.chiamateRisultato, 0);
      expect(find.byType(ModificaRisultatoPage), findsOneWidget);
    });
  });
}
