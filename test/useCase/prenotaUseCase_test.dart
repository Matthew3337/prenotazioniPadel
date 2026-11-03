import 'package:flutter_test/flutter_test.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/useCase/prenotaUseCase.dart';

import '../fake/fakeCampoRepo.dart';

void main()
{
  late FakeCampoRepo repo;
  late ListaCampiUseCase useCase;

  setUp(()
  {
    repo = FakeCampoRepo();
    useCase = ListaCampiUseCase(repo: repo);
  });

  test("restituisce i campi del repository", () async
  {
    repo.campi = [campoDiTest(id: 1, nome: "Campo Uno"), campoDiTest(id: 2, nome: "Campo Due")];

    final campi = await useCase.call();

    expect(campi.map((c) => c.nome).toList(), ["Campo Uno", "Campo Due"]);
    expect(repo.chiamateCampi, 1);
  });

  test("l'errore del repository arriva a chi chiama", ()
  {
    repo.erroreCampi = ErroreGenericoServer();

    expect(useCase.call(), throwsA(isA<ErroreGenericoServer>()));
  });
}
