import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thepadel/bloc/autenticazione/authBloc.dart';
import 'package:thepadel/core/di/depInjection.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/ui/registrazione.dart';
import 'package:thepadel/ui/stileApp.dart';
import 'package:thepadel/useCase/authUseCase.dart';
import 'package:thepadel/useCase/eccezioniUseCase.dart';

import '../fake/fakeUtenteRepo.dart';
import '../fake/temaDiTest.dart';

void main()
{
  setUpAll(caricaFontDellApp);

  late FakeUtenteRepo repo;

  setUp(() async
  {
    await sl.reset();
    repo = FakeUtenteRepo();
    sl.registerFactory<AuthBloc>(() => AuthBloc(loginUseCase: LoginUseCase(repo: repo), registrazioneUseCase: RegistrazioneUseCase(repo: repo), logoutUseCase: LogoutUseCase(repo: repo), eliminaAccountUseCase: EliminaAccountUseCase(repo: repo)));
  });

  tearDown(() async
  {
    await sl.reset();
  });

  //apre la pagina sopra una schermata finta, cosi si puo vedere il ritorno al login
  Future<void> apriPagina(WidgetTester tester, {Size schermo = const Size(390, 844)}) async
  {
    tester.view.physicalSize = schermo * 3.0;
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      theme: temaDiTest(),
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: ()
            {
              Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const RegistrazionePage()));
            },
            child: const Text("apri"),
          ),
        ),
      ),
    ));
    await tester.tap(find.text("apri"));
    await tester.pumpAndSettle();
  }

  //nell'ordine: nome, cognome, telefono, password. La data non e un TextField
  Future<void> compila(WidgetTester tester, {String nome = "Mario", String cognome = "Rossi", String telefono = "3331234567", String password = "segreta"}) async
  {
    await tester.enterText(find.byType(TextField).at(0), nome);
    await tester.enterText(find.byType(TextField).at(1), cognome);
    await tester.enterText(find.byType(TextField).at(2), telefono);
    await tester.enterText(find.byType(TextField).at(3), password);
  }

  Future<void> scegliData(WidgetTester tester) async
  {
    await tester.tap(find.text("Data di nascita").first);
    await tester.pumpAndSettle();
    await tester.tap(find.text("OK"));
    await tester.pumpAndSettle();
  }

  Future<void> registrati(WidgetTester tester) async
  {
    await tester.ensureVisible(find.widgetWithText(ElevatedButton, "Registrati"));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, "Registrati"));
    await tester.pumpAndSettle();
  }

  testWidgets("mostra tutti i campi e nessun errore", (tester) async
  {
    await apriPagina(tester);

    expect(find.text("Crea il tuo account"), findsOneWidget);
    expect(find.text("Nome"), findsOneWidget);
    expect(find.text("Cognome"), findsOneWidget);
    //il nome del campo data compare due volte: come hint del decoratore e come testo segnaposto
    expect(find.text("Data di nascita"), findsWidgets);
    expect(find.text("Accederai con il numero di telefono."), findsNothing);
    expect(find.text("Telefono"), findsOneWidget);
    expect(find.text("Password"), findsOneWidget);
    expect(find.byType(RiquadroMessaggio), findsNothing);
    expect(repo.chiamateRegistrazione, 0);
  });

  testWidgets("su un telefono piccolo non va in overflow", (tester) async
  {
    await apriPagina(tester, schermo: const Size(320, 568));

    expect(tester.takeException(), isNull);
  });

  group("validazione", ()
  {
    testWidgets("nome mancante: messaggio sotto il campo, sotto gli altri niente", (tester) async
    {
      await apriPagina(tester);
      await compila(tester, nome: "   ");
      await scegliData(tester);

      await registrati(tester);

      expect(find.text(NomeMancante().message), findsOneWidget);
      expect(find.text(CognomeMancante().message), findsNothing);
      expect(find.byType(RiquadroMessaggio), findsNothing);
      expect(repo.chiamateRegistrazione, 0);
    });

    testWidgets("cognome mancante", (tester) async
    {
      await apriPagina(tester);
      await compila(tester, cognome: "");

      await registrati(tester);

      expect(find.text(CognomeMancante().message), findsOneWidget);
    });

    testWidgets("data non scelta", (tester) async
    {
      await apriPagina(tester);
      await compila(tester);

      await registrati(tester);

      expect(find.text(DataNascitaMancante().message), findsOneWidget);
    });

    testWidgets("telefono non valido", (tester) async
    {
      await apriPagina(tester);
      await compila(tester, telefono: "333");
      await scegliData(tester);

      await registrati(tester);

      expect(find.text(FormatoTelefonoNonValido().message), findsOneWidget);
    });

    testWidgets("password mancante", (tester) async
    {
      await apriPagina(tester);
      await compila(tester, password: "");
      await scegliData(tester);

      await registrati(tester);

      expect(find.text(PwMancante().message), findsOneWidget);
    });
  });

  group("risposta del server", ()
  {
    testWidgets("la data scelta dal calendario compare nel campo", (tester) async
    {
      await apriPagina(tester);

      await scegliData(tester);

      final adesso = DateTime.now();
      final attesa = DateTime(adesso.year - 18, adesso.month, adesso.day);
      final gg = attesa.day.toString().padLeft(2, '0');
      final mm = attesa.month.toString().padLeft(2, '0');
      expect(find.text("$gg/$mm/${attesa.year}"), findsOneWidget);
    });

    testWidgets("successo: SnackBar e ritorno al login", (tester) async
    {
      await apriPagina(tester);
      await compila(tester);
      await scegliData(tester);

      await registrati(tester);

      expect(repo.chiamateRegistrazione, 1);
      expect(find.byType(RegistrazionePage), findsNothing);
      expect(find.text("apri"), findsOneWidget);
      expect(find.widgetWithText(SnackBar, "Registrazione avvenuta con successo, effettua il login"), findsOneWidget);
    });

    testWidgets("telefono gia registrato: riquadro col messaggio e Accedi torna al login", (tester) async
    {
      repo.erroreRegistrazione = TelefonoDuplicatoException();
      await apriPagina(tester);
      await compila(tester);
      await scegliData(tester);

      await registrati(tester);

      expect(find.widgetWithText(RiquadroMessaggio, TelefonoDuplicatoException().messaggio), findsOneWidget);

      await tester.tap(find.descendant(of: find.byType(RiquadroMessaggio), matching: find.text("Accedi")));
      await tester.pumpAndSettle();

      expect(find.byType(RegistrazionePage), findsNothing);
    });

    testWidgets("data rifiutata dal server: messaggio sotto il campo data", (tester) async
    {
      repo.erroreRegistrazione = DataNonValida();
      await apriPagina(tester);
      await compila(tester);
      await scegliData(tester);

      await registrati(tester);

      expect(find.text(DataNonValida().messaggio), findsOneWidget);
      expect(find.byType(RiquadroMessaggio), findsNothing);
    });

    testWidgets("errore generico: riquadro col messaggio, senza Accedi al suo interno", (tester) async
    {
      repo.erroreRegistrazione = ErroreGenericoServer();
      await apriPagina(tester);
      await compila(tester);
      await scegliData(tester);

      await registrati(tester);

      expect(find.widgetWithText(RiquadroMessaggio, ErroreGenericoServer().messaggio), findsOneWidget);
      expect(find.descendant(of: find.byType(RiquadroMessaggio), matching: find.text("Accedi")), findsNothing);
    });

    testWidgets("durante l'invio campi e bottoni sono spenti", (tester) async
    {
      repo.attesaRegistrazione = Completer<void>();
      await apriPagina(tester);
      await compila(tester);
      await scegliData(tester);

      await tester.ensureVisible(find.widgetWithText(ElevatedButton, "Registrati"));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, "Registrati"));
      await tester.pump();

      expect(find.text("Attendi…"), findsOneWidget);
      expect(tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed, isNull);
      for(final campo in tester.widgetList<TextField>(find.byType(TextField)))
      {
        expect(campo.enabled, false);
      }
      expect(tester.widget<IconButton>(find.byType(IconButton)).onPressed, isNull);

      repo.attesaRegistrazione!.complete();
      await tester.pumpAndSettle();
    });
  });

  group("ritorno al login", ()
  {
    testWidgets("la freccia torna al login", (tester) async
    {
      await apriPagina(tester);

      await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
      await tester.pumpAndSettle();

      expect(find.byType(RegistrazionePage), findsNothing);
    });

    testWidgets("il link Accedi torna al login", (tester) async
    {
      await apriPagina(tester);

      await tester.ensureVisible(find.text("Accedi"));
      await tester.pumpAndSettle();
      await tester.tap(find.text("Accedi"));
      await tester.pumpAndSettle();

      expect(find.byType(RegistrazionePage), findsNothing);
    });
  });
}
