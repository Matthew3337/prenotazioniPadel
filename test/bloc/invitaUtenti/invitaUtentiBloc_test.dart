import 'package:flutter_test/flutter_test.dart';
import 'package:thepadel/bloc/invitaUtenti/invitaUtentiBloc.dart';
import 'package:thepadel/bloc/invitaUtenti/invitaUtentiEvent.dart';
import 'package:thepadel/bloc/invitaUtenti/invitaUtentiState.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/useCase/dettaglioPartitaUseCase.dart';
import 'package:thepadel/useCase/invitaUtentiUseCase.dart';

import '../../fake/fakePartitaRepo.dart';

List<String> telefoni(List<dynamic> utenti)
{
  return utenti.map((u) => u.telefono as String).toList();
}

TypeMatcher<InvitabiliCaricati> caricatiCon(List<String> telefoniAttesi, int postiLiberi)
{
  return isA<InvitabiliCaricati>()
      .having((s) => telefoni(s.utenti), "telefoni", telefoniAttesi)
      .having((s) => s.postiLiberi, "postiLiberi", postiLiberi);
}

void main()
{
  late FakePartitaRepo repo;
  late InvitaUtentiBloc bloc;

  //i due utenti di default del fake
  const luca = "3335550001";
  const anna = "3335550002";

  setUp(()
  {
    repo = FakePartitaRepo();
    bloc = InvitaUtentiBloc(
      invitabiliUseCase: InvitabiliUseCase(repo: repo),
      invitaUtenteUseCase: InvitaUtenteUseCase(repo: repo),
      dettaglioPartitaUseCase: DettaglioPartitaUseCase(repo: repo),
    );
  });

  tearDown(() async
  {
    await bloc.close();
  });

  //primo caricamento con cerca vuoto, come fa la pagina
  Future<void> carica() async
  {
    bloc.add(const InvitabiliRichiesti(idPartita: 10, cerca: ""));
    await expectLater(bloc.stream, emitsInOrder([isA<InvitaUtentiLoading>(), isA<InvitabiliCaricati>()]));
  }

  test("lo stato iniziale e InvitaUtentiInitial", ()
  {
    expect(bloc.state, isA<InvitaUtentiInitial>());
  });

  group("caricamento", ()
  {
    test("Loading poi Caricati con gli utenti e i posti liberi presi dal dettaglio", () async
    {
      bloc.add(const InvitabiliRichiesti(idPartita: 10, cerca: ""));

      await expectLater(bloc.stream, emitsInOrder([
        isA<InvitaUtentiLoading>(),
        caricatiCon([luca, anna], 2).having((s) => s.alCompleto, "alCompleto", false),
      ]));
      expect(repo.idRicevuto, 10);
      expect(repo.idInvitabiliRicevuto, 10);
      expect(repo.cercaRicevuti, [""]);
      expect(repo.chiamate, 1);
    });

    test("con un solo posto libero postiLiberi e 1", () async
    {
      repo.risposta = dettaglioConInvitati(2);
      bloc.add(const InvitabiliRichiesti(idPartita: 10, cerca: ""));

      await expectLater(bloc.stream, emitsInOrder([isA<InvitaUtentiLoading>(), caricatiCon([luca, anna], 1)]));
    });

    test("partita gia al completo: Caricati con alCompleto true", () async
    {
      repo.risposta = dettaglioConInvitati(3);
      bloc.add(const InvitabiliRichiesti(idPartita: 10, cerca: ""));

      await expectLater(bloc.stream, emitsInOrder([
        isA<InvitaUtentiLoading>(),
        caricatiCon([luca, anna], 0).having((s) => s.alCompleto, "alCompleto", true),
      ]));
    });

    test("nessun utente invitabile: Caricati con lista vuota", () async
    {
      repo.invitabili = [];
      bloc.add(const InvitabiliRichiesti(idPartita: 10, cerca: ""));

      await expectLater(bloc.stream, emitsInOrder([isA<InvitaUtentiLoading>(), caricatiCon([], 2)]));
    });

    test("ricerca: il testo arriva al repository e la lista e quella filtrata", () async
    {
      await carica();

      repo.invitabili = [utenteInvitabileDiTest(telefono: anna, nome: "Anna", cognome: "Verdi")];
      bloc.add(const InvitabiliRichiesti(idPartita: 10, cerca: "ann"));

      await expectLater(bloc.stream, emitsInOrder([isA<InvitaUtentiLoading>(), caricatiCon([anna], 2)]));
      expect(repo.cercaRicevuti, ["", "ann"]);
      expect(bloc.cerca, "ann");
    });

    test("404 sul dettaglio: Loading poi Errore col messaggio", () async
    {
      repo.errore = PartitaNonTrovata(messaggio: "Partita non trovata");
      bloc.add(const InvitabiliRichiesti(idPartita: 10, cerca: ""));

      await expectLater(bloc.stream, emitsInOrder([
        isA<InvitaUtentiLoading>(),
        isA<InvitabiliErrore>().having((s) => s.messaggio, "messaggio", "Partita non trovata"),
      ]));
    });

    test("403 sugli invitabili: Loading poi Errore col messaggio", () async
    {
      repo.erroreInvitabili = OperazioneRifiutata(messaggio: "Solo il creatore può invitare");
      bloc.add(const InvitabiliRichiesti(idPartita: 10, cerca: ""));

      await expectLater(bloc.stream, emitsInOrder([
        isA<InvitaUtentiLoading>(),
        isA<InvitabiliErrore>().having((s) => s.messaggio, "messaggio", "Solo il creatore può invitare"),
      ]));
    });

    test("errore generico: Loading poi Errore col messaggio di ErroreGenericoServer", () async
    {
      repo.erroreInvitabili = ErroreGenericoServer();
      bloc.add(const InvitabiliRichiesti(idPartita: 10, cerca: ""));

      await expectLater(bloc.stream, emitsInOrder([
        isA<InvitaUtentiLoading>(),
        isA<InvitabiliErrore>().having((s) => s.messaggio, "messaggio", ErroreGenericoServer().messaggio),
      ]));
    });
  });

  group("invito", ()
  {
    test("riuscito: InCorso con la lista intera, poi Riuscito senza l'invitato e coi posti aggiornati", () async
    {
      await carica();
      repo.rispostaInvita = dettaglioConInvitati(2);

      bloc.add(const InvitoRichiesto(idPartita: 10, telefono: luca));

      await expectLater(bloc.stream, emitsInOrder([
        isA<InvitoInCorso>()
            .having((s) => telefoni(s.utenti), "telefoni", [luca, anna])
            .having((s) => s.telefono, "telefono", luca),
        isA<InvitoRiuscito>()
            .having((s) => telefoni(s.utenti), "telefoni", [anna])
            .having((s) => s.postiLiberi, "postiLiberi", 1)
            .having((s) => s.alCompleto, "alCompleto", false),
      ]));
      expect(repo.chiamateInvita, 1);
      expect(repo.idInvitaRicevuto, 10);
      expect(repo.telefonoInvitaRicevuto, luca);
      //dopo un invito riuscito la lista non viene richiesta di nuovo al server
      expect(repo.chiamateInvitabili, 1);
    });

    test("due inviti di fila: il secondo parte dalla lista gia senza il primo invitato", () async
    {
      await carica();
      repo.rispostaInvita = dettaglioConInvitati(1);
      bloc.add(const InvitoRichiesto(idPartita: 10, telefono: luca));
      await expectLater(bloc.stream, emitsInOrder([isA<InvitoInCorso>(), isA<InvitoRiuscito>()]));

      repo.rispostaInvita = dettaglioConInvitati(2);
      bloc.add(const InvitoRichiesto(idPartita: 10, telefono: anna));

      await expectLater(bloc.stream, emitsInOrder([
        isA<InvitoInCorso>().having((s) => telefoni(s.utenti), "telefoni", [anna]),
        isA<InvitoRiuscito>()
            .having((s) => telefoni(s.utenti), "telefoni", [])
            .having((s) => s.postiLiberi, "postiLiberi", 1),
      ]));
    });

    test("l'invito che occupa l'ultimo posto: Riuscito con alCompleto true", () async
    {
      repo.risposta = dettaglioConInvitati(2);
      await carica();
      repo.rispostaInvita = dettaglioConInvitati(3);

      bloc.add(const InvitoRichiesto(idPartita: 10, telefono: anna));

      await expectLater(bloc.stream, emitsInOrder([
        isA<InvitoInCorso>(),
        isA<InvitoRiuscito>()
            .having((s) => telefoni(s.utenti), "telefoni", [luca])
            .having((s) => s.postiLiberi, "postiLiberi", 0)
            .having((s) => s.alCompleto, "alCompleto", true),
      ]));
    });

    test("409: InCorso, Errore col messaggio e la lista, poi ricarica senza passare da Loading", () async
    {
      await carica();
      repo.erroreInvita = OperazioneRifiutata(messaggio: "La partita è al completo");
      //intanto un altro giocatore ha preso l'ultimo posto
      repo.risposta = dettaglioConInvitati(3);

      bloc.add(const InvitoRichiesto(idPartita: 10, telefono: luca));

      await expectLater(bloc.stream, emitsInOrder([
        isA<InvitoInCorso>(),
        isA<InvitoErrore>()
            .having((s) => s.messaggio, "messaggio", "La partita è al completo")
            .having((s) => telefoni(s.utenti), "telefoni", [luca, anna]),
        caricatiCon([luca, anna], 0).having((s) => s.alCompleto, "alCompleto", true),
      ]));
      expect(repo.chiamateInvitabili, 2);
      expect(repo.chiamate, 2);
    });

    test("la ricarica dopo l'errore usa l'ultima ricerca fatta", () async
    {
      bloc.add(const InvitabiliRichiesti(idPartita: 10, cerca: "bia"));
      await expectLater(bloc.stream, emitsInOrder([isA<InvitaUtentiLoading>(), isA<InvitabiliCaricati>()]));
      repo.erroreInvita = OperazioneRifiutata(messaggio: "L'utente partecipa già a questa partita");

      bloc.add(const InvitoRichiesto(idPartita: 10, telefono: luca));

      await expectLater(bloc.stream, emitsInOrder([isA<InvitoInCorso>(), isA<InvitoErrore>(), isA<InvitabiliCaricati>()]));
      expect(repo.cercaRicevuti, ["bia", "bia"]);
    });

    test("404 Utente non trovato: Errore col messaggio poi ricarica", () async
    {
      await carica();
      repo.erroreInvita = PartitaNonTrovata(messaggio: "Utente non trovato");

      bloc.add(const InvitoRichiesto(idPartita: 10, telefono: luca));

      await expectLater(bloc.stream, emitsInOrder([
        isA<InvitoInCorso>(),
        isA<InvitoErrore>().having((s) => s.messaggio, "messaggio", "Utente non trovato"),
        caricatiCon([luca, anna], 2),
      ]));
    });

    test("errore generico: Errore col messaggio di ErroreGenericoServer poi ricarica", () async
    {
      await carica();
      repo.erroreInvita = ErroreGenericoServer();

      bloc.add(const InvitoRichiesto(idPartita: 10, telefono: luca));

      await expectLater(bloc.stream, emitsInOrder([
        isA<InvitoInCorso>(),
        isA<InvitoErrore>().having((s) => s.messaggio, "messaggio", ErroreGenericoServer().messaggio),
        isA<InvitabiliCaricati>(),
      ]));
    });

    test("errore e ricarica fallita: dopo l'Errore dell'invito arriva InvitabiliErrore", () async
    {
      await carica();
      repo.erroreInvita = OperazioneRifiutata(messaggio: "La partita non è più aperta");
      repo.errore = PartitaNonTrovata(messaggio: "Partita non trovata");

      bloc.add(const InvitoRichiesto(idPartita: 10, telefono: luca));

      await expectLater(bloc.stream, emitsInOrder([
        isA<InvitoInCorso>(),
        isA<InvitoErrore>(),
        isA<InvitabiliErrore>().having((s) => s.messaggio, "messaggio", "Partita non trovata"),
      ]));
    });
  });

  group("timeout o rete assente", ()
  {
    test("al caricamento: InvitabiliErrore col messaggio generico", () async
    {
      repo.erroreInvitabili = Exception("timeout");
      bloc.add(const InvitabiliRichiesti(idPartita: 10, cerca: ""));

      await expectLater(bloc.stream, emitsInOrder([
        isA<InvitaUtentiLoading>(),
        isA<InvitabiliErrore>().having((s) => s.messaggio, "messaggio", ErroreGenericoServer().messaggio),
      ]));
    });

    test("sull'invito: InvitoErrore col messaggio generico, poi la lista ricaricata", () async
    {
      await carica();
      repo.erroreInvita = Exception("timeout");
      bloc.add(const InvitoRichiesto(idPartita: 10, telefono: luca));

      await expectLater(bloc.stream, emitsInOrder([
        isA<InvitoInCorso>(),
        isA<InvitoErrore>().having((s) => s.messaggio, "messaggio", ErroreGenericoServer().messaggio),
        caricatiCon([luca, anna], 2),
      ]));
    });
  });
}
