import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thepadel/bloc/gestioneCampi/gestioneCampiBloc.dart';
import 'package:thepadel/bloc/gestioneCampi/gestioneCampiEvent.dart';
import 'package:thepadel/bloc/gestioneCampi/gestioneCampiState.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/useCase/adminUseCase.dart';
import 'package:thepadel/useCase/eccezioniUseCase.dart';
import 'package:thepadel/useCase/prenotaUseCase.dart';

import '../../fake/fakeCampoRepo.dart';

const TimeOfDay apertura = TimeOfDay(hour: 8, minute: 0);
const TimeOfDay chiusura = TimeOfDay(hour: 22, minute: 0);

void main()
{
  late FakeCampoRepo repo;
  late GestioneCampiBloc bloc;

  setUp(()
  {
    repo = FakeCampoRepo();
    repo.campi = [campoDiTest(id: 1, nome: "Uno"), campoDiTest(id: 2, nome: "Due")];
    bloc = GestioneCampiBloc(listaCampiUseCase: ListaCampiUseCase(repo: repo), salvaCampoUseCase: SalvaCampoUseCase(repo: repo), eliminaCampoUseCase: EliminaCampoUseCase(repo: repo));
  });

  tearDown(() async
  {
    await bloc.close();
  });

  Future<void> caricaCampi() async
  {
    bloc.add(const CampiRichiesti());
    await expectLater(bloc.stream, emitsInOrder([isA<GestioneCampiLoading>(), isA<CampiCaricati>()]));
  }

  List<String> nomi(List<dynamic> campi)
  {
    final List<String> risultato = [];
    for(final campo in campi)
    {
      risultato.add(campo.nome as String);
    }
    return risultato;
  }

  group("lettura", ()
  {
    test("ok: Loading poi Caricati", () async
    {
      bloc.add(const CampiRichiesti());

      await expectLater(bloc.stream, emitsInOrder([
        isA<GestioneCampiLoading>(),
        isA<CampiCaricati>().having((s) => s.campi.length, "campi", 2),
      ]));
    });

    test("errore del server e timeout: CampiErrore", () async
    {
      repo.erroreCampi = ErroreGenericoServer();
      bloc.add(const CampiRichiesti());
      await expectLater(bloc.stream, emitsInOrder([isA<GestioneCampiLoading>(), isA<CampiErrore>()]));

      repo.erroreCampi = TimeoutException("timeout");
      bloc.add(const CampiRichiesti());
      await expectLater(bloc.stream, emitsInOrder([
        isA<GestioneCampiLoading>(),
        isA<CampiErrore>().having((s) => s.messaggio, "messaggio", ErroreGenericoServer().messaggio),
      ]));
    });
  });

  group("salvataggio", ()
  {
    test("campo nuovo: finisce in fondo alla lista senza richiederla al server", () async
    {
      await caricaCampi();

      bloc.add(const SalvaCampoRichiesto(id: null, nome: "Tre", alCoperto: true, oraApertura: apertura, oraChiusura: chiusura));

      await expectLater(bloc.stream, emitsInOrder([
        isA<CampoInCorso>().having((s) => s.campi.length, "campi", 2),
        isA<CampoSalvato>().having((s) => nomi(s.campi), "nomi", ["Uno", "Due", "Tre"]).having((s) => s.campo.id, "id", repo.idNuovoCampo),
      ]));
      expect(repo.chiamateCampi, 1);
    });

    test("modifica: sostituisce la riga al suo posto senza richiedere la lista", () async
    {
      await caricaCampi();

      bloc.add(const SalvaCampoRichiesto(id: 1, nome: "Rinominato", alCoperto: false, oraApertura: apertura, oraChiusura: chiusura));

      await expectLater(bloc.stream, emitsInOrder([
        isA<CampoInCorso>(),
        isA<CampoSalvato>().having((s) => nomi(s.campi), "nomi", ["Rinominato", "Due"]),
      ]));
      expect(repo.idModificaRicevuto, 1);
      expect(repo.chiamateCampi, 1);
    });

    test("nome mancante: errore senza chiamare il server e la lista resta", () async
    {
      await caricaCampi();

      bloc.add(const SalvaCampoRichiesto(id: null, nome: " ", alCoperto: true, oraApertura: apertura, oraChiusura: chiusura));

      await expectLater(bloc.stream, emitsInOrder([
        isA<CampoInCorso>(),
        isA<CampoOperazioneErrore>().having((s) => s.messaggio, "messaggio", NomeCampoMancante().message).having((s) => s.campi.length, "campi", 2),
      ]));
      expect(repo.chiamateCrea, 0);
    });
  });

  group("eliminazione", ()
  {
    test("ok: il campo sparisce dalla lista senza richiederla al server", () async
    {
      await caricaCampi();

      bloc.add(const EliminaCampoRichiesto(id: 1));

      await expectLater(bloc.stream, emitsInOrder([
        isA<CampoInCorso>(),
        isA<CampoEliminato>().having((s) => nomi(s.campi), "nomi", ["Due"]),
      ]));
      expect(repo.idEliminaRicevuto, 1);
      expect(repo.chiamateCampi, 1);
    });
  });

  group("errori delle operazioni: la lista resta e non viene ricaricata", ()
  {
    final errori = <String, Exception Function()>{
      "400": () => OperazioneRifiutata(messaggio: "Il nome del campo è obbligatorio"),
      "404": () => PartitaNonTrovata(messaggio: "Campo non trovato"),
      "409": () => OperazioneRifiutata(messaggio: "Il campo ha partite collegate e non può essere eliminato"),
      "generico": () => ErroreGenericoServer(),
      "rete": () => TimeoutException("timeout"),
    };
    final messaggi = <String, String>{
      "400": "Il nome del campo è obbligatorio",
      "404": "Campo non trovato",
      "409": "Il campo ha partite collegate e non può essere eliminato",
      "generico": ErroreGenericoServer().messaggio,
      "rete": ErroreGenericoServer().messaggio,
    };

    errori.forEach((nome, errore)
    {
      test("salvataggio, $nome", () async
      {
        await caricaCampi();
        repo.erroreSalva = errore();

        bloc.add(const SalvaCampoRichiesto(id: 1, nome: "Rinominato", alCoperto: true, oraApertura: apertura, oraChiusura: chiusura));

        await expectLater(bloc.stream, emitsInOrder([
          isA<CampoInCorso>(),
          isA<CampoOperazioneErrore>().having((s) => s.messaggio, "messaggio", messaggi[nome]).having((s) => nomi(s.campi), "nomi", ["Uno", "Due"]),
        ]));
        await Future<void>.delayed(Duration.zero);
        expect(bloc.state, isA<CampoOperazioneErrore>());
        expect(repo.chiamateCampi, 1);
      });

      test("eliminazione, $nome", () async
      {
        await caricaCampi();
        repo.erroreElimina = errore();

        bloc.add(const EliminaCampoRichiesto(id: 1));

        await expectLater(bloc.stream, emitsInOrder([
          isA<CampoInCorso>(),
          isA<CampoOperazioneErrore>().having((s) => s.messaggio, "messaggio", messaggi[nome]).having((s) => nomi(s.campi), "nomi", ["Uno", "Due"]),
        ]));
        await Future<void>.delayed(Duration.zero);
        expect(bloc.state, isA<CampoOperazioneErrore>());
        expect(repo.chiamateCampi, 1);
      });
    });
  });
}
