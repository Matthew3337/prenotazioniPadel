import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:thepadel/bloc/livelloCampo/livelloCampoBloc.dart';
import 'package:thepadel/bloc/livelloCampo/livelloCampoEvent.dart';
import 'package:thepadel/bloc/livelloCampo/livelloCampoState.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/useCase/adminUseCase.dart';
import 'package:thepadel/useCase/eccezioniUseCase.dart';

import '../../fake/fakeAdminRepo.dart';

void main()
{
  late FakeAdminRepo repo;
  late LivelloCampoBloc bloc;

  setUp(()
  {
    repo = FakeAdminRepo();
    bloc = LivelloCampoBloc(livelloCampoUseCase: LivelloCampoUseCase(repo: repo), cambiaLivelloCampoUseCase: CambiaLivelloCampoUseCase(repo: repo));
  });

  tearDown(() async
  {
    await bloc.close();
  });

  Future<void> caricaLivello() async
  {
    bloc.add(const LivelloCampoRichiesto());
    await expectLater(bloc.stream, emitsInOrder([isA<LivelloCampoLoading>(), isA<LivelloCampoCaricato>()]));
  }

  group("lettura", ()
  {
    test("ok: Loading senza livello, poi Caricato", () async
    {
      repo.livelloCampo = 3.0;

      bloc.add(const LivelloCampoRichiesto());

      await expectLater(bloc.stream, emitsInOrder([
        isA<LivelloCampoLoading>().having((s) => s.livello, "livello", isNull),
        isA<LivelloCampoCaricato>().having((s) => s.livello, "livello", 3.0),
      ]));
    });

    test("errore: Errore senza livello col messaggio", () async
    {
      repo.erroreLivelloCampo = OperazioneRifiutata(messaggio: "Non sei admin");

      bloc.add(const LivelloCampoRichiesto());

      await expectLater(bloc.stream, emitsInOrder([
        isA<LivelloCampoLoading>(),
        isA<LivelloCampoErrore>().having((s) => s.livello, "livello", isNull).having((s) => s.messaggio, "messaggio", "Non sei admin"),
      ]));
    });

    test("timeout: Errore col messaggio generico", () async
    {
      repo.erroreLivelloCampo = TimeoutException("timeout");

      bloc.add(const LivelloCampoRichiesto());

      await expectLater(bloc.stream, emitsInOrder([
        isA<LivelloCampoLoading>(),
        isA<LivelloCampoErrore>().having((s) => s.messaggio, "messaggio", ErroreGenericoServer().messaggio),
      ]));
    });
  });

  group("salvataggio", ()
  {
    test("ok: Loading col livello vecchio, poi Caricato col nuovo", () async
    {
      await caricaLivello();

      bloc.add(const CambiaLivelloCampoRichiesto(livello: 3.5));

      await expectLater(bloc.stream, emitsInOrder([
        isA<LivelloCampoLoading>().having((s) => s.livello, "livello", 2.0),
        isA<LivelloCampoCaricato>().having((s) => s.livello, "livello", 3.5),
      ]));
      expect(repo.livelliCampoRicevuti, [3.5]);
      expect(bloc.livello, 3.5);
    });

    final errori = <String, Exception Function()>{
      "400": () => OperazioneRifiutata(messaggio: "Il livello deve essere tra 0 e 5 con passo 0,5"),
      "404": () => PartitaNonTrovata(messaggio: "Non trovato"),
      "generico": () => ErroreGenericoServer(),
      "rete": () => TimeoutException("timeout"),
    };
    final messaggi = <String, String>{
      "400": "Il livello deve essere tra 0 e 5 con passo 0,5",
      "404": "Non trovato",
      "generico": ErroreGenericoServer().messaggio,
      "rete": ErroreGenericoServer().messaggio,
    };

    errori.forEach((nome, errore)
    {
      test("errore $nome: il livello resta quello vecchio", () async
      {
        await caricaLivello();
        repo.erroreSalvaLivelloCampo = errore();

        bloc.add(const CambiaLivelloCampoRichiesto(livello: 3.5));

        await expectLater(bloc.stream, emitsInOrder([
          isA<LivelloCampoLoading>(),
          isA<LivelloCampoErrore>().having((s) => s.livello, "livello", 2.0).having((s) => s.messaggio, "messaggio", messaggi[nome]),
        ]));
        expect(bloc.livello, 2.0);
      });
    });

    test("livello non valido: errore senza chiamare il server", () async
    {
      await caricaLivello();

      bloc.add(const CambiaLivelloCampoRichiesto(livello: 2.3));

      await expectLater(bloc.stream, emitsInOrder([
        isA<LivelloCampoLoading>(),
        isA<LivelloCampoErrore>().having((s) => s.livello, "livello", 2.0).having((s) => s.messaggio, "messaggio", LivelloNonValido().message),
      ]));
      expect(repo.livelliCampoRicevuti, isEmpty);
    });
  });
}
