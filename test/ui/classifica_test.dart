import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thepadel/bloc/classifica/classificaBloc.dart';
import 'package:thepadel/core/di/depInjection.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/ui/classifica.dart';
import 'package:thepadel/useCase/classificaUseCase.dart';

import '../fake/fakeUtenteRepo.dart';

void main()
{
  late FakeUtenteRepo repo;

  setUp(() async
  {
    await sl.reset();
    repo = FakeUtenteRepo();
    sl.registerFactory<ClassificaBloc>(() => ClassificaBloc(classificaUseCase: ClassificaUseCase(repo: repo)));
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

    await tester.pumpWidget(const MaterialApp(home: ClassificaPage()));
    await tester.pumpAndSettle();
  }

  //il colore della card che contiene il testo: e il primo Container risalendo l'albero
  Color? sfondoCard(WidgetTester tester, String testo)
  {
    final Container card = tester.widget<Container>(find.ancestor(of: find.text(testo), matching: find.byType(Container)).first);
    return (card.decoration as BoxDecoration).color;
  }

  FontWeight? pesoTesto(WidgetTester tester, String testo)
  {
    return tester.widget<Text>(find.text(testo)).style?.fontWeight;
  }

  testWidgets("mostra posizione, nome e cognome, punteggio per ogni riga", (tester) async
  {
    repo.voci = [
      voceDiTest(posizione: 1, nome: "Mario", cognome: "Rossi", punteggio: 12),
      voceDiTest(posizione: 2, nome: "Anna", cognome: "Verdi", punteggio: 7),
    ];
    await apriPagina(tester);

    expect(repo.chiamate, 1);
    expect(find.text("Classifica"), findsOneWidget);
    expect(find.text("1"), findsOneWidget);
    expect(find.text("Mario Rossi"), findsOneWidget);
    expect(find.text("12 pt"), findsOneWidget);
    expect(find.text("2"), findsOneWidget);
    expect(find.text("Anna Verdi"), findsOneWidget);
    expect(find.text("7 pt"), findsOneWidget);
    expect(find.text("Nessun giocatore in classifica"), findsNothing);
  });

  testWidgets("rispetta l'ordine del server, senza riordinare per punteggio", (tester) async
  {
    //punteggi volutamente crescenti: se la pagina riordinasse, Mario finirebbe in fondo
    repo.voci = [
      voceDiTest(posizione: 1, nome: "Mario", cognome: "Rossi", punteggio: 1),
      voceDiTest(posizione: 2, nome: "Anna", cognome: "Verdi", punteggio: 5),
      voceDiTest(posizione: 3, nome: "Luca", cognome: "Bianchi", punteggio: 9),
    ];
    await apriPagina(tester);

    final double yMario = tester.getTopLeft(find.text("Mario Rossi")).dy;
    final double yAnna = tester.getTopLeft(find.text("Anna Verdi")).dy;
    final double yLuca = tester.getTopLeft(find.text("Luca Bianchi")).dy;

    expect(yMario, lessThan(yAnna));
    expect(yAnna, lessThan(yLuca));
  });

  testWidgets("a pari punti la posizione si ripete: 1, 2, 2, 4", (tester) async
  {
    repo.voci = [
      voceDiTest(posizione: 1, nome: "Mario", cognome: "Rossi", punteggio: 9),
      voceDiTest(posizione: 2, nome: "Anna", cognome: "Verdi", punteggio: 5),
      voceDiTest(posizione: 2, nome: "Luca", cognome: "Bianchi", punteggio: 5),
      voceDiTest(posizione: 4, nome: "Sara", cognome: "Neri", punteggio: 0),
    ];
    await apriPagina(tester);

    expect(find.text("1"), findsOneWidget);
    expect(find.text("2"), findsNWidgets(2));
    expect(find.text("3"), findsNothing);
    expect(find.text("4"), findsOneWidget);
  });

  testWidgets("evidenzia solo la riga dell'utente corrente", (tester) async
  {
    repo.voci = [
      voceDiTest(posizione: 1, nome: "Anna", cognome: "Verdi", punteggio: 9),
      voceDiTest(posizione: 2, nome: "Mario", cognome: "Rossi", punteggio: 5, utenteCorrente: true),
    ];
    await apriPagina(tester);

    expect(sfondoCard(tester, "Mario Rossi"), const Color(0xFFE7F1FC));
    expect(pesoTesto(tester, "Mario Rossi"), FontWeight.w700);
    expect(pesoTesto(tester, "5 pt"), FontWeight.w700);

    expect(sfondoCard(tester, "Anna Verdi"), Colors.white);
    expect(pesoTesto(tester, "Anna Verdi"), FontWeight.w500);
    expect(pesoTesto(tester, "9 pt"), FontWeight.w500);
  });

  testWidgets("senza utente corrente (admin) nessuna riga e evidenziata", (tester) async
  {
    repo.voci = [
      voceDiTest(posizione: 1, nome: "Anna", cognome: "Verdi"),
      voceDiTest(posizione: 2, nome: "Mario", cognome: "Rossi"),
    ];
    await apriPagina(tester);

    expect(sfondoCard(tester, "Anna Verdi"), Colors.white);
    expect(sfondoCard(tester, "Mario Rossi"), Colors.white);
  });

  testWidgets("lista vuota: mostra il messaggio e nessuna riga", (tester) async
  {
    repo.voci = [];
    await apriPagina(tester);

    expect(find.text("Nessun giocatore in classifica"), findsOneWidget);
    expect(find.textContaining(" pt"), findsNothing);
    expect(find.text("Riprova"), findsNothing);
  });

  testWidgets("errore di caricamento: messaggio e Riprova rifa la richiesta", (tester) async
  {
    repo.errore = ErroreGenericoServer();
    await apriPagina(tester);

    expect(find.text(ErroreGenericoServer().messaggio), findsOneWidget);
    expect(find.text("Riprova"), findsOneWidget);
    expect(find.text("Classifica"), findsOneWidget);

    repo.errore = null;
    repo.voci = [voceDiTest(nome: "Mario", cognome: "Rossi")];
    await tester.tap(find.text("Riprova"));
    await tester.pumpAndSettle();

    expect(repo.chiamate, 2);
    expect(find.text("Mario Rossi"), findsOneWidget);
    expect(find.text("Riprova"), findsNothing);
  });

  testWidgets("pull-to-refresh: rifa la richiesta e mostra i dati nuovi", (tester) async
  {
    repo.voci = [voceDiTest(nome: "Mario", cognome: "Rossi", punteggio: 3)];
    await apriPagina(tester);

    repo.voci = [voceDiTest(nome: "Mario", cognome: "Rossi", punteggio: 6)];
    await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();

    expect(repo.chiamate, 2);
    expect(find.text("6 pt"), findsOneWidget);
    expect(find.text("3 pt"), findsNothing);
  });

  testWidgets("pull-to-refresh funziona anche con la lista vuota", (tester) async
  {
    repo.voci = [];
    await apriPagina(tester);

    repo.voci = [voceDiTest(nome: "Mario", cognome: "Rossi")];
    await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();

    expect(repo.chiamate, 2);
    expect(find.text("Mario Rossi"), findsOneWidget);
    expect(find.text("Nessun giocatore in classifica"), findsNothing);
  });

  testWidgets("con un nome lunghissimo la riga non va in overflow", (tester) async
  {
    repo.voci = [voceDiTest(nome: "Pierfrancescomaria", cognome: "Dellaportadisantagostinoeabramo", punteggio: 123456)];
    await apriPagina(tester);

    expect(tester.takeException(), isNull);
    expect(find.text("123456 pt"), findsOneWidget);
  });

  testWidgets("la freccia indietro chiude la pagina", (tester) async
  {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () {
            Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const ClassificaPage()));
          },
          child: const Text("apri"),
        ),
      ),
    ));
    await tester.tap(find.text("apri"));
    await tester.pumpAndSettle();
    expect(find.byType(ClassificaPage), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.byType(ClassificaPage), findsNothing);
  });
}
