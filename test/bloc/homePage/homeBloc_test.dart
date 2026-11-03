import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thepadel/bloc/homePage/homeBloc.dart';
import 'package:thepadel/bloc/homePage/homeEvent.dart';
import 'package:thepadel/bloc/homePage/homeState.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/domainLayer/enetity/dettaglioPartita.dart';
import 'package:thepadel/domainLayer/enetity/distaccoClassifica.dart';
import 'package:thepadel/domainLayer/enetity/prenotazione.dart';
import 'package:thepadel/domainLayer/enetity/slotOrario.dart';
import 'package:thepadel/domainLayer/enetity/voceClassifica.dart';
import 'package:thepadel/useCase/bachecaInvitiUseCase.dart';
import 'package:thepadel/useCase/bachecaPubblicheUseCase.dart';
import 'package:thepadel/useCase/classificaUseCase.dart';
import 'package:thepadel/useCase/dettaglioPartitaUseCase.dart';
import 'package:thepadel/useCase/homeUseCase.dart';

import '../../fake/fakeCampoRepo.dart';
import '../../fake/fakePartitaRepo.dart';
import '../../fake/fakePrenotazioneRepo.dart';
import '../../fake/fakeUtenteRepo.dart';

Matcher classificaLoading()
{
  return isA<HomeState>().having((s) => s.classifica, "classifica", isA<SectionLoading<VoceClassifica>>());
}

Matcher conDistacco(int? punti, int? posizioneSopra)
{
  return isA<HomeState>().having((s) => s.distaccoClassifica, "distacco", isA<SectionSuccess<DistaccoClassifica>>()
    .having((d) => d.data.punti, "punti", punti)
    .having((d) => d.data.posizioneSopra, "posizione sopra", posizioneSopra));
}

