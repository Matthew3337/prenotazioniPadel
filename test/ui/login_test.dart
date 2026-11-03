import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thepadel/bloc/autenticazione/authBloc.dart';
import 'package:thepadel/core/di/depInjection.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/ui/home.dart';
import 'package:thepadel/ui/login.dart';
import 'package:thepadel/ui/registrazione.dart';
import 'package:thepadel/useCase/authUseCase.dart';
import 'package:thepadel/useCase/eccezioniUseCase.dart';

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

  late FakeUtenteRepo repo;

  setUp(() async
  {
    await sl.reset();
    await registraPreferenzeDiTest();
    repo = FakeUtenteRepo();
    sl.registerFactory<AuthBloc>(() => AuthBloc(loginUseCase: LoginUseCase(repo: repo), registrazioneUseCase: RegistrazioneUseCase(repo: repo)));
    registraBlocDiTest(repoPartita: FakePartitaRepo(), repoCampo: FakeCampoRepo(), repoPrenotazione: FakePrenotazioneRepo(), repoUtente: repo);
  });

  tearDown(() async
  {
    await sl.reset();
  });

  Future<void> apriPagina(WidgetTester tester, {Size schermo = const Size(390, 844)}) async
  {
    tester.view.physicalSize = schermo * 3.0;
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(theme: temaDiTest(), home: const LoginPage()));
    await tester.pumpAndSettle();
  }

  Future<void> compila(WidgetTester tester, String telefono, String password) async
  {
    await tester.enterText(find.byType(TextField).at(0), telefono);
    await tester.enterText(find.byType(TextField).at(1), password);
  }

  Future<void> accedi(WidgetTester tester) async
  {
    await tester.tap(find.widgetWithText(ElevatedButton, "Accedi"));
    await tester.pumpAndSettle();
  }

  testWidgets("mostra i campi, il bottone e il link alla registrazione", (tester) async
  {
    await apriPagina(tester);

    expect(find.text("Telefono"), findsOneWidget);
    expect(find.text("Password"), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, "Accedi"), findsOneWidget);
    expect(find.text("Registrati"), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.text("Il numero deve avere 10 cifre"), findsNothing);
    expect(repo.chiamateLogin, 0);
  });

  testWidgets("su un telefono piccolo non va in overflow", (tester) async
  {
    await apriPagina(tester, schermo: const Size(320, 568));

    expect(tester.takeException(), isNull);
  });

  testWidgets("telefono non valido: il messaggio compare e il server non viene chiamato", (tester) async
  {
    await apriPagina(tester);
    await compila(tester, "333", "segreta");

    await accedi(tester);

    expect(find.text(FormatoTelefonoNonValido().message), findsOneWidget);
    expect(repo.chiamateLogin, 0);
  });

  testWidgets("password mancante: il messaggio compare e il server non viene chiamato", (tester) async
  {
    await apriPagina(tester);
    await compila(tester, "3331234567", "");

    await accedi(tester);

    expect(find.text(PwMancante().message), findsOneWidget);
    expect(repo.chiamateLogin, 0);
  });

  testWidgets("credenziali errate: il messaggio del server e si resta sulla pagina", (tester) async
  {
    repo.erroreLogin = TelOPasswordErrata();
    await apriPagina(tester);
    await compila(tester, "3331234567", "sbagliata");

    await accedi(tester);

    expect(find.text(TelOPasswordErrata().messaggio), findsOneWidget);
    expect(find.byType(LoginPage), findsOneWidget);
  });

  testWidgets("durante il login campi e bottone sono spenti e il testo dice Accesso in corso", (tester) async
  {
    repo.attesaLogin = Completer<void>();
    await apriPagina(tester);
    await compila(tester, "3331234567", "segreta");

    await tester.tap(find.widgetWithText(ElevatedButton, "Accedi"));
    await tester.pump();

    expect(find.text("Accesso in corso…"), findsOneWidget);
    expect(tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed, isNull);
    for(final campo in tester.widgetList<TextField>(find.byType(TextField)))
    {
      expect(campo.enabled, false);
    }
    expect(find.text("Registrati"), findsNothing);

    repo.attesaLogin!.complete();
    await tester.pumpAndSettle();
  });

  testWidgets("login riuscito: la home prende il posto del login", (tester) async
  {
    await apriPagina(tester);
    await compila(tester, "3331234567", "segreta");

    await accedi(tester);

    expect(repo.chiamateLogin, 1);
    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byType(LoginPage), findsNothing);
  });

  testWidgets("Mostra e Nascondi cambiano la visibilita della password", (tester) async
  {
    await apriPagina(tester);

    TextField password() => tester.widget<TextField>(find.byType(TextField).at(1));

    expect(password().obscureText, true);

    await tester.tap(find.text("Mostra"));
    await tester.pump();
    expect(password().obscureText, false);

    await tester.tap(find.text("Nascondi"));
    await tester.pump();
    expect(password().obscureText, true);
  });

  testWidgets("Registrati apre la registrazione", (tester) async
  {
    await apriPagina(tester);

    await tester.tap(find.text("Registrati"));
    await tester.pumpAndSettle();

    expect(find.byType(RegistrazionePage), findsOneWidget);
  });
}
