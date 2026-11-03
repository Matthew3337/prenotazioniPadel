import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thepadel/bloc/autenticazione/authBloc.dart';
import 'package:thepadel/core/di/depInjection.dart';
import 'package:thepadel/ui/home.dart';
import 'package:thepadel/ui/homeAdmin.dart';
import 'package:thepadel/ui/login.dart';
import 'package:thepadel/useCase/authUseCase.dart';
import 'package:thepadel/dataLayer/exception.dart';

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
    sl.registerFactory<AuthBloc>(() => AuthBloc(loginUseCase: LoginUseCase(repo: repo), registrazioneUseCase: RegistrazioneUseCase(repo: repo), logoutUseCase: LogoutUseCase(repo: repo)));
    registraBlocDiTest(repoPartita: FakePartitaRepo(), repoCampo: FakeCampoRepo(), repoPrenotazione: FakePrenotazioneRepo(), repoUtente: repo);
  });

  tearDown(() async
  {
    await sl.reset();
  });

  //la home sta sopra un'altra pagina: dopo il logout non deve restare nessuna delle due
  Future<void> apriPagina(WidgetTester tester, Widget home) async
  {
    tester.view.physicalSize = const Size(1170, 3600);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      theme: temaDiTest(),
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: ()
            {
              Navigator.push<void>(context, MaterialPageRoute<void>(builder: (_) => home));
            },
            child: const Text("apri"),
          ),
        ),
      ),
    ));
    await tester.tap(find.text("apri"));
    await tester.pumpAndSettle();
  }

  Future<void> apriDialog(WidgetTester tester) async
  {
    final esci = find.widgetWithText(TextButton, "Esci");
    await tester.ensureVisible(esci);
    await tester.pumpAndSettle();
    await tester.tap(esci);
    await tester.pumpAndSettle();
  }

  Finder bottoneDelDialog(String testo)
  {
    return find.descendant(of: find.byType(Dialog), matching: find.widgetWithText(ElevatedButton, testo));
  }

  final pagine = <String, Widget>{"home utente": const HomePage(), "home admin": const HomeAdminPage()};

  pagine.forEach((nome, pagina)
  {
    group(nome, ()
    {
      testWidgets("Esci chiede conferma senza fare il logout", (tester) async
      {
        await apriPagina(tester, pagina);

        await apriDialog(tester);

        expect(find.text("Uscire dall'app?"), findsOneWidget);
        expect(find.text("Per rientrare dovrai accedere di nuovo."), findsOneWidget);
        expect(repo.chiamateLogout, 0);
      });

      testWidgets("Annulla chiude il dialog e si resta sulla pagina", (tester) async
      {
        await apriPagina(tester, pagina);
        await apriDialog(tester);

        await tester.tap(bottoneDelDialog("Annulla"));
        await tester.pumpAndSettle();

        expect(find.byType(Dialog), findsNothing);
        expect(find.byType(pagina.runtimeType), findsOneWidget);
        expect(repo.chiamateLogout, 0);
      });

      testWidgets("confermando torna al login con lo stack vuoto", (tester) async
      {
        await apriPagina(tester, pagina);
        await apriDialog(tester);

        await tester.tap(bottoneDelDialog("Esci"));
        await tester.pumpAndSettle();

        expect(repo.chiamateLogout, 1);
        expect(find.byType(LoginPage), findsOneWidget);
        expect(find.byType(pagina.runtimeType), findsNothing);
        expect(find.byType(Dialog), findsNothing);
        expect(find.text("apri"), findsNothing);

        final NavigatorState navigator = tester.state(find.byType(Navigator).first);
        expect(navigator.canPop(), false);
        expect(tester.takeException(), isNull);
      });
    });
  });

  testWidgets("durante il logout Annulla e Esci sono spenti e c'e lo spinner", (tester) async
  {
    repo.attesaLogout = Completer<void>();
    await apriPagina(tester, const HomeAdminPage());
    await apriDialog(tester);

    await tester.tap(bottoneDelDialog("Esci"));
    await tester.pump();

    expect(tester.widget<ElevatedButton>(bottoneDelDialog("Annulla")).onPressed, isNull);
    expect(find.descendant(of: find.byType(Dialog), matching: find.byType(CircularProgressIndicator)), findsOneWidget);

    repo.attesaLogout!.complete();
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
  });

  testWidgets("se il logout fallisce il messaggio sta nel dialog e si puo riprovare", (tester) async
  {
    repo.erroreLogout = Exception("preferenze non scrivibili");
    await apriPagina(tester, const HomeAdminPage());
    await apriDialog(tester);

    await tester.tap(bottoneDelDialog("Esci"));
    await tester.pumpAndSettle();

    expect(find.descendant(of: find.byType(Dialog), matching: find.text(ErroreGenericoServer().messaggio)), findsOneWidget);
    expect(find.byType(LoginPage), findsNothing);

    repo.erroreLogout = null;
    await tester.tap(bottoneDelDialog("Esci"));
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
    expect(repo.chiamateLogout, 2);
  });
}
