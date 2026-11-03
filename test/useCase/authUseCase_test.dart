import 'package:flutter_test/flutter_test.dart';
import 'package:thepadel/useCase/authUseCase.dart';
import 'package:thepadel/useCase/eccezioniUseCase.dart';

import '../fake/fakeUtenteRepo.dart';

void main()
{
  late FakeUtenteRepo repo;

  setUp(()
  {
    repo = FakeUtenteRepo();
  });

  group("LoginUseCase", ()
  {
    test("dati validi: chiama il repository", () async
    {
      final utente = await LoginUseCase(repo: repo).call("3331234567", "segreta");

      expect(utente.telefono, "3331234567");
      expect(repo.chiamateLogin, 1);
    });

    test("telefono troppo corto: FormatoTelefonoNonValido senza chiamare il repository", ()
    {
      expect(() => LoginUseCase(repo: repo).call("333123456", "segreta"), throwsA(isA<FormatoTelefonoNonValido>()));
      expect(repo.chiamateLogin, 0);
    });

    test("password vuota: PwMancante senza chiamare il repository", ()
    {
      expect(() => LoginUseCase(repo: repo).call("3331234567", ""), throwsA(isA<PwMancante>()));
      expect(repo.chiamateLogin, 0);
    });
  });

  group("RegistrazioneUseCase", ()
  {
    final nascita = DateTime(1990, 1, 1);

    test("dati validi: chiama il repository", () async
    {
      expect(await RegistrazioneUseCase(repo: repo).call("Mario", "Rossi", "3331234567", nascita, "segreta"), 201);
      expect(repo.chiamateRegistrazione, 1);
    });

    for(final nome in ["", "   "])
    {
      test("nome '$nome': NomeMancante", ()
      {
        expect(() => RegistrazioneUseCase(repo: repo).call(nome, "Rossi", "3331234567", nascita, "segreta"), throwsA(isA<NomeMancante>()));
      });

      test("cognome '$nome': CognomeMancante", ()
      {
        expect(() => RegistrazioneUseCase(repo: repo).call("Mario", nome, "3331234567", nascita, "segreta"), throwsA(isA<CognomeMancante>()));
      });
    }

    test("data non inserita: DataNascitaMancante", ()
    {
      expect(() => RegistrazioneUseCase(repo: repo).call("Mario", "Rossi", "3331234567", DateTime(0), "segreta"), throwsA(isA<DataNascitaMancante>()));
    });

    test("telefono troppo corto: FormatoTelefonoNonValido", ()
    {
      expect(() => RegistrazioneUseCase(repo: repo).call("Mario", "Rossi", "333", nascita, "segreta"), throwsA(isA<FormatoTelefonoNonValido>()));
    });

    test("password vuota: PwMancante", ()
    {
      expect(() => RegistrazioneUseCase(repo: repo).call("Mario", "Rossi", "3331234567", nascita, ""), throwsA(isA<PwMancante>()));
    });

    test("con un dato sbagliato il repository non viene chiamato", ()
    {
      expect(() => RegistrazioneUseCase(repo: repo).call("", "Rossi", "3331234567", nascita, "segreta"), throwsA(anything));
      expect(repo.chiamateRegistrazione, 0);
    });
  });
}
