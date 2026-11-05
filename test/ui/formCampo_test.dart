import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thepadel/core/di/depInjection.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/ui/formCampo.dart';
import 'package:thepadel/ui/gestioneCampi.dart';
import 'package:thepadel/ui/stileApp.dart';

import '../fake/blocDiTest.dart';
import '../fake/fakeCampoRepo.dart';
import '../fake/fakePartitaRepo.dart';
import '../fake/fakePreferenze.dart';
import '../fake/fakePrenotazioneRepo.dart';
import '../fake/fakeUtenteRepo.dart';
import '../fake/temaDiTest.dart';

const String partiteCollegate = "Il campo ha partite collegate e non può essere eliminato";

void main()
{
  setUpAll(caricaFontDellApp);

  late FakeCampoRepo repo;

  setUp(() async
  {
    await sl.reset();
    await registraPreferenzeDiTest();
    repo = FakeCampoRepo();
    registraBlocDiTest(repoPartita: FakePartitaRepo(), repoCampo: repo, repoPrenotazione: FakePrenotazioneRepo(), repoUtente: FakeUtenteRepo());
  });

  tearDown(() async
  {
    await sl.reset();
  });

  //il form usa il bloc dell'elenco: ci si arriva sempre dalla pagina dei campi, come nell'app
  Future<void> apriElenco(WidgetTester tester) async
  {
    tester.view.physicalSize = const Size(390, 844) * 3.0;
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(theme: temaDiTest(), home: const GestioneCampiPage()));
    await tester.pumpAndSettle();
  }

  Future<void> apriNuovo(WidgetTester tester) async
  {
    await apriElenco(tester);
    await tester.tap(find.text("Nuovo campo"));
    await tester.pumpAndSettle();
  }

  Future<void> apriModifica(WidgetTester tester) async
  {
    await apriElenco(tester);
    await tester.tap(find.text("Campo Centrale"));
    await tester.pumpAndSettle();
  }

  Finder salva()
  {
    return find.widgetWithText(ElevatedButton, "Salva");
  }

  Finder riquadro(String testo)
  {
    return find.descendant(of: find.byType(RiquadroMessaggio), matching: find.text(testo));
  }

  Finder nelDialog(String testo)
  {
    return find.descendant(of: find.byType(Dialog), matching: find.text(testo));
  }

  Future<void> confermaElimina(WidgetTester tester) async
  {
    await tester.tap(find.text("Elimina campo"));
    await tester.pumpAndSettle();
    await tester.tap(nelDialog("Elimina"));
    await tester.pumpAndSettle();
  }

  group("salvataggio", ()
  {
    testWidgets("campo nuovo: manda i dati, torna all'elenco e lo mostra senza richiederlo", (tester) async
    {
      await apriNuovo(tester);

      await tester.enterText(find.byType(TextField), "  Campo Est  ");
      await tester.tap(find.byType(Switch));
      await tester.pump();
      await tester.tap(salva());
      await tester.pumpAndSettle();

      expect(repo.chiamateCrea, 1);
      expect(repo.nomeRicevuto, "Campo Est");
      expect(repo.alCopertoRicevuto, true);
      expect(repo.aperturaRicevuta, const TimeOfDay(hour: 9, minute: 0));
      expect(repo.chiusuraRicevuta, const TimeOfDay(hour: 23, minute: 0));

      expect(find.byType(FormCampoPage), findsNothing);
      expect(find.text("Campo Est"), findsOneWidget);
      expect(find.text("Campo salvato"), findsOneWidget);
      expect(repo.chiamateCampi, 1);
    });

    testWidgets("modifica: manda l'id del campo e l'elenco si aggiorna", (tester) async
    {
      await apriModifica(tester);

      await tester.enterText(find.byType(TextField), "Rinominato");
      await tester.tap(find.byType(Switch));
      await tester.pump();
      await tester.tap(salva());
      await tester.pumpAndSettle();

      expect(repo.idModificaRicevuto, 3);
      expect(repo.alCopertoRicevuto, false);
      expect(find.text("Rinominato"), findsOneWidget);
      expect(find.text("Campo Centrale"), findsNothing);
      expect(find.text("Campo salvato"), findsOneWidget);
    });

    testWidgets("il nome vuoto resta nel form col messaggio nel riquadro", (tester) async
    {
      await apriNuovo(tester);

      await tester.tap(salva());
      await tester.pumpAndSettle();

      expect(find.byType(FormCampoPage), findsOneWidget);
      expect(riquadro("Inserisci il nome del campo"), findsOneWidget);
      expect(repo.chiamateCrea, 0);
    });

    testWidgets("durante il salvataggio il bottone e spento con lo spinner", (tester) async
    {
      await apriNuovo(tester);
      final attesa = Completer<void>();
      repo.attesaSalva = attesa;

      await tester.enterText(find.byType(TextField), "Campo Est");
      await tester.tap(salva());
      await tester.pump();

      final ElevatedButton bottone = tester.widget(find.byType(ElevatedButton));
      expect(bottone.onPressed, isNull);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, false);

      attesa.complete();
      await tester.pumpAndSettle();

      expect(find.byType(FormCampoPage), findsNothing);
    });

    testWidgets("salvare di nuovo toglie il messaggio d'errore precedente", (tester) async
    {
      await apriModifica(tester);
      repo.erroreSalva = OperazioneRifiutata(messaggio: "Dati non validi");

      await tester.tap(salva());
      await tester.pumpAndSettle();
      expect(riquadro("Dati non validi"), findsOneWidget);

      repo.erroreSalva = null;
      final attesa = Completer<void>();
      repo.attesaSalva = attesa;
      await tester.tap(salva());
      await tester.pump();
      expect(riquadro("Dati non validi"), findsNothing);

      attesa.complete();
      await tester.pumpAndSettle();
    });
  });

  group("eliminazione", ()
  {
    testWidgets("su un campo nuovo non si puo eliminare", (tester) async
    {
      await apriNuovo(tester);

      expect(find.text("Elimina campo"), findsNothing);
    });

    testWidgets("chiede conferma: Indietro non chiama il server", (tester) async
    {
      await apriModifica(tester);

      await tester.tap(find.text("Elimina campo"));
      await tester.pumpAndSettle();

      expect(nelDialog("Eliminare il campo?"), findsOneWidget);

      await tester.tap(nelDialog("Indietro"));
      await tester.pumpAndSettle();

      expect(repo.chiamateElimina, 0);
      expect(find.byType(FormCampoPage), findsOneWidget);
    });

    testWidgets("confermando torna all'elenco senza il campo", (tester) async
    {
      await apriModifica(tester);

      await confermaElimina(tester);

      expect(repo.idEliminaRicevuto, 3);
      expect(find.byType(FormCampoPage), findsNothing);
      expect(find.text("Campo Centrale"), findsNothing);
      expect(find.text("Campo eliminato"), findsOneWidget);
      expect(repo.chiamateCampi, 1);
    });

    testWidgets("partite collegate: il messaggio del server sta nel riquadro e si resta nel form", (tester) async
    {
      await apriModifica(tester);
      repo.erroreElimina = OperazioneRifiutata(messaggio: partiteCollegate);

      await confermaElimina(tester);

      expect(find.byType(FormCampoPage), findsOneWidget);
      expect(riquadro(partiteCollegate), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
      expect(repo.chiamateCampi, 1);
    });

    testWidgets("riaprendo il form l'errore precedente non c'e piu e l'elenco e rimasto", (tester) async
    {
      await apriModifica(tester);
      repo.erroreElimina = OperazioneRifiutata(messaggio: partiteCollegate);
      await confermaElimina(tester);

      final NavigatorState navigator = tester.state(find.byType(Navigator).first);
      navigator.pop();
      await tester.pumpAndSettle();

      expect(find.text("Campo Centrale"), findsOneWidget);

      await tester.tap(find.text("Campo Centrale"));
      await tester.pumpAndSettle();

      expect(riquadro(partiteCollegate), findsNothing);
    });
  });
}
