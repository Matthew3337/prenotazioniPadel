import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thepadel/bloc/autenticazione/authBloc.dart';
import 'package:thepadel/core/di/depInjection.dart';
import 'package:thepadel/main.dart';
import 'package:thepadel/ui/home.dart';
import 'package:thepadel/ui/login.dart';
import 'package:thepadel/useCase/authUseCase.dart';

import 'fake/blocDiTest.dart';
import 'fake/fakeCampoRepo.dart';
import 'fake/fakePartitaRepo.dart';
import 'fake/fakePrenotazioneRepo.dart';
import 'fake/fakeUtenteRepo.dart';

void main()
{
  Future<void> preparaApp(Map<String, Object> preferenze) async
  {
    await sl.reset();
    SharedPreferences.setMockInitialValues(preferenze);
    sl.registerSingleton<SharedPreferences>(await SharedPreferences.getInstance());

    final repoUtente = FakeUtenteRepo();
    sl.registerFactory<AuthBloc>(() => AuthBloc(loginUseCase: LoginUseCase(repo: repoUtente), registrazioneUseCase: RegistrazioneUseCase(repo: repoUtente)));
    registraBlocDiTest(repoPartita: FakePartitaRepo(), repoCampo: FakeCampoRepo(), repoPrenotazione: FakePrenotazioneRepo(), repoUtente: repoUtente);
  }

  tearDown(() async
  {
    await sl.reset();
  });

  testWidgets("senza login l'app parte dalla pagina di login", (tester) async
  {
    await tester.runAsync(() => preparaApp({}));

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.byType(HomePage), findsNothing);
  });

  testWidgets("con isLogged a false l'app parte dalla pagina di login", (tester) async
  {
    await tester.runAsync(() => preparaApp({"isLogged": false}));

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
  });

  testWidgets("con il login gia fatto l'app parte dalla home", (tester) async
  {
    await tester.runAsync(() => preparaApp({"isLogged": true, "jwt": "token-finto", "telefono": "3331234567"}));

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byType(LoginPage), findsNothing);
  });

  testWidgets("il tema usa i font e i colori dell'app", (tester) async
  {
    await tester.runAsync(() => preparaApp({}));

    await tester.pumpWidget(const MyApp());

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.title, "ThePadel");
    expect(app.theme!.textTheme.bodyMedium!.fontFamily, "SourceSans3");
    expect(app.theme!.scaffoldBackgroundColor, const Color(0xFFF7F8FC));
  });
}
