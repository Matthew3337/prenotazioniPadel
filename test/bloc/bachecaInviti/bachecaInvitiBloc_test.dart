import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:thepadel/bloc/bachecaInviti/bachecaInvitiBloc.dart';
import 'package:thepadel/bloc/bachecaInviti/bachecaInvitiEvent.dart';
import 'package:thepadel/bloc/bachecaInviti/bachecaInvitiState.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/domainLayer/enetity/dettaglioPartita.dart';
import 'package:thepadel/useCase/bachecaInvitiUseCase.dart';
import 'package:thepadel/useCase/dettaglioPartitaUseCase.dart';

import '../../fake/fakePartitaRepo.dart';

Matcher caricataCon(List<int> idPartite)
{
  return isA<BachecaInvitiCaricata>().having((s) => s.partite.map((p) => p.id).toList(), "id partite", idPartite);
}

void main()
{
  late FakePartitaRepo repo;
  late BachecaInvitiBloc bloc;

  setUp(()
  {
    repo = FakePartitaRepo();
    repo.partiteInviti = [partitaInvitoDiTest(id: 10), partitaInvitoDiTest(id: 11, stato: "confermata")];
    repo.dettagliPerId = {
      10: dettaglioDiTest(id: 10, azioni: azioniDiTest(puoConfermare: true)),
      11: dettaglioDiTest(id: 11, azioni: azioniDiTest(puoConfermare: true)),
    };
    bloc = BachecaInvitiBloc(invitiConStatoUseCase: InvitiConStatoUseCase(repo: repo), confermaPartitaUseCase: ConfermaPartitaUseCase(repo: repo));
  });

  tearDown(() async
  {
    await bloc.close();
  });

  Future<void> carica() async
  {
    bloc.add(const BachecaInvitiRichiesta());
    await expectLater(bloc.stream, emitsInOrder([isA<BachecaInvitiLoading>(), caricataCon([10, 11])]));
  }

  test("lo stato iniziale e BachecaInvitiInitial", ()
  {
    expect(bloc.state, isA<BachecaInvitiInitial>());
  });

  test("caricamento ok: Loading poi Caricata con le partite nell'ordine del repository", () async
  {
    bloc.add(const BachecaInvitiRichiesta());

    await expectLater(bloc.stream, emitsInOrder([
      isA<BachecaInvitiLoading>(),
      caricataCon([10, 11]),
    ]));
    expect(repo.chiamateInviti, 1);
  });

  test("le voci caricate portano lo stato di conferma letto dal dettaglio", () async
  {
    repo.dettagliPerId = {10: dettaglioDiTest(id: 10, azioni: azioniDiTest(puoConfermare: true))};
    repo.dettagliInErrore = {11};
    await carica();

    final stato = bloc.state as BachecaInvitiCaricata;
    expect(stato.voci[0].puoConfermare, true);
    expect(stato.voci[1].puoConfermare, false);
  });

  test("nessun invito: Loading poi Caricata con lista vuota", () async
  {
    repo.partiteInviti = [];
    bloc.add(const BachecaInvitiRichiesta());

    await expectLater(bloc.stream, emitsInOrder([
      isA<BachecaInvitiLoading>(),
      caricataCon([]),
    ]));
  });

  test("errore: Loading poi Errore col messaggio di ErroreGenericoServer", () async
  {
    repo.erroreInviti = ErroreGenericoServer();
    bloc.add(const BachecaInvitiRichiesta());

    await expectLater(bloc.stream, emitsInOrder([
      isA<BachecaInvitiLoading>(),
      isA<BachecaInvitiErrore>().having((s) => s.messaggio, "messaggio", ErroreGenericoServer().messaggio),
    ]));
  });

  test("timeout o rete assente: Loading poi Errore col messaggio generico", () async
  {
    repo.erroreInviti = Exception("timeout");
    bloc.add(const BachecaInvitiRichiesta());

    await expectLater(bloc.stream, emitsInOrder([
      isA<BachecaInvitiLoading>(),
      isA<BachecaInvitiErrore>().having((s) => s.messaggio, "messaggio", ErroreGenericoServer().messaggio),
    ]));
  });

  test("una seconda richiesta dopo l'errore ricarica la bacheca", () async
  {
    repo.erroreInviti = ErroreGenericoServer();
    bloc.add(const BachecaInvitiRichiesta());
    await expectLater(bloc.stream, emitsInOrder([isA<BachecaInvitiLoading>(), isA<BachecaInvitiErrore>()]));

    repo.erroreInviti = null;
    bloc.add(const BachecaInvitiRichiesta());

    await expectLater(bloc.stream, emitsInOrder([
      isA<BachecaInvitiLoading>(),
      caricataCon([10, 11]),
    ]));
    expect(repo.chiamateInviti, 2);
  });

  group("conferma dalla lista", ()
  {
    test("successo: InCorso poi Riuscita, l'invito resta in lista come gia confermato", () async
    {
      await carica();

      bloc.add(const ConfermaInvitoRichiesta(idPartita: 10));

      await expectLater(bloc.stream, emitsInOrder([
        isA<ConfermaInvitoInCorso>().having((s) => s.idPartita, "id", 10).having((s) => s.voci.length, "voci", 2),
        isA<ConfermaInvitoRiuscita>().having((s) => s.dettaglio.id, "dettaglio", 10),
      ]));
      expect(repo.idConfermaRicevuto, 10);

      final stato = bloc.state as ConfermaInvitoRiuscita;
      expect(stato.voci[0].partita.id, 10);
      expect(stato.voci[0].puoConfermare, false);
      expect(stato.voci[0].giaConfermato, true);
      //l'altro invito non cambia
      expect(stato.voci[1].puoConfermare, true);
      expect(stato.voci[1].giaConfermato, false);
    });

    test("errori: InCorso poi ConfermaInvitoErrore col messaggio e la lista invariata", () async
    {
      final errori = <Exception, String>{
        PartitaNonTrovata(messaggio: "Partita non trovata"): "Partita non trovata",
        OperazioneRifiutata(messaggio: "Conferma non possibile"): "Conferma non possibile",
        ErroreGenericoServer(): ErroreGenericoServer().messaggio,
        Exception("timeout"): ErroreGenericoServer().messaggio,
      };
      await carica();

      for(final errore in errori.entries)
      {
        repo.erroreConferma = errore.key;
        bloc.add(const ConfermaInvitoRichiesta(idPartita: 10));

        await expectLater(bloc.stream, emitsInOrder([
          isA<ConfermaInvitoInCorso>(),
          isA<ConfermaInvitoErrore>().having((s) => s.messaggio, "messaggio", errore.value).having((s) => s.voci.length, "voci", 2),
        ]));
        expect((bloc.state as ConfermaInvitoErrore).voci[0].puoConfermare, true);
      }
    });

    test("senza una lista caricata la richiesta viene ignorata", () async
    {
      bloc.add(const ConfermaInvitoRichiesta(idPartita: 10));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(bloc.state, isA<BachecaInvitiInitial>());
      expect(repo.chiamateConferma, 0);
    });

    test("mentre una conferma e in corso le altre vengono ignorate", () async
    {
      repo.attesaConferma = Completer<DettaglioPartita>();
      await carica();

      bloc.add(const ConfermaInvitoRichiesta(idPartita: 10));
      await expectLater(bloc.stream, emits(isA<ConfermaInvitoInCorso>()));

      bloc.add(const ConfermaInvitoRichiesta(idPartita: 11));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(repo.chiamateConferma, 1);
      expect(repo.idConfermaRicevuto, 10);
      expect((bloc.state as ConfermaInvitoInCorso).idPartita, 10);

      repo.attesaConferma!.complete(dettaglioDiTest(id: 10));
      await expectLater(bloc.stream, emits(isA<ConfermaInvitoRiuscita>()));
    });

    test("finita una conferma se ne puo fare un'altra, e le conferme gia fatte restano", () async
    {
      await carica();

      bloc.add(const ConfermaInvitoRichiesta(idPartita: 10));
      await expectLater(bloc.stream, emitsInOrder([isA<ConfermaInvitoInCorso>(), isA<ConfermaInvitoRiuscita>()]));

      bloc.add(const ConfermaInvitoRichiesta(idPartita: 11));
      await expectLater(bloc.stream, emitsInOrder([isA<ConfermaInvitoInCorso>(), isA<ConfermaInvitoRiuscita>()]));

      final stato = bloc.state as ConfermaInvitoRiuscita;
      expect(stato.voci.map((v) => v.giaConfermato).toList(), [true, true]);
    });
  });
}