void main()
{
  late FakeUtenteRepo repo;
  late FakePrenotazioneRepo repoPrenotazione;
  late FakeCampoRepo repoCampo;
  late FakePartitaRepo repoPartita;
  late HomeBloc bloc;

  setUp(()
  {
    repo = FakeUtenteRepo();
    repoPrenotazione = FakePrenotazioneRepo();
    repoCampo = FakeCampoRepo();
    repoPartita = FakePartitaRepo();
    bloc = HomeBloc(
      prossimaPartitaUseCase: ProssimaPartitaUseCase(repo: repoPrenotazione),
      slotOggiUseCase: SlotOggiUseCase(repo: repoCampo),
      classificaUseCase: ClassificaUseCase(repo: repo),
      dettaglioPartitaUseCase: DettaglioPartitaUseCase(repo: repoPartita),
      bachecaInvitiUseCase: BachecaInvitiUseCase(repo: repoPartita),
      partitePubblicheUseCase: PartitePubblicheUseCase(repo: repoPartita),
    );
  });

  tearDown(() async
  {
    await bloc.close();
  });

  group("classifica", ()
  {
    test("lo stato iniziale ha la classifica in caricamento", ()
    {
      expect(bloc.state.classifica, isA<SectionLoading<VoceClassifica>>());
    });

    test("utente presente: Loading poi Success con la sua riga, anche se non e la prima", () async
    {
      repo.voci = [
        voceDiTest(posizione: 1, telefono: "1", punteggio: 9),
        voceDiTest(posizione: 2, telefono: "2", punteggio: 5, utenteCorrente: true),
        voceDiTest(posizione: 3, telefono: "3", punteggio: 1),
      ];
      bloc.add(const HomeClassificaRequested());

      await expectLater(bloc.stream, emitsInOrder([
        classificaLoading(),
        isA<HomeState>().having((s) => s.classifica, "classifica", isA<SectionSuccess<VoceClassifica>>()
          .having((c) => c.data.telefono, "telefono", "2")
          .having((c) => c.data.posizione, "posizione", 2)
          .having((c) => c.data.punteggio, "punteggio", 5)),
      ]));
    });

    test("utente assente (admin): Loading poi Empty, anche per il distacco", () async
    {
      repo.voci = [voceDiTest(telefono: "1"), voceDiTest(telefono: "2")];
      bloc.add(const HomeClassificaRequested());

      await expectLater(bloc.stream, emitsInOrder([
        classificaLoading(),
        isA<HomeState>()
          .having((s) => s.classifica, "classifica", isA<SectionEmpty<VoceClassifica>>())
          .having((s) => s.distaccoClassifica, "distacco", isA<SectionEmpty<DistaccoClassifica>>()),
      ]));
    });

    test("classifica vuota: Loading poi Empty", () async
    {
      repo.voci = [];
      bloc.add(const HomeClassificaRequested());

      await expectLater(bloc.stream, emitsInOrder([
        classificaLoading(),
        isA<HomeState>().having((s) => s.classifica, "classifica", isA<SectionEmpty<VoceClassifica>>()),
      ]));
    });

    test("errore: Loading poi Error col messaggio di ErroreGenericoServer, anche per il distacco", () async
    {
      repo.errore = ErroreGenericoServer();
      bloc.add(const HomeClassificaRequested());

      await expectLater(bloc.stream, emitsInOrder([
        classificaLoading(),
        isA<HomeState>()
          .having((s) => s.classifica, "classifica", isA<SectionError<VoceClassifica>>().having((c) => c.message, "message", ErroreGenericoServer().messaggio))
          .having((s) => s.distaccoClassifica, "distacco", isA<SectionError<DistaccoClassifica>>()),
      ]));
    });

    test("timeout o rete assente: Loading poi Error col messaggio generico", () async
    {
      repo.errore = Exception("timeout");
      bloc.add(const HomeClassificaRequested());

      await expectLater(bloc.stream, emitsInOrder([
        classificaLoading(),
        isA<HomeState>().having((s) => s.classifica, "classifica", isA<SectionError<VoceClassifica>>().having((c) => c.message, "message", ErroreGenericoServer().messaggio)),
      ]));
    });
  });

  group("distacco in classifica", ()
  {
    test("chi e primo non ha nessuno sopra", () async
    {
      repo.voci = [voceDiTest(posizione: 1, punteggio: 9, utenteCorrente: true), voceDiTest(posizione: 2, telefono: "2", punteggio: 5)];
      bloc.add(const HomeClassificaRequested());

      await expectLater(bloc.stream, emitsInOrder([classificaLoading(), conDistacco(null, null)]));
    });

    test("distacco dalla posizione subito sopra", () async
    {
      repo.voci = [
        voceDiTest(posizione: 1, telefono: "1", punteggio: 30),
        voceDiTest(posizione: 2, telefono: "2", punteggio: 20),
        voceDiTest(posizione: 3, telefono: "3", punteggio: 12, utenteCorrente: true),
      ];
      bloc.add(const HomeClassificaRequested());

      await expectLater(bloc.stream, emitsInOrder([classificaLoading(), conDistacco(8, 2)]));
    });

    test("con i pari merito la posizione sopra non e la mia meno uno: 1, 2, 2, 4", () async
    {
      repo.voci = [
        voceDiTest(posizione: 1, telefono: "1", punteggio: 30),
        voceDiTest(posizione: 2, telefono: "2", punteggio: 20),
        voceDiTest(posizione: 2, telefono: "3", punteggio: 20),
        voceDiTest(posizione: 4, telefono: "4", punteggio: 12, utenteCorrente: true),
      ];
      bloc.add(const HomeClassificaRequested());

      await expectLater(bloc.stream, emitsInOrder([classificaLoading(), conDistacco(8, 2)]));
    });

    test("chi e secondo a pari merito guarda il primo", () async
    {
      repo.voci = [
        voceDiTest(posizione: 1, telefono: "1", punteggio: 30),
        voceDiTest(posizione: 2, telefono: "2", punteggio: 20, utenteCorrente: true),
        voceDiTest(posizione: 2, telefono: "3", punteggio: 20),
      ];
      bloc.add(const HomeClassificaRequested());

      await expectLater(bloc.stream, emitsInOrder([classificaLoading(), conDistacco(10, 1)]));
    });
  });

  group("prossima partita", ()
  {
    test("lo stato iniziale ha prossima partita e dettaglio in caricamento", ()
    {
      expect(bloc.state.prossimaPartita, isA<SectionLoading<Prenotazione>>());
      expect(bloc.state.dettaglioProssimaPartita, isA<SectionLoading<DettaglioPartita>>());
    });

    test("c'e: Loading, Success della prenotazione, poi Success del suo dettaglio", () async
    {
      repoPrenotazione.prossima = prenotazioneDiTest();
      bloc.add(const HomeProssimaPartitaRequested());

      await expectLater(bloc.stream, emitsInOrder([
        isA<HomeState>()
          .having((s) => s.prossimaPartita, "prossima", isA<SectionLoading<Prenotazione>>())
          .having((s) => s.dettaglioProssimaPartita, "dettaglio", isA<SectionLoading<DettaglioPartita>>()),
        isA<HomeState>()
          .having((s) => s.prossimaPartita, "prossima", isA<SectionSuccess<Prenotazione>>())
          .having((s) => s.dettaglioProssimaPartita, "dettaglio", isA<SectionLoading<DettaglioPartita>>()),
        isA<HomeState>().having((s) => s.dettaglioProssimaPartita, "dettaglio", isA<SectionSuccess<DettaglioPartita>>().having((d) => d.data.id, "id", 10)),
      ]));
      expect(repoPartita.idRicevuto, 10);
    });

    test("non c'e: Empty per entrambe, il dettaglio non viene chiesto", () async
    {
      bloc.add(const HomeProssimaPartitaRequested());

      await expectLater(bloc.stream, emitsInOrder([
        isA<HomeState>().having((s) => s.prossimaPartita, "prossima", isA<SectionLoading<Prenotazione>>()),
        isA<HomeState>()
          .having((s) => s.prossimaPartita, "prossima", isA<SectionEmpty<Prenotazione>>())
          .having((s) => s.dettaglioProssimaPartita, "dettaglio", isA<SectionEmpty<DettaglioPartita>>()),
      ]));
      expect(repoPartita.chiamate, 0);
    });

    for(final caso in {"del server": ErroreGenericoServer(), "di rete": Exception("timeout")}.entries)
    {
      test("errore ${caso.key}: Error sulla prossima partita, Empty sul dettaglio", () async
      {
        repoPrenotazione.erroreProssima = caso.value;
        bloc.add(const HomeProssimaPartitaRequested());

        await expectLater(bloc.stream, emitsInOrder([
          isA<HomeState>().having((s) => s.prossimaPartita, "prossima", isA<SectionLoading<Prenotazione>>()),
          isA<HomeState>()
            .having((s) => s.prossimaPartita, "prossima", isA<SectionError<Prenotazione>>().having((e) => e.message, "message", ErroreGenericoServer().messaggio))
            .having((s) => s.dettaglioProssimaPartita, "dettaglio", isA<SectionEmpty<DettaglioPartita>>()),
        ]));
        expect(repoPartita.chiamate, 0);
      });
    }

    final erroriDettaglio = <String, Exception>{
      "partita non trovata": PartitaNonTrovata(messaggio: "Partita non trovata"),
      "errore del server": ErroreGenericoServer(),
      "rete assente": Exception("timeout"),
    };
    for(final caso in erroriDettaglio.entries)
    {
      test("dettaglio che fallisce per ${caso.key}: la prossima partita resta Success", () async
      {
        repoPrenotazione.prossima = prenotazioneDiTest();
        repoPartita.errore = caso.value;
        bloc.add(const HomeProssimaPartitaRequested());

        await expectLater(bloc.stream, emitsInOrder([
          isA<HomeState>().having((s) => s.prossimaPartita, "prossima", isA<SectionLoading<Prenotazione>>()),
          isA<HomeState>().having((s) => s.prossimaPartita, "prossima", isA<SectionSuccess<Prenotazione>>()),
          isA<HomeState>()
            .having((s) => s.prossimaPartita, "prossima", isA<SectionSuccess<Prenotazione>>())
            .having((s) => s.dettaglioProssimaPartita, "dettaglio", isA<SectionError<DettaglioPartita>>()),
        ]));
      });
    }
  });

  group("slot di oggi", ()
  {
    Matcher slotLoading()
    {
      return isA<HomeState>().having((s) => s.slotOggi, "slot", isA<SectionLoading<List<SlotOrario>>>());
    }

    test("con degli slot: Loading poi Success", () async
    {
      //con il campo aperto dalle 23:59 uno slot delle 00:00 e sempre di domani, quindi mai passato
      repoCampo.campi = [campoDiTest(oraApertura: const TimeOfDay(hour: 23, minute: 59))];
      repoCampo.slots = [slotCampoDiTest(oraInizio: "00:00:00")];
      bloc.add(const HomeSlotOggiRequested());

      await expectLater(bloc.stream, emitsInOrder([
        slotLoading(),
        isA<HomeState>().having((s) => s.slotOggi, "slot", isA<SectionSuccess<List<SlotOrario>>>().having((l) => l.data.length, "numero", 1)),
      ]));
    });

    test("senza slot: Loading poi Empty", () async
    {
      repoCampo.slots = [];
      bloc.add(const HomeSlotOggiRequested());

      await expectLater(bloc.stream, emitsInOrder([
        slotLoading(),
        isA<HomeState>().having((s) => s.slotOggi, "slot", isA<SectionEmpty<List<SlotOrario>>>()),
      ]));
    });

    for(final caso in {"del server": ErroreGenericoServer(), "di rete": Exception("timeout")}.entries)
    {
      test("errore ${caso.key}: Loading poi Error col messaggio generico", () async
      {
        repoCampo.erroreSlot = caso.value;
        bloc.add(const HomeSlotOggiRequested());

        await expectLater(bloc.stream, emitsInOrder([
          slotLoading(),
          isA<HomeState>().having((s) => s.slotOggi, "slot", isA<SectionError<List<SlotOrario>>>().having((e) => e.message, "message", ErroreGenericoServer().messaggio)),
        ]));
      });
    }
  });

  group("contatori", ()
  {
    test("inviti: Loading poi Success col numero degli inviti", () async
    {
      repoPartita.partiteInviti = [partitaInvitoDiTest(id: 1), partitaInvitoDiTest(id: 2)];
      bloc.add(const HomeInvitiRequested());

      await expectLater(bloc.stream, emitsInOrder([
        isA<HomeState>().having((s) => s.invitiRicevuti, "inviti", isA<SectionLoading<int>>()),
        isA<HomeState>().having((s) => s.invitiRicevuti, "inviti", isA<SectionSuccess<int>>().having((n) => n.data, "numero", 2)),
      ]));
    });

    test("pubbliche: Loading poi Success col numero delle partite", () async
    {
      repoPartita.partitePubbliche = [partitaPubblicaDiTest(id: 1), partitaPubblicaDiTest(id: 2), partitaPubblicaDiTest(id: 3)];
      bloc.add(const HomePartitePubblicheRequested());

      await expectLater(bloc.stream, emitsInOrder([
        isA<HomeState>().having((s) => s.partitePubblicheAperte, "pubbliche", isA<SectionLoading<int>>()),
        isA<HomeState>().having((s) => s.partitePubblicheAperte, "pubbliche", isA<SectionSuccess<int>>().having((n) => n.data, "numero", 3)),
      ]));
    });

    for(final caso in {"del server": ErroreGenericoServer(), "di rete": Exception("timeout")}.entries)
    {
      test("inviti, errore ${caso.key}: Error col messaggio generico", () async
      {
        repoPartita.erroreInviti = caso.value;
        bloc.add(const HomeInvitiRequested());

        await expectLater(bloc.stream, emitsInOrder([
          isA<HomeState>().having((s) => s.invitiRicevuti, "inviti", isA<SectionLoading<int>>()),
          isA<HomeState>().having((s) => s.invitiRicevuti, "inviti", isA<SectionError<int>>().having((e) => e.message, "message", ErroreGenericoServer().messaggio)),
        ]));
      });

      test("pubbliche, errore ${caso.key}: Error col messaggio generico", () async
      {
        repoPartita.errorePubbliche = caso.value;
        bloc.add(const HomePartitePubblicheRequested());

        await expectLater(bloc.stream, emitsInOrder([
          isA<HomeState>().having((s) => s.partitePubblicheAperte, "pubbliche", isA<SectionLoading<int>>()),
          isA<HomeState>().having((s) => s.partitePubblicheAperte, "pubbliche", isA<SectionError<int>>().having((e) => e.message, "message", ErroreGenericoServer().messaggio)),
        ]));
      });
    }
  });

  test("copyWith sulla classifica non tocca le altre sezioni", ()
  {
    final prima = HomeState.initial();

    final dopo = prima.copyWith(classifica: const SectionEmpty());

    expect(dopo.classifica, isA<SectionEmpty<VoceClassifica>>());
    expect(identical(dopo.prossimaPartita, prima.prossimaPartita), true);
    expect(identical(dopo.slotOggi, prima.slotOggi), true);
    expect(identical(dopo.dettaglioProssimaPartita, prima.dettaglioProssimaPartita), true);
    expect(identical(dopo.invitiRicevuti, prima.invitiRicevuti), true);
    expect(identical(dopo.partitePubblicheAperte, prima.partitePubblicheAperte), true);
    expect(identical(dopo.distaccoClassifica, prima.distaccoClassifica), true);
  });
}
