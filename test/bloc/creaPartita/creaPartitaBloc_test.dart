import 'package:flutter_test/flutter_test.dart';
import 'package:thepadel/bloc/creaPartita/creaPartitaBloc.dart';
import 'package:thepadel/bloc/creaPartita/creaPartitaEvent.dart';
import 'package:thepadel/bloc/creaPartita/creaPartitaState.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/useCase/creaPartitaUseCase.dart';

import '../../fake/fakeCampoRepo.dart';
import '../../fake/fakePrenotazioneRepo.dart';

Matcher erroreCon(String messaggio)
{
  return isA<CreaPartitaErrore>().having((s) => s.messaggio, "messaggio", messaggio);
}

void main()
{
  late FakePrenotazioneRepo repo;
  late FakeCampoRepo repoCampo;
  late CreaPartitaBloc bloc;

  setUp(()
  {
    repo = FakePrenotazioneRepo();
    repoCampo = FakeCampoRepo();
    bloc = CreaPartitaBloc(creaPartitaUseCase: CreaPartitaUseCase(repo: repo), slotLiberiDataUseCase: SlotLiberiDataUseCase(repo: repoCampo));
  });

  tearDown(() async
  {
    await bloc.close();
  });

  test("lo stato iniziale e CreaPartitaInitial", ()
  {
    expect(bloc.state, isA<CreaPartitaInitial>());
  });

  test("successo: Loading poi Success con la prenotazione creata", () async
  {
    bloc.add(CreaPartitaRichiesta(slot: slotDiTest(), data: DateTime(2026, 11, 2), tipo: "PUBBLICA"));

    await expectLater(bloc.stream, emitsInOrder([
      isA<CreaPartitaLoading>(),
      isA<CreaPartitaSuccess>().having((s) => s.prenotazione.id, "id", 10).having((s) => s.prenotazione.tipo, "tipo", "PUBBLICA"),
    ]));
    expect(repo.tipoRicevuto, "PUBBLICA");
  });

  test("tipo non scelto: Loading poi Errore col messaggio di validazione, nessuna chiamata", () async
  {
    bloc.add(CreaPartitaRichiesta(slot: slotDiTest(), data: DateTime(2026, 11, 2), tipo: ""));

    await expectLater(bloc.stream, emitsInOrder([
      isA<CreaPartitaLoading>(),
      erroreCon("Scegli se la partita è pubblica o privata"),
    ]));
    expect(repo.chiamate, 0);
  });

  group("409: slot appena preso", ()
  {
    //un giorno futuro, cosi gli slot non risultano gia iniziati qualunque sia l'ora del test
    final oggi = DateTime.now();
    final domani = DateTime(oggi.year, oggi.month, oggi.day + 1);

    test("Loading poi SlotPreso col messaggio del server, la data e gli altri slot liberi", () async
    {
      repo.errore = SlotNonDisponibile(messaggio: "Lo slot selezionato è già occupato");
      repoCampo.slots = [slotCampoDiTest(oraInizio: "20:00:00"), slotCampoDiTest(oraInizio: "21:30:00", disponibile: false)];
      bloc.add(CreaPartitaRichiesta(slot: slotDiTest(), data: domani, tipo: "PRIVATA"));

      await expectLater(bloc.stream, emitsInOrder([
        isA<CreaPartitaLoading>(),
        isA<CreaPartitaSlotPreso>()
          .having((s) => s.messaggio, "messaggio", "Lo slot selezionato è già occupato")
          .having((s) => s.data, "data", domani)
          .having((s) => s.slotLiberi.map((l) => l.oraInizio).toList(), "slot liberi", ["20:00:00"]),
      ]));
      expect(repoCampo.dateRicevute, [domani]);
    });

    test("lo slot appena rifiutato non viene riproposto, anche se il server lo da per libero", () async
    {
      repo.errore = SlotNonDisponibile(messaggio: "occupato");
      repoCampo.slots = [slotCampoDiTest(oraInizio: "18:30:00"), slotCampoDiTest(oraInizio: "20:00:00")];
      bloc.add(CreaPartitaRichiesta(slot: slotDiTest(), data: domani, tipo: "PRIVATA"));

      await expectLater(bloc.stream, emitsInOrder([
        isA<CreaPartitaLoading>(),
        isA<CreaPartitaSlotPreso>().having((s) => s.slotLiberi.map((l) => l.oraInizio).toList(), "slot liberi", ["20:00:00"]),
      ]));
    });

    test("la stessa ora su un altro campo resta tra le alternative", () async
    {
      repo.errore = SlotNonDisponibile(messaggio: "occupato");
      repoCampo.campi = [campoDiTest(), campoDiTest(id: 4, nome: "Campo Due")];
      repoCampo.slots = [slotCampoDiTest(), slotCampoDiTest(idCampo: 4, nomeCampo: "Campo Due")];
      bloc.add(CreaPartitaRichiesta(slot: slotDiTest(), data: domani, tipo: "PRIVATA"));

      await expectLater(bloc.stream, emitsInOrder([
        isA<CreaPartitaLoading>(),
        isA<CreaPartitaSlotPreso>().having((s) => s.slotLiberi.map((l) => l.nomeCampo).toList(), "slot liberi", ["Campo Due"]),
      ]));
    });

    test("se le alternative non arrivano resta SlotPreso, con la lista vuota", () async
    {
      repo.errore = SlotNonDisponibile(messaggio: "occupato");
      repoCampo.erroreSlot = ErroreGenericoServer();
      bloc.add(CreaPartitaRichiesta(slot: slotDiTest(), data: domani, tipo: "PRIVATA"));

      await expectLater(bloc.stream, emitsInOrder([
        isA<CreaPartitaLoading>(),
        isA<CreaPartitaSlotPreso>().having((s) => s.messaggio, "messaggio", "occupato").having((s) => s.slotLiberi, "slot liberi", isEmpty),
      ]));
    });

    test("nella UI SlotPreso va distinto: e anche un CreaPartitaErrore", ()
    {
      expect(CreaPartitaSlotPreso(messaggio: "occupato", data: domani, slotLiberi: const []), isA<CreaPartitaErrore>());
    });
  });

  test("400: Loading poi Errore col messaggio del server", () async
  {
    repo.errore = PrenotazioneNonValida(messaggio: "Dati non validi");
    bloc.add(CreaPartitaRichiesta(slot: slotDiTest(), data: DateTime(2026, 11, 2), tipo: "PUBBLICA"));

    await expectLater(bloc.stream, emitsInOrder([isA<CreaPartitaLoading>(), erroreCon("Dati non validi")]));
  });

  test("404: Loading poi Errore col messaggio del server", () async
  {
    repo.errore = CampoInesistente(messaggio: "Campo non trovato");
    bloc.add(CreaPartitaRichiesta(slot: slotDiTest(), data: DateTime(2026, 11, 2), tipo: "PUBBLICA"));

    await expectLater(bloc.stream, emitsInOrder([isA<CreaPartitaLoading>(), erroreCon("Campo non trovato")]));
  });

  test("errore generico: Loading poi Errore col messaggio generico", () async
  {
    repo.errore = ErroreGenericoServer();
    bloc.add(CreaPartitaRichiesta(slot: slotDiTest(), data: DateTime(2026, 11, 2), tipo: "PUBBLICA"));

    await expectLater(bloc.stream, emitsInOrder([
      isA<CreaPartitaLoading>(),
      erroreCon("Qualcosa è andato storto. Riprova più tardi."),
    ]));
  });

  test("timeout o rete assente: Loading poi Errore col messaggio generico", () async
  {
    repo.errore = Exception("timeout");
    bloc.add(CreaPartitaRichiesta(slot: slotDiTest(), data: DateTime(2026, 11, 2), tipo: "PUBBLICA"));

    await expectLater(bloc.stream, emitsInOrder([isA<CreaPartitaLoading>(), erroreCon(ErroreGenericoServer().messaggio)]));
  });
}
