import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thepadel/bloc/registraRisultato/registraRisultatoBloc.dart';
import 'package:thepadel/core/di/depInjection.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/domainLayer/enetity/dettaglioPartita.dart';
import 'package:thepadel/domainLayer/enetity/postoPartita.dart';
import 'package:thepadel/ui/registraRisultato.dart';
import 'package:thepadel/ui/stileApp.dart';
import 'package:thepadel/useCase/registraRisultatoUseCase.dart';

import '../fake/fakePartitaRepo.dart';
import '../fake/fakePreferenze.dart';
import '../fake/temaDiTest.dart';

//i bottoni + e - sono uno per stepper: per ogni set prima la squadra 1, poi la squadra 2
const int set1Squadra1 = 0;
const int set1Squadra2 = 1;
const int set2Squadra1 = 2;
const int set2Squadra2 = 3;
const int set3Squadra1 = 4;
const int set3Squadra2 = 5;

const String piu = "+";
const String meno = "−";

void main()
{
  setUpAll(caricaFontDellApp);

  late FakePartitaRepo repo;

  //risultato del pop della pagina: serve una pagina sotto per poterlo leggere
  bool paginaChiusa = false;
  bool? valoreDelPop;

  setUp(() async
  {
    await sl.reset();
    await registraPreferenzeDiTest();
    repo = FakePartitaRepo();
    paginaChiusa = false;
    valoreDelPop = null;
    sl.registerFactory<RegistraRisultatoBloc>(() => RegistraRisultatoBloc(registraRisultatoUseCase: RegistraRisultatoUseCase(repo: repo)));
  });

  tearDown(() async
  {
    await sl.reset();
  });

  Future<void> apriPagina(WidgetTester tester, {DettaglioPartita? dettaglio}) async
  {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final partita = dettaglio ?? dettaglioDiTest(posti: quattroPostiDiTest(), stato: "confermata");

    await tester.pumpWidget(MaterialApp(
      theme: temaDiTest(),
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async
            {
              final valore = await Navigator.push<bool>(context, MaterialPageRoute<bool>(builder: (_) => RegistraRisultatoPage(dettaglio: partita)));
              paginaChiusa = true;
              valoreDelPop = valore;
            },
            child: const Text("apri"),
          ),
        ),
      ),
    ));
    await tester.tap(find.text("apri"));
    await tester.pumpAndSettle();
  }

  //i valori degli stepper nell'ordine a schermo: sono gli unici testi fatti di una sola cifra
  List<String> valoriGame(WidgetTester tester)
  {
    final testi = tester.widgetList<Text>(find.byType(Text));
    final valori = <String>[];
    for(final testo in testi)
    {
      final contenuto = testo.data;
      if(contenuto != null && RegExp(r'^\d$').hasMatch(contenuto))
      {
        valori.add(contenuto);
      }
    }
    return valori;
  }

  bool stepperAttivo(WidgetTester tester, String simbolo, int indice)
  {
    final bottone = find.ancestor(of: find.text(simbolo).at(indice), matching: find.byType(InkWell)).first;
    return tester.widget<InkWell>(bottone).onTap != null;
  }

  Future<void> premi(WidgetTester tester, String simbolo, int indice, {int volte = 1}) async
  {
    final bottone = find.text(simbolo).at(indice);
    await tester.ensureVisible(bottone);
    await tester.pumpAndSettle();
    for(int i = 0; i < volte; i++)
    {
      await tester.tap(bottone);
      await tester.pump();
    }
  }

  //6-4 nel primo set e 6-2 nel secondo
  Future<void> compilaDueSet(WidgetTester tester) async
  {
    await premi(tester, piu, set1Squadra1, volte: 6);
    await premi(tester, piu, set1Squadra2, volte: 4);
    await premi(tester, piu, set2Squadra1, volte: 6);
    await premi(tester, piu, set2Squadra2, volte: 2);
  }

  Future<void> cambiaTerzoSet(WidgetTester tester, String testo) async
  {
    await tester.ensureVisible(find.text(testo));
    await tester.pumpAndSettle();
    await tester.tap(find.text(testo));
    await tester.pumpAndSettle();
  }

  Future<void> salva(WidgetTester tester) async
  {
    await tester.tap(find.text("Salva risultato"));
    await tester.pumpAndSettle();
  }

  ElevatedButton bottoneSalva(WidgetTester tester)
  {
    return tester.widget<ElevatedButton>(find.byType(ElevatedButton));
  }

  testWidgets("la testata dice giorno e campo, la freccia chiude senza valore e senza inviare", (tester) async
  {
    final partita = dettaglioDiTest(posti: quattroPostiDiTest(), stato: "confermata");
    await apriPagina(tester, dettaglio: partita);

    expect(find.text("${conMaiuscola(dataEstesa(partita.dataPartita))}, Campo Centrale"), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
    await tester.pumpAndSettle();

    expect(paginaChiusa, isTrue);
    expect(valoreDelPop, isNull);
    expect(repo.chiamateRisultato, 0);
  });

  group("squadre", ()
  {
    testWidgets("all'inizio i primi due posti sono in squadra 1 e gli altri in squadra 2", (tester) async
    {
      await apriPagina(tester);

      expect(find.text("Chi ha giocato con chi?"), findsOneWidget);
      expect(find.text("Squadra 1"), findsOneWidget);
      expect(find.text("Mario e Luca"), findsOneWidget);
      expect(find.text("Squadra 2"), findsOneWidget);
      expect(find.text("Anna e Giocatore del campo"), findsOneWidget);
    });

    testWidgets("un tocco scambia il giocatore con quello di fronte, un secondo tocco lo riporta indietro", (tester) async
    {
      await apriPagina(tester);

      await tester.tap(find.text("LB"));
      await tester.pump();
      expect(find.text("Mario e Giocatore del campo"), findsOneWidget);
      expect(find.text("Anna e Luca"), findsOneWidget);

      await tester.tap(find.text("LB"));
      await tester.pump();
      expect(find.text("Mario e Luca"), findsOneWidget);
      expect(find.text("Anna e Giocatore del campo"), findsOneWidget);
    });

    testWidgets("le squadre inviate sono quelle a schermo, giocatore del campo compreso", (tester) async
    {
      await apriPagina(tester);
      await compilaDueSet(tester);

      //Luca e il giocatore del campo si scambiano di squadra
      await tester.ensureVisible(find.text("LB"));
      await tester.pumpAndSettle();
      await tester.tap(find.text("LB"));
      await tester.pump();

      await salva(tester);

      expect(repo.idRisultatoRicevuto, 10);
      expect(repo.squadra1Ricevuta, [11, 14]);
      expect(repo.squadra2Ricevuta, [13, 12]);
    });
  });

  group("stepper", ()
  {
    testWidgets("partono da zero e il + aumenta solo il proprio valore", (tester) async
    {
      await apriPagina(tester);
      expect(valoriGame(tester), ["0", "0", "0", "0"]);

      await premi(tester, piu, set1Squadra2, volte: 2);

      expect(valoriGame(tester), ["0", "2", "0", "0"]);
    });

    testWidgets("a 0 il - e disabilitato, a 6 il + e disabilitato", (tester) async
    {
      await apriPagina(tester);

      expect(stepperAttivo(tester, meno, set1Squadra1), isFalse);
      expect(stepperAttivo(tester, piu, set1Squadra1), isTrue);

      await premi(tester, piu, set1Squadra1, volte: 6);

      expect(valoriGame(tester)[set1Squadra1], "6");
      expect(stepperAttivo(tester, piu, set1Squadra1), isFalse);
      expect(stepperAttivo(tester, meno, set1Squadra1), isTrue);

      //un altro tocco sul + non porta a 7
      await tester.tap(find.text(piu).at(set1Squadra1));
      await tester.pump();
      expect(valoriGame(tester)[set1Squadra1], "6");

      //il - riporta sotto il limite e riattiva il +
      await premi(tester, meno, set1Squadra1);
      expect(valoriGame(tester)[set1Squadra1], "5");
      expect(stepperAttivo(tester, piu, set1Squadra1), isTrue);
    });
  });

  group("controlli sui set", ()
  {
    testWidgets("con un set ancora 0-0 non si puo salvare e lo dice, ma senza errori rossi", (tester) async
    {
      await apriPagina(tester);
      await premi(tester, piu, set1Squadra1, volte: 6);

      expect(find.text("Inserisci il punteggio dei set"), findsOneWidget);
      expect(find.textContaining("non può finire in parità"), findsNothing);
      expect(bottoneSalva(tester).onPressed, isNull);
    });

    testWidgets("un set in parita indica quale correggere e blocca il salvataggio", (tester) async
    {
      await apriPagina(tester);
      await premi(tester, piu, set2Squadra1, volte: 3);
      await premi(tester, piu, set2Squadra2, volte: 3);

      expect(find.text("Un set non può finire in parità: correggi il set 2."), findsOneWidget);
      expect(find.text("Inserisci il punteggio dei set"), findsNothing);
      expect(bottoneSalva(tester).onPressed, isNull);

      await tester.tap(find.byType(ElevatedButton), warnIfMissed: false);
      await tester.pump();
      expect(repo.chiamateRisultato, 0);
    });

    testWidgets("mostra chi vince e quanti set, dal punto di vista della squadra vincente", (tester) async
    {
      await apriPagina(tester);
      await compilaDueSet(tester);

      expect(find.text("Vince la squadra 1, 2 set a 0"), findsOneWidget);
      expect(bottoneSalva(tester).onPressed, isNotNull);
    });

    testWidgets("vince la squadra 2", (tester) async
    {
      await apriPagina(tester);
      await premi(tester, piu, set1Squadra2, volte: 6);
      await premi(tester, piu, set2Squadra2, volte: 6);
      await premi(tester, piu, set1Squadra1, volte: 1);
      await premi(tester, piu, set2Squadra1, volte: 2);

      expect(find.text("Vince la squadra 2, 2 set a 0"), findsOneWidget);
    });

    testWidgets("un set a testa senza il terzo: Parità, controlla i punteggi", (tester) async
    {
      await apriPagina(tester);
      await premi(tester, piu, set1Squadra1, volte: 6);
      await premi(tester, piu, set2Squadra2, volte: 6);

      expect(find.text("Parità: controlla i punteggi"), findsOneWidget);
    });
  });

  group("terzo set", ()
  {
    testWidgets("spento: i suoi stepper non ci sono e nel body ci sono due soli set", (tester) async
    {
      await apriPagina(tester);

      expect(find.text("Set 3"), findsNothing);
      expect(find.text(piu), findsNWidgets(4));

      await compilaDueSet(tester);
      await salva(tester);

      expect(repo.setRicevuti!.length, 2);
      expect(repo.setRicevuti![0].squadra1, 6);
      expect(repo.setRicevuti![0].squadra2, 4);
      expect(repo.setRicevuti![1].squadra1, 6);
      expect(repo.setRicevuti![1].squadra2, 2);
    });

    testWidgets("acceso: gli stepper compaiono e il terzo set viene inviato", (tester) async
    {
      await apriPagina(tester);
      await compilaDueSet(tester);
      await cambiaTerzoSet(tester, "Aggiungi il terzo set");

      expect(find.text("Set 3"), findsOneWidget);
      expect(find.text("Togli il terzo set"), findsOneWidget);
      //il terzo set e ancora 0-0: finche non si compila non si salva
      expect(bottoneSalva(tester).onPressed, isNull);

      await premi(tester, piu, set3Squadra1, volte: 6);
      await premi(tester, piu, set3Squadra2, volte: 3);
      await salva(tester);

      expect(repo.setRicevuti!.length, 3);
      expect(repo.setRicevuti![2].squadra1, 6);
      expect(repo.setRicevuti![2].squadra2, 3);
    });

    testWidgets("riempito e poi spento: non viene inviato", (tester) async
    {
      await apriPagina(tester);
      await compilaDueSet(tester);
      await cambiaTerzoSet(tester, "Aggiungi il terzo set");
      await premi(tester, piu, set3Squadra1, volte: 6);
      await cambiaTerzoSet(tester, "Togli il terzo set");

      await salva(tester);

      expect(repo.setRicevuti!.length, 2);
    });
  });

  group("salvataggio", ()
  {
    testWidgets("loading: spinner nel bottone, bottone e controlli disabilitati", (tester) async
    {
      repo.attesaRisultato = Completer<DettaglioPartita>();
      await apriPagina(tester);
      await compilaDueSet(tester);

      await tester.tap(find.text("Salva risultato"));
      await tester.pump();

      expect(bottoneSalva(tester).onPressed, isNull);
      expect(find.descendant(of: find.byType(ElevatedButton), matching: find.byType(CircularProgressIndicator)), findsOneWidget);
      expect(find.text("Salva risultato"), findsNothing);
      for(int i = 0; i < 4; i++)
      {
        expect(stepperAttivo(tester, piu, i), isFalse);
        expect(stepperAttivo(tester, meno, i), isFalse);
      }
      expect(tester.widget<TextButton>(find.widgetWithText(TextButton, "Aggiungi il terzo set")).onPressed, isNull);

      //durante l'invio le squadre non si spostano
      await tester.tap(find.text("LB"), warnIfMissed: false);
      await tester.pump();
      expect(find.text("Mario e Luca"), findsOneWidget);

      repo.attesaRisultato!.complete(dettaglioDiTest(stato: "giocata"));
      await tester.pumpAndSettle();

      expect(paginaChiusa, isTrue);
    });

    testWidgets("successo: SnackBar e pop con true", (tester) async
    {
      await apriPagina(tester);
      await compilaDueSet(tester);

      await salva(tester);

      expect(repo.chiamateRisultato, 1);
      expect(find.byType(RegistraRisultatoPage), findsNothing);
      expect(paginaChiusa, isTrue);
      expect(valoreDelPop, isTrue);
      expect(find.widgetWithText(SnackBar, "Risultato registrato"), findsOneWidget);
    });

    testWidgets("errore del server: messaggio sopra il bottone, il form resta aperto coi dati e si puo riprovare", (tester) async
    {
      const messaggio = "Il risultato è già stato registrato";
      repo.erroreRisultato = OperazioneRifiutata(messaggio: messaggio);
      await apriPagina(tester);
      await compilaDueSet(tester);

      await salva(tester);

      expect(find.widgetWithText(RiquadroMessaggio, messaggio), findsOneWidget);
      expect(find.byType(RegistraRisultatoPage), findsOneWidget);
      expect(paginaChiusa, isFalse);
      expect(valoriGame(tester), ["6", "4", "6", "2"]);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      repo.erroreRisultato = null;
      await salva(tester);

      expect(repo.chiamateRisultato, 2);
      expect(valoreDelPop, isTrue);
    });

    testWidgets("cambiare un punteggio toglie il messaggio d'errore", (tester) async
    {
      repo.erroreRisultato = OperazioneRifiutata(messaggio: "Rifiutato");
      await apriPagina(tester);
      await compilaDueSet(tester);
      await salva(tester);
      expect(find.byType(RiquadroMessaggio), findsOneWidget);

      await premi(tester, meno, set1Squadra2);

      expect(find.byType(RiquadroMessaggio), findsNothing);
    });
  });

  group("registrazione non disponibile", ()
  {
    DettaglioPartita partitaSenzaIdPosto()
    {
      final posti = quattroPostiDiTest();
      //basta un solo posto senza id per non poter comporre le squadre
      posti[2] = PostoPartita(idPosto: null, tipo: "UTENTE", telefono: "3335550002", nome: "Anna", cognome: "Verdi", livello: 2.5, confermata: true, squadra: null);
      return dettaglioDiTest(posti: posti, stato: "confermata");
    }

    testWidgets("un posto senza id: mostra il messaggio e non il form", (tester) async
    {
      await apriPagina(tester, dettaglio: partitaSenzaIdPosto());

      expect(find.text("Registrazione del risultato non disponibile al momento"), findsOneWidget);
      expect(find.text("Salva risultato"), findsNothing);
      expect(find.text(piu), findsNothing);
      expect(find.text("Mario e Luca"), findsNothing);
      expect(repo.chiamateRisultato, 0);
    });

    testWidgets("meno di quattro posti: stesso messaggio", (tester) async
    {
      await apriPagina(tester, dettaglio: dettaglioDiTest(stato: "confermata"));

      expect(find.text("Registrazione del risultato non disponibile al momento"), findsOneWidget);
    });

    testWidgets("Torna indietro chiude senza valore", (tester) async
    {
      await apriPagina(tester, dettaglio: partitaSenzaIdPosto());

      await tester.tap(find.text("Torna indietro"));
      await tester.pumpAndSettle();

      expect(paginaChiusa, isTrue);
      expect(valoreDelPop, isNull);
    });
  });
}
