import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thepadel/bloc/registraRisultato/registraRisultatoBloc.dart';
import 'package:thepadel/core/di/depInjection.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/domainLayer/enetity/dettaglioPartita.dart';
import 'package:thepadel/domainLayer/enetity/postoPartita.dart';
import 'package:thepadel/ui/registraRisultato.dart';
import 'package:thepadel/useCase/eccezioniUseCase.dart';
import 'package:thepadel/useCase/registraRisultatoUseCase.dart';

import '../fake/fakePartitaRepo.dart';

//i bottoni + e - sono 6 per tipo: per ogni set prima la squadra 1, poi la squadra 2
const int set1Squadra1 = 0;
const int set1Squadra2 = 1;
const int set2Squadra1 = 2;
const int set2Squadra2 = 3;
const int set3Squadra1 = 4;
const int set3Squadra2 = 5;

void main()
{
  late FakePartitaRepo repo;

  //risultato del pop della pagina: serve una pagina sotto per poterlo leggere
  bool paginaChiusa = false;
  bool? valoreDelPop;

  setUp(() async
  {
    await sl.reset();
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

  //la colonna in cui sta un giocatore: Squadra 1 occupa la meta sinistra dello schermo (largo 390)
  int colonnaDi(WidgetTester tester, String nome)
  {
    return tester.getCenter(find.text(nome)).dx < 195 ? 1 : 2;
  }

  //i valori dei 6 stepper nell'ordine a schermo: sono gli unici testi fatti di una sola cifra
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

  IconButton bottoneStepper(WidgetTester tester, IconData icona, int indice)
  {
    return tester.widget<IconButton>(find.widgetWithIcon(IconButton, icona).at(indice));
  }

  Future<void> premi(WidgetTester tester, IconData icona, int indice, {int volte = 1}) async
  {
    final bottone = find.widgetWithIcon(IconButton, icona).at(indice);
    await tester.ensureVisible(bottone);
    await tester.pumpAndSettle();
    for(int i = 0; i < volte; i++)
    {
      await tester.tap(bottone);
      await tester.pump();
    }
  }

  //6-4 nel primo set e 2-6 nel secondo
  Future<void> compilaDueSet(WidgetTester tester) async
  {
    await premi(tester, Icons.add, set1Squadra1, volte: 6);
    await premi(tester, Icons.add, set1Squadra2, volte: 4);
    await premi(tester, Icons.add, set2Squadra1, volte: 2);
    await premi(tester, Icons.add, set2Squadra2, volte: 6);
  }

  Future<void> attivaTerzoSet(WidgetTester tester) async
  {
    await tester.ensureVisible(find.byType(Switch));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    await tester.pump();
  }

  group("squadre", ()
  {
    testWidgets("all'inizio i primi due posti sono in squadra 1 e gli altri in squadra 2, col nome giusto", (tester) async
    {
      await apriPagina(tester);

      expect(find.text("Salva risultato"), findsOneWidget);
      expect(colonnaDi(tester, "Mario Rossi"), 1);
      expect(colonnaDi(tester, "Luca Bianchi"), 1);
      expect(colonnaDi(tester, "Anna Verdi"), 2);
      expect(colonnaDi(tester, "Giocatore del campo"), 2);
    });

    testWidgets("un tocco sposta il giocatore nell'altra squadra, un secondo tocco lo riporta indietro", (tester) async
    {
      await apriPagina(tester);

      await tester.tap(find.text("Mario Rossi"));
      await tester.pump();
      expect(colonnaDi(tester, "Mario Rossi"), 2);

      await tester.tap(find.text("Mario Rossi"));
      await tester.pump();
      expect(colonnaDi(tester, "Mario Rossi"), 1);
    });

    testWidgets("le squadre inviate sono quelle a schermo, giocatore del campo compreso", (tester) async
    {
      await apriPagina(tester);
      await compilaDueSet(tester);
      await attivaTerzoSet(tester);
      await premi(tester, Icons.add, set3Squadra1);

      //Luca e il giocatore del campo si scambiano di squadra
      await tester.ensureVisible(find.text("Luca Bianchi"));
      await tester.pumpAndSettle();
      await tester.tap(find.text("Luca Bianchi"));
      await tester.pump();
      await tester.tap(find.text("Giocatore del campo"));
      await tester.pump();

      await tester.tap(find.text("Salva risultato"));
      await tester.pumpAndSettle();

      expect(repo.idRisultatoRicevuto, 10);
      expect(repo.squadra1Ricevuta, [11, 14]);
      expect(repo.squadra2Ricevuta, [12, 13]);
    });

    testWidgets("3 giocatori da una parte: errore SnackBar di validazione e nessuna chiamata", (tester) async
    {
      await apriPagina(tester);
      await compilaDueSet(tester);

      await tester.ensureVisible(find.text("Mario Rossi"));
      await tester.pumpAndSettle();
      await tester.tap(find.text("Mario Rossi"));
      await tester.pump();
      await tester.tap(find.text("Salva risultato"));
      await tester.pumpAndSettle();

      expect(repo.chiamateRisultato, 0);
      expect(find.widgetWithText(SnackBar, SquadraIncompleta().message), findsOneWidget);
      expect(find.byType(RegistraRisultatoPage), findsOneWidget);
    });
  });

  group("stepper", ()
  {
    testWidgets("partono da zero e il + aumenta solo il proprio valore", (tester) async
    {
      await apriPagina(tester);
      expect(valoriGame(tester), ["0", "0", "0", "0", "0", "0"]);

      await premi(tester, Icons.add, set1Squadra2, volte: 2);

      expect(valoriGame(tester), ["0", "2", "0", "0", "0", "0"]);
    });

    testWidgets("a 0 il - e disabilitato, a 6 il + e disabilitato", (tester) async
    {
      await apriPagina(tester);

      expect(bottoneStepper(tester, Icons.remove, set1Squadra1).onPressed, isNull);
      expect(bottoneStepper(tester, Icons.add, set1Squadra1).onPressed, isNotNull);

      await premi(tester, Icons.add, set1Squadra1, volte: 6);

      expect(valoriGame(tester)[set1Squadra1], "6");
      expect(bottoneStepper(tester, Icons.add, set1Squadra1).onPressed, isNull);
      expect(bottoneStepper(tester, Icons.remove, set1Squadra1).onPressed, isNotNull);

      //un altro tocco sul + non porta a 7
      await tester.tap(find.widgetWithIcon(IconButton, Icons.add).at(set1Squadra1));
      await tester.pump();
      expect(valoriGame(tester)[set1Squadra1], "6");

      //il - riporta sotto il limite e riattiva il +
      await premi(tester, Icons.remove, set1Squadra1);
      expect(valoriGame(tester)[set1Squadra1], "5");
      expect(bottoneStepper(tester, Icons.add, set1Squadra1).onPressed, isNotNull);
    });
  });

  group("terzo set", ()
  {
    testWidgets("spento: i suoi stepper sono disabilitati e nel body ci sono due soli set", (tester) async
    {
      await apriPagina(tester);

      expect(bottoneStepper(tester, Icons.add, set3Squadra1).onPressed, isNull);
      expect(bottoneStepper(tester, Icons.add, set3Squadra2).onPressed, isNull);

      await compilaDueSet(tester);
      await tester.tap(find.text("Salva risultato"));
      await tester.pumpAndSettle();

      expect(repo.setRicevuti!.length, 2);
      expect(repo.setRicevuti![0].squadra1, 6);
      expect(repo.setRicevuti![0].squadra2, 4);
      expect(repo.setRicevuti![1].squadra1, 2);
      expect(repo.setRicevuti![1].squadra2, 6);
    });

    testWidgets("acceso: gli stepper si attivano e il terzo set viene inviato", (tester) async
    {
      await apriPagina(tester);
      await compilaDueSet(tester);
      await attivaTerzoSet(tester);

      expect(bottoneStepper(tester, Icons.add, set3Squadra1).onPressed, isNotNull);

      await premi(tester, Icons.add, set3Squadra1, volte: 6);
      await premi(tester, Icons.add, set3Squadra2, volte: 3);
      await tester.tap(find.text("Salva risultato"));
      await tester.pumpAndSettle();

      expect(repo.setRicevuti!.length, 3);
      expect(repo.setRicevuti![2].squadra1, 6);
      expect(repo.setRicevuti![2].squadra2, 3);
    });

    testWidgets("riempito e poi spento: non viene inviato", (tester) async
    {
      await apriPagina(tester);
      await compilaDueSet(tester);
      await attivaTerzoSet(tester);
      await premi(tester, Icons.add, set3Squadra1, volte: 6);
      await attivaTerzoSet(tester);

      await tester.tap(find.text("Salva risultato"));
      await tester.pumpAndSettle();

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

      final salva = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(salva.onPressed, isNull);
      expect(find.descendant(of: find.byType(ElevatedButton), matching: find.byType(CircularProgressIndicator)), findsOneWidget);
      expect(find.text("Salva risultato"), findsNothing);
      expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNull);
      for(int i = 0; i < 6; i++)
      {
        expect(bottoneStepper(tester, Icons.add, i).onPressed, isNull);
        expect(bottoneStepper(tester, Icons.remove, i).onPressed, isNull);
      }

      //durante l'invio le squadre non si spostano
      await tester.tap(find.text("Mario Rossi"), warnIfMissed: false);
      await tester.pump();
      expect(colonnaDi(tester, "Mario Rossi"), 1);

      repo.attesaRisultato!.complete(dettaglioDiTest(stato: "giocata"));
      await tester.pumpAndSettle();

      expect(paginaChiusa, isTrue);
    });

    testWidgets("successo: SnackBar e pop con true", (tester) async
    {
      await apriPagina(tester);
      await compilaDueSet(tester);

      await tester.tap(find.text("Salva risultato"));
      await tester.pumpAndSettle();

      expect(repo.chiamateRisultato, 1);
      expect(find.byType(RegistraRisultatoPage), findsNothing);
      expect(paginaChiusa, isTrue);
      expect(valoreDelPop, isTrue);
      expect(find.widgetWithText(SnackBar, "Risultato registrato"), findsOneWidget);
    });

    testWidgets("errore del server: SnackBar col messaggio, il form resta aperto coi dati e si puo riprovare", (tester) async
    {
      const messaggio = "Il risultato è già stato registrato";
      repo.erroreRisultato = OperazioneRifiutata(messaggio: messaggio);
      await apriPagina(tester);
      await compilaDueSet(tester);

      await tester.tap(find.text("Salva risultato"));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(SnackBar, messaggio), findsOneWidget);
      expect(find.byType(RegistraRisultatoPage), findsOneWidget);
      expect(paginaChiusa, isFalse);
      expect(valoriGame(tester), ["6", "4", "2", "6", "0", "0"]);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      //la SnackBar copre il bottone: si aspetta che sparisca, poi il secondo tentativo va a buon fine
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      repo.erroreRisultato = null;
      await tester.tap(find.text("Salva risultato"));
      await tester.pumpAndSettle();

      expect(repo.chiamateRisultato, 2);
      expect(valoreDelPop, isTrue);
    });

    testWidgets("set a zero: SnackBar di validazione, nessuna chiamata e form aperto", (tester) async
    {
      await apriPagina(tester);

      await tester.tap(find.text("Salva risultato"));
      await tester.pumpAndSettle();

      expect(repo.chiamateRisultato, 0);
      expect(find.widgetWithText(SnackBar, SetNonValido().message), findsOneWidget);
      expect(find.byType(RegistraRisultatoPage), findsOneWidget);
    });

    testWidgets("la freccia indietro chiude senza valore e senza inviare", (tester) async
    {
      await apriPagina(tester);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(paginaChiusa, isTrue);
      expect(valoreDelPop, isNull);
      expect(repo.chiamateRisultato, 0);
    });
  });

  group("idPosto mancante", ()
  {
    DettaglioPartita partitaSenzaIdPosto()
    {
      final posti = quattroPostiDiTest();
      //basta un solo posto senza id per non poter comporre le squadre
      posti[2] = PostoPartita(idPosto: null, tipo: "UTENTE", telefono: "3335550002", nome: "Anna", cognome: "Verdi", livello: 2.5, confermata: true, squadra: null);
      return dettaglioDiTest(posti: posti, stato: "confermata");
    }

    testWidgets("mostra il messaggio e non il form", (tester) async
    {
      await apriPagina(tester, dettaglio: partitaSenzaIdPosto());

      expect(find.text("Registrazione del risultato non disponibile al momento"), findsOneWidget);
      expect(find.text("Salva risultato"), findsNothing);
      expect(find.byType(Switch), findsNothing);
      expect(find.text("Mario Rossi"), findsNothing);
      expect(repo.chiamateRisultato, 0);
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
