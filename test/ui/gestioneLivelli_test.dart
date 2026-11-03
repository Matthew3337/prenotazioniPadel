import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thepadel/core/di/depInjection.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/ui/gestioneLivelli.dart';

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

  setUp(() async
  {
    await sl.reset();
    await registraPreferenzeDiTest();
    repo = FakeAdminRepo();
    repo.utenti = [
      utenteAdminDiTest(telefono: "1", nome: "Luca", cognome: "Bianchi", livello: 2.5, punteggio: 12),
      utenteAdminDiTest(telefono: "2", nome: "Anna", cognome: "Verdi", livello: 4.0, punteggio: 30),
    ];
    registraBlocDiTest(repoPartita: FakePartitaRepo(), repoCampo: FakeCampoRepo(), repoPrenotazione: FakePrenotazioneRepo(), repoUtente: FakeUtenteRepo(), repoAdmin: repo);
  });

  tearDown(() async
  {
    await sl.reset();
  });

  Future<void> apriPagina(WidgetTester tester) async
  {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(theme: temaDiTest(), home: const GestioneLivelliPage()));
    await tester.pumpAndSettle();
  }

  Finder selettore(int riga)
  {
    return find.byType(DropdownButton<double>).at(riga);
  }

  //apre il selettore della riga e sceglie il livello: l'ultimo testo e quello del menu aperto
  Future<void> scegliLivello(WidgetTester tester, int riga, String livello) async
  {
    await tester.tap(selettore(riga));
    await tester.pumpAndSettle();
    await tester.tap(find.text(livello).last);
    await tester.pump();
  }

  testWidgets("all'apertura carica tutti gli utenti e mostra nome, punti e livello", (tester) async
  {
    await apriPagina(tester);

    expect(repo.cercaRicevuti, [""]);
    expect(find.text("Gestione livelli"), findsOneWidget);
    expect(find.text("Luca Bianchi"), findsOneWidget);
    expect(find.text("12 punti"), findsOneWidget);
    expect(find.text("Anna Verdi"), findsOneWidget);
    expect(tester.widget<DropdownButton<double>>(selettore(0)).value, 2.5);
    expect(tester.widget<DropdownButton<double>>(selettore(1)).value, 4.0);
  });

  testWidgets("il selettore propone i livelli da 0 a 5 con passo 0,5", (tester) async
  {
    await apriPagina(tester);

    final voci = tester.widget<DropdownButton<double>>(selettore(0)).items!;

    expect(voci.map((v) => v.value).toList(), [0.0, 0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0]);
  });

  testWidgets("un livello fuori dal passo non rompe la pagina: resta visibile come testo", (tester) async
  {
    repo.utenti = [utenteAdminDiTest(livello: 2.3)];
    await apriPagina(tester);

    expect(tester.takeException(), isNull);
    expect(tester.widget<DropdownButton<double>>(selettore(0)).value, isNull);
    expect(find.text("2.3"), findsOneWidget);
  });

  testWidgets("nessun utente trovato", (tester) async
  {
    repo.utenti = [];
    await apriPagina(tester);

    expect(find.text("Nessun utente trovato"), findsOneWidget);
  });

  group("debounce della ricerca", ()
  {
    testWidgets("la richiesta parte solo 400 ms dopo l'ultima lettera, con il testo finale ripulito", (tester) async
    {
      await apriPagina(tester);

      await tester.enterText(find.byType(TextField), "m");
      await tester.pump(const Duration(milliseconds: 300));
      await tester.enterText(find.byType(TextField), "ma");
      await tester.pump(const Duration(milliseconds: 300));
      await tester.enterText(find.byType(TextField), " mar ");
      await tester.pump(const Duration(milliseconds: 399));

      expect(repo.cercaRicevuti, [""]);

      await tester.pump(const Duration(milliseconds: 1));
      await tester.pumpAndSettle();

      expect(repo.cercaRicevuti, ["", "mar"]);
    });

    testWidgets("uscendo dalla pagina prima dei 400 ms non parte nulla", (tester) async
    {
      await apriPagina(tester);

      await tester.enterText(find.byType(TextField), "mar");
      await tester.pumpWidget(MaterialApp(theme: temaDiTest(), home: const SizedBox.shrink()));
      await tester.pump(const Duration(seconds: 1));

      expect(repo.cercaRicevuti, [""]);
      expect(tester.takeException(), isNull);
    });
  });

  group("cambio di livello", ()
  {
    testWidgets("lo spinner compare solo sulla riga in salvataggio e le altre sono spente", (tester) async
    {
      repo.attesaLivello = Completer<void>();
      await apriPagina(tester);

      await scegliLivello(tester, 0, "3.0");

      expect(repo.telefonoLivelloRicevuto, "1");
      expect(repo.livelloRicevuto, 3.0);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      //la riga di Luca ha lo spinner al posto del selettore
      expect(find.byType(DropdownButton<double>), findsOneWidget);
      expect(tester.widget<DropdownButton<double>>(selettore(0)).onChanged, isNull);
      expect(find.text("Luca Bianchi"), findsOneWidget);
      expect(find.text("Anna Verdi"), findsOneWidget);

      repo.attesaLivello!.complete();
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(DropdownButton<double>), findsNWidgets(2));
    });

    testWidgets("riuscito: SnackBar e il selettore mostra il livello nuovo", (tester) async
    {
      await apriPagina(tester);

      await scegliLivello(tester, 0, "3.0");
      await tester.pumpAndSettle();

      expect(find.widgetWithText(SnackBar, "Livello aggiornato"), findsOneWidget);
      expect(tester.widget<DropdownButton<double>>(selettore(0)).value, 3.0);
      expect(repo.cercaRicevuti, [""]);
    });

    testWidgets("rifiutato: SnackBar col messaggio del server e la lista si ricarica", (tester) async
    {
      repo.erroreLivello = PartitaNonTrovata(messaggio: "Utente non trovato");
      await apriPagina(tester);

      await scegliLivello(tester, 0, "3.0");
      await tester.pumpAndSettle();

      expect(find.widgetWithText(SnackBar, "Utente non trovato"), findsOneWidget);
      expect(repo.cercaRicevuti, ["", ""]);
      expect(tester.widget<DropdownButton<double>>(selettore(0)).value, 2.5);
    });

    testWidgets("timeout: SnackBar col messaggio generico e la lista resta", (tester) async
    {
      repo.erroreLivello = Exception("timeout");
      await apriPagina(tester);

      await scegliLivello(tester, 0, "3.0");
      await tester.pumpAndSettle();

      expect(find.widgetWithText(SnackBar, ErroreGenericoServer().messaggio), findsOneWidget);
      expect(find.text("Luca Bianchi"), findsOneWidget);
    });

    testWidgets("scegliere il livello che ha gia non chiama il server", (tester) async
    {
      await apriPagina(tester);

      await scegliLivello(tester, 0, "2.5");
      await tester.pumpAndSettle();

      expect(repo.chiamateLivello, 0);
      expect(find.byType(SnackBar), findsNothing);
    });
  });

  group("errore sull'elenco", ()
  {
    testWidgets("mostra il messaggio e Riprova rifa la stessa ricerca", (tester) async
    {
      await apriPagina(tester);

      repo.erroreUtenti = ErroreGenericoServer();
      await tester.enterText(find.byType(TextField), "mar");
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.text("Non siamo riusciti a caricare gli utenti"), findsOneWidget);
      expect(find.text(ErroreGenericoServer().messaggio), findsOneWidget);

      repo.erroreUtenti = null;
      await tester.tap(find.text("Riprova"));
      await tester.pumpAndSettle();

      expect(repo.cercaRicevuti, ["", "mar", "mar"]);
      expect(find.text("Luca Bianchi"), findsOneWidget);
    });
  });
}
