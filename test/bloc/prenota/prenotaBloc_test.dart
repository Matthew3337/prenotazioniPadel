import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thepadel/bloc/prenota/prenotaBloc.dart';
import 'package:thepadel/bloc/prenota/prenotaEvent.dart';
import 'package:thepadel/bloc/prenota/prenotaState.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/domainLayer/enetity/slotOrario.dart';
import 'package:thepadel/useCase/homeUseCase.dart';
import 'package:thepadel/useCase/prenotaUseCase.dart';
import 'package:thepadel/useCase/miePartiteUseCase.dart';

import '../../fake/fakeCampoRepo.dart';
import '../../fake/fakePartitaRepo.dart';

DateTime giornoDaOggi(int giorni)
{
  final oggi = DateTime.now();
  return DateTime(oggi.year, oggi.month, oggi.day + giorni);
}

void main()
{
  late FakeCampoRepo repoCampo;
  late FakePartitaRepo repoPartita;
  late PrenotaBloc bloc;

  setUp(()
  {
    repoCampo = FakeCampoRepo();
    repoPartita = FakePartitaRepo();
    repoPartita.partiteMie = [];
    bloc = PrenotaBloc(
      listaCampiUseCase: ListaCampiUseCase(repo: repoCampo),
      slotUseCase: SlotDisponibiliUseCase(repo: repoCampo),
      miePartiteUseCase: MiePartiteUseCase(repo: repoPartita),
    );
  });

  tearDown(() async
  {
    await bloc.close();
  });

  test("lo stato iniziale e su oggi, con 16 giorni (oggi + 15) a mezzanotte e consecutivi", ()
  {
    expect(bloc.state, isA<PrenotaInitial>());
    expect(bloc.state.giorno, giornoDaOggi(0));
    expect(bloc.state.giorni, [for(int i = 0; i <= 15; i++) giornoDaOggi(i)]);
  });

  group("caricamento", ()
  {
    test("Loading poi Caricato con campi e slot del giorno selezionato", () async
    {
      bloc.add(const PrenotaRichiesta());

      await expectLater(bloc.stream, emitsInOrder([
        isA<PrenotaLoading>().having((s) => s.giorno, "giorno", giornoDaOggi(0)),
        isA<PrenotaCaricato>()
          .having((s) => s.giorno, "giorno", giornoDaOggi(0))
          .having((s) => s.campi.length, "campi", 1)
          .having((s) => s.slotPerCampo[3]!.length, "slot", 1)
          .having((s) => s.partiteUtente, "partite utente", isEmpty),
      ]));
      expect(repoCampo.dateRicevute, [giornoDaOggi(0)]);
    });

    test("gli slot sono divisi per campo, anche quando un campo non ne ha", () async
    {
      repoCampo.campi = [campoDiTest(id: 1, nome: "Uno"), campoDiTest(id: 2, nome: "Due"), campoDiTest(id: 3, nome: "Tre")];
      repoCampo.slots = [
        slotCampoDiTest(idCampo: 1, nomeCampo: "Uno", oraInizio: "18:00:00"),
        slotCampoDiTest(idCampo: 2, nomeCampo: "Due", oraInizio: "19:00:00"),
        slotCampoDiTest(idCampo: 1, nomeCampo: "Uno", oraInizio: "20:00:00"),
      ];
      bloc.add(const PrenotaRichiesta());

      await bloc.stream.firstWhere((s) => s is PrenotaCaricato);

      final stato = bloc.state as PrenotaCaricato;
      expect(stato.slotPerCampo[1]!.map((s) => s.oraInizio).toList(), ["18:00:00", "20:00:00"]);
      expect(stato.slotPerCampo[2]!.map((s) => s.oraInizio).toList(), ["19:00:00"]);
      expect(stato.slotPerCampo[3], isEmpty);
    });

    test("uno slot dopo mezzanotte va in fondo e non in cima", () async
    {
      repoCampo.slots = [
        slotCampoDiTest(oraInizio: "00:30:00"),
        slotCampoDiTest(oraInizio: "09:00:00"),
        slotCampoDiTest(oraInizio: "22:30:00"),
      ];
      bloc.add(const PrenotaRichiesta());

      await bloc.stream.firstWhere((s) => s is PrenotaCaricato);

      final stato = bloc.state as PrenotaCaricato;
      expect(stato.slotPerCampo[3]!.map((s) => s.oraInizio).toList(), ["09:00:00", "22:30:00", "00:30:00"]);
    });

    test("delle partite dell'utente restano solo quelle del giorno selezionato", () async
    {
      repoPartita.partiteMie = [
        partitaStoricoDiTest(id: 1, dataPartita: giornoDaOggi(0)),
        partitaStoricoDiTest(id: 2, dataPartita: giornoDaOggi(1)),
      ];
      bloc.add(const PrenotaRichiesta());

      await bloc.stream.firstWhere((s) => s is PrenotaCaricato);

      final stato = bloc.state as PrenotaCaricato;
      expect(stato.partiteUtente.map((p) => p.id).toList(), [1]);
    });

    test("se le mie partite non arrivano il tabellone si mostra lo stesso, senza partite dell'utente", () async
    {
      repoPartita.erroreMie = ErroreGenericoServer();
      bloc.add(const PrenotaRichiesta());

      await expectLater(bloc.stream, emitsInOrder([
        isA<PrenotaLoading>(),
        isA<PrenotaCaricato>().having((s) => s.partiteUtente, "partite utente", isEmpty),
      ]));
    });

    test("errore sui campi: Loading poi Errore, con il giorno e i giorni ancora presenti", () async
    {
      repoCampo.erroreCampi = ErroreGenericoServer();
      bloc.add(const PrenotaRichiesta());

      await expectLater(bloc.stream, emitsInOrder([
        isA<PrenotaLoading>(),
        isA<PrenotaErrore>()
          .having((s) => s.messaggio, "messaggio", ErroreGenericoServer().messaggio)
          .having((s) => s.giorno, "giorno", giornoDaOggi(0))
          .having((s) => s.giorni.length, "giorni", 16),
      ]));
    });

    test("errore sugli slot: Loading poi Errore", () async
    {
      repoCampo.erroreSlot = ErroreGenericoServer();
      bloc.add(const PrenotaRichiesta());

      await expectLater(bloc.stream, emitsInOrder([isA<PrenotaLoading>(), isA<PrenotaErrore>()]));
    });

    test("timeout o rete assente: Errore col messaggio generico", () async
    {
      repoCampo.erroreSlot = Exception("timeout");
      bloc.add(const PrenotaRichiesta());

      await expectLater(bloc.stream, emitsInOrder([
        isA<PrenotaLoading>(),
        isA<PrenotaErrore>().having((s) => s.messaggio, "messaggio", ErroreGenericoServer().messaggio),
      ]));
    });

    test("Riprova dopo un errore ricarica lo stesso giorno", () async
    {
      repoCampo.erroreSlot = ErroreGenericoServer();
      bloc.add(PrenotaGiornoCambiato(giorno: giornoDaOggi(2)));
      await bloc.stream.firstWhere((s) => s is PrenotaErrore);

      repoCampo.erroreSlot = null;
      bloc.add(const PrenotaRichiesta());

      await expectLater(bloc.stream, emitsInOrder([
        isA<PrenotaLoading>().having((s) => s.giorno, "giorno", giornoDaOggi(2)),
        isA<PrenotaCaricato>().having((s) => s.giorno, "giorno", giornoDaOggi(2)),
      ]));
    });
  });

  group("cambio di giorno", ()
  {
    test("carica il giorno scelto", () async
    {
      bloc.add(PrenotaGiornoCambiato(giorno: giornoDaOggi(3)));

      await expectLater(bloc.stream, emitsInOrder([
        isA<PrenotaLoading>().having((s) => s.giorno, "giorno", giornoDaOggi(3)),
        isA<PrenotaCaricato>().having((s) => s.giorno, "giorno", giornoDaOggi(3)),
      ]));
      expect(repoCampo.dateRicevute, [giornoDaOggi(3)]);
    });

    test("un giorno con l'ora viene portato a mezzanotte", () async
    {
      final conOra = giornoDaOggi(1).add(const Duration(hours: 15));
      bloc.add(PrenotaGiornoCambiato(giorno: conOra));

      await expectLater(bloc.stream, emits(isA<PrenotaLoading>().having((s) => s.giorno, "giorno", giornoDaOggi(1))));
    });

    test("un giorno fuori dai 16 selezionabili torna a oggi", () async
    {
      bloc.add(PrenotaGiornoCambiato(giorno: giornoDaOggi(-1)));

      await expectLater(bloc.stream, emits(isA<PrenotaLoading>().having((s) => s.giorno, "giorno", giornoDaOggi(0))));
    });

    test("oggi + 15 e l'ultimo giorno selezionabile, oggi + 16 torna a oggi", () async
    {
      bloc.add(PrenotaGiornoCambiato(giorno: giornoDaOggi(15)));
      await expectLater(bloc.stream, emitsInOrder([
        isA<PrenotaLoading>().having((s) => s.giorno, "giorno", giornoDaOggi(15)),
        isA<PrenotaCaricato>().having((s) => s.giorno, "giorno", giornoDaOggi(15)),
      ]));

      bloc.add(PrenotaGiornoCambiato(giorno: giornoDaOggi(16)));
      await expectLater(bloc.stream, emits(isA<PrenotaLoading>().having((s) => s.giorno, "giorno", giornoDaOggi(0))));
    });

    test("le partite dell'utente arrivano da /mie e non dallo storico", () async
    {
      bloc.add(const PrenotaRichiesta());
      await bloc.stream.firstWhere((s) => s is PrenotaCaricato);

      expect(repoPartita.chiamateMie, 1);
      expect(repoPartita.chiamateStorico, 0);
    });

    test("la risposta di un giorno non piu selezionato viene ignorata", () async
    {
      final attesaPrimo = Completer<List<SlotOrario>>();
      repoCampo.attesePerData[giornoDaOggi(1)] = attesaPrimo;

      final stati = <PrenotaState>[];
      final ascolto = bloc.stream.listen(stati.add);

      bloc.add(PrenotaGiornoCambiato(giorno: giornoDaOggi(1)));
      await Future<void>.delayed(Duration.zero);
      bloc.add(PrenotaGiornoCambiato(giorno: giornoDaOggi(2)));
      await bloc.stream.firstWhere((s) => s is PrenotaCaricato);

      //il primo giorno risponde quando l'utente e gia sul secondo
      attesaPrimo.complete([slotCampoDiTest()]);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await ascolto.cancel();

      expect(bloc.state.giorno, giornoDaOggi(2));
      expect(stati.whereType<PrenotaCaricato>().map((s) => s.giorno).toList(), [giornoDaOggi(2)]);
    });

    test("l'errore di un giorno non piu selezionato viene ignorato", () async
    {
      final attesaPrimo = Completer<List<SlotOrario>>();
      repoCampo.attesePerData[giornoDaOggi(1)] = attesaPrimo;

      bloc.add(PrenotaGiornoCambiato(giorno: giornoDaOggi(1)));
      await Future<void>.delayed(Duration.zero);
      bloc.add(PrenotaGiornoCambiato(giorno: giornoDaOggi(2)));
      await bloc.stream.firstWhere((s) => s is PrenotaCaricato);

      attesaPrimo.completeError(ErroreGenericoServer());
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(bloc.state, isA<PrenotaCaricato>());
      expect(bloc.state.giorno, giornoDaOggi(2));
    });
  });

  group("PrenotaCaricato", ()
  {
    final giorno = DateTime(2026, 11, 5);

    PrenotaCaricato stato({int idCampo = 3, TimeOfDay oraInizio = const TimeOfDay(hour: 18, minute: 30)})
    {
      return PrenotaCaricato(
        giorno: giorno,
        giorni: [giorno],
        campi: [campoDiTest()],
        slotPerCampo: const {},
        partiteUtente: [partitaStoricoDiTest(id: 77, idCampo: idCampo, oraInizio: oraInizio, dataPartita: giorno)],
      );
    }

    test("partitaUtenteDelloSlot trova la partita con lo stesso campo e la stessa ora", ()
    {
      expect(stato().partitaUtenteDelloSlot(slotCampoDiTest())!.id, 77);
    });

    test("partitaUtenteDelloSlot e null su un altro campo o un'altra ora", ()
    {
      expect(stato(idCampo: 1).partitaUtenteDelloSlot(slotCampoDiTest()), isNull);
      expect(stato(oraInizio: const TimeOfDay(hour: 18, minute: 0)).partitaUtenteDelloSlot(slotCampoDiTest()), isNull);
    });

    test("slotPassato confronta l'inizio dello slot con adesso", ()
    {
      final slot = slotCampoDiTest();

      expect(stato().slotPassato(slot, DateTime(2026, 11, 5, 18, 31)), true);
      expect(stato().slotPassato(slot, DateTime(2026, 11, 5, 18, 30)), false);
      expect(stato().slotPassato(slot, DateTime(2026, 11, 5, 18, 0)), false);
    });

    test("uno slot dopo mezzanotte non e passato la sera prima", ()
    {
      final slot = slotCampoDiTest(oraInizio: "00:30:00");

      expect(stato().slotPassato(slot, DateTime(2026, 11, 5, 23, 0)), false);
      expect(stato().slotPassato(slot, DateTime(2026, 11, 6, 1, 0)), true);
    });

    test("uno slot di un campo sconosciuto non e passato", ()
    {
      expect(stato().slotPassato(slotCampoDiTest(idCampo: 99), DateTime(2030)), false);
    });
  });
}
