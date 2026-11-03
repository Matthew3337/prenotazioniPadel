import 'package:flutter_test/flutter_test.dart';
import 'package:thepadel/bloc/autenticazione/authBloc.dart';
import 'package:thepadel/bloc/autenticazione/authState.dart';
import 'package:thepadel/bloc/autenticazione/authevent.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/useCase/authUseCase.dart';
import 'package:thepadel/useCase/eccezioniUseCase.dart';

import '../../fake/fakeUtenteRepo.dart';

Matcher erroreCon(String messaggio, CampoErroreAuth campo)
{
  return isA<AuthErrore>().having((s) => s.messaggio, "messaggio", messaggio).having((s) => s.campo, "campo", campo);
}

void main()
{
  late FakeUtenteRepo repo;
  late AuthBloc bloc;
  final nascita = DateTime(1990, 1, 1);

  setUp(()
  {
    repo = FakeUtenteRepo();
    bloc = AuthBloc(loginUseCase: LoginUseCase(repo: repo), registrazioneUseCase: RegistrazioneUseCase(repo: repo));
  });

  tearDown(() async
  {
    await bloc.close();
  });

  test("lo stato iniziale e AuthInitial", ()
  {
    expect(bloc.state, isA<AuthInitial>());
  });

  group("login", ()
  {
    test("successo: Loading poi LoginSuccess con l'utente", () async
    {
      bloc.add(LoginRichiesto(telefono: "3331234567", password: "segreta"));

      await expectLater(bloc.stream, emitsInOrder([
        isA<AuthLoading>(),
        isA<LoginSuccess>().having((s) => s.utente.telefono, "telefono", "3331234567"),
      ]));
    });

    test("telefono non valido: l'errore si riferisce al campo telefono", () async
    {
      bloc.add(LoginRichiesto(telefono: "333", password: "segreta"));

      await expectLater(bloc.stream, emitsInOrder([isA<AuthLoading>(), erroreCon(FormatoTelefonoNonValido().message, CampoErroreAuth.telefono)]));
    });

    test("password mancante: l'errore si riferisce al campo password", () async
    {
      bloc.add(LoginRichiesto(telefono: "3331234567", password: ""));

      await expectLater(bloc.stream, emitsInOrder([isA<AuthLoading>(), erroreCon(PwMancante().message, CampoErroreAuth.password)]));
    });

    test("credenziali errate: errore generale", () async
    {
      repo.erroreLogin = TelOPasswordErrata();
      bloc.add(LoginRichiesto(telefono: "3331234567", password: "segreta"));

      await expectLater(bloc.stream, emitsInOrder([isA<AuthLoading>(), erroreCon(TelOPasswordErrata().messaggio, CampoErroreAuth.nessuno)]));
    });

    test("errore del server: errore generale", () async
    {
      repo.erroreLogin = ErroreGenericoServer();
      bloc.add(LoginRichiesto(telefono: "3331234567", password: "segreta"));

      await expectLater(bloc.stream, emitsInOrder([isA<AuthLoading>(), erroreCon(ErroreGenericoServer().messaggio, CampoErroreAuth.nessuno)]));
    });

    test("timeout o rete assente: errore generale col messaggio generico", () async
    {
      repo.erroreLogin = Exception("timeout");
      bloc.add(LoginRichiesto(telefono: "3331234567", password: "segreta"));

      await expectLater(bloc.stream, emitsInOrder([isA<AuthLoading>(), erroreCon(ErroreGenericoServer().messaggio, CampoErroreAuth.nessuno)]));
    });
  });

  group("registrazione", ()
  {
    RegistrazioneRichiesta evento({String nome = "Mario", String cognome = "Rossi", String telefono = "3331234567", DateTime? data, String pw = "segreta"})
    {
      return RegistrazioneRichiesta(nome: nome, cognome: cognome, telefono: telefono, dataNascita: data ?? nascita, pw: pw);
    }

    test("successo: Loading poi RegistrazioneSuccess", () async
    {
      bloc.add(evento());

      await expectLater(bloc.stream, emitsInOrder([isA<AuthLoading>(), isA<RegistrazioneSuccess>()]));
    });

    test("nome mancante: errore sul campo nome", () async
    {
      bloc.add(evento(nome: "  "));

      await expectLater(bloc.stream, emitsInOrder([isA<AuthLoading>(), erroreCon(NomeMancante().message, CampoErroreAuth.nome)]));
    });

    test("cognome mancante: errore sul campo cognome", () async
    {
      bloc.add(evento(cognome: ""));

      await expectLater(bloc.stream, emitsInOrder([isA<AuthLoading>(), erroreCon(CognomeMancante().message, CampoErroreAuth.cognome)]));
    });

    test("data mancante: errore sul campo data", () async
    {
      bloc.add(evento(data: DateTime(0)));

      await expectLater(bloc.stream, emitsInOrder([isA<AuthLoading>(), erroreCon(DataNascitaMancante().message, CampoErroreAuth.dataNascita)]));
    });

    test("data rifiutata dal server: errore sul campo data", () async
    {
      repo.erroreRegistrazione = DataNonValida();
      bloc.add(evento());

      await expectLater(bloc.stream, emitsInOrder([isA<AuthLoading>(), erroreCon(DataNonValida().messaggio, CampoErroreAuth.dataNascita)]));
    });

    test("telefono non valido: errore sul campo telefono", () async
    {
      bloc.add(evento(telefono: "333"));

      await expectLater(bloc.stream, emitsInOrder([isA<AuthLoading>(), erroreCon(FormatoTelefonoNonValido().message, CampoErroreAuth.telefono)]));
    });

    test("password mancante: errore sul campo password", () async
    {
      bloc.add(evento(pw: ""));

      await expectLater(bloc.stream, emitsInOrder([isA<AuthLoading>(), erroreCon(PwMancante().message, CampoErroreAuth.password)]));
    });

    test("telefono gia registrato: errore generale", () async
    {
      repo.erroreRegistrazione = TelefonoDuplicatoException();
      bloc.add(evento());

      await expectLater(bloc.stream, emitsInOrder([isA<AuthLoading>(), erroreCon(TelefonoDuplicatoException().messaggio, CampoErroreAuth.nessuno)]));
    });

    test("errore del server: errore generale", () async
    {
      repo.erroreRegistrazione = ErroreGenericoServer();
      bloc.add(evento());

      await expectLater(bloc.stream, emitsInOrder([isA<AuthLoading>(), erroreCon(ErroreGenericoServer().messaggio, CampoErroreAuth.nessuno)]));
    });

    test("timeout o rete assente: errore generale col messaggio generico", () async
    {
      repo.erroreRegistrazione = Exception("timeout");
      bloc.add(evento());

      await expectLater(bloc.stream, emitsInOrder([isA<AuthLoading>(), erroreCon(ErroreGenericoServer().messaggio, CampoErroreAuth.nessuno)]));
    });
  });
}
