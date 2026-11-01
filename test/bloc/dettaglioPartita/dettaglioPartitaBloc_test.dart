import 'package:flutter_test/flutter_test.dart';
import 'package:thepadel/bloc/dettaglioPartita/dettaglioPartitaBloc.dart';
import 'package:thepadel/bloc/dettaglioPartita/dettaglioPartitaEvent.dart';
import 'package:thepadel/bloc/dettaglioPartita/dettaglioPartitaState.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/domainLayer/enetity/postoPartita.dart';
import 'package:thepadel/useCase/dettaglioPartitaUseCase.dart';

import '../../fake/fakePartitaRepo.dart';

Matcher erroreCon(String messaggio)
{
  return isA<DettaglioPartitaErrore>().having((s) => s.messaggio, "messaggio", messaggio);
}

Matcher operazioneErroreCon(String messaggio)
{
  return isA<OperazioneErrore>().having((s) => s.messaggio, "messaggio", messaggio).having((s) => s.dettaglio.id, "id", 10);
}

void main()
{
  late FakePartitaRepo repo;
  late DettaglioPartitaBloc bloc;

  setUp(()
  {
    repo = FakePartitaRepo();
    bloc = DettaglioPartitaBloc(dettaglioPartitaUseCase: DettaglioPartitaUseCase(repo: repo), eliminaPartitaUseCase: EliminaPartitaUseCase(repo: repo), esciDaPartitaUseCase: EsciDaPartitaUseCase(repo: repo), confermaPartitaUseCase: ConfermaPartitaUseCase(repo: repo));
  });

  tearDown(() async
  {
    await bloc.close();
  });

  test("lo stato iniziale e DettaglioPartitaInitial", ()
  {
    expect(bloc.state, isA<DettaglioPartitaInitial>());
  });

  test("successo: Loading poi Caricato col dettaglio, l'id arriva al repository", () async
  {
    bloc.add(const DettaglioPartitaRichiesto(idPartita: 10));

    await expectLater(bloc.stream, emitsInOrder([
      isA<DettaglioPartitaLoading>(),
      isA<DettaglioPartitaCaricato>().having((s) => s.dettaglio.id, "id", 10).having((s) => s.dettaglio.posti.length, "posti", 2),
    ]));
    expect(repo.chiamate, 1);
    expect(repo.idRicevuto, 10);
  });

  test("404: Loading poi Errore col messaggio di PartitaNonTrovata", () async
  {
    repo.errore = PartitaNonTrovata(messaggio: "Partita non trovata");
    bloc.add(const DettaglioPartitaRichiesto(idPartita: 99));

    await expectLater(bloc.stream, emitsInOrder([
      isA<DettaglioPartitaLoading>(),
      erroreCon("Partita non trovata"),
    ]));
  });

  test("errore generico: Loading poi Errore col messaggio di ErroreGenericoServer", () async
  {
    repo.errore = ErroreGenericoServer();
    bloc.add(const DettaglioPartitaRichiesto(idPartita: 10));

    await expectLater(bloc.stream, emitsInOrder([
      isA<DettaglioPartitaLoading>(),
      erroreCon(ErroreGenericoServer().messaggio),
    ]));
  });

  //carica il dettaglio e aspetta che arrivi, come succede quando la pagina e a schermo
  Future<void> caricaDettaglio() async
  {
    bloc.add(const DettaglioPartitaRichiesto(idPartita: 10));
    await expectLater(bloc.stream, emitsInOrder([
      isA<DettaglioPartitaLoading>(),
      isA<DettaglioPartitaCaricato>(),
    ]));
  }

  group("elimina partita", ()
  {
    test("successo: OperazioneInCorso col dettaglio poi PartitaEliminata, senza ricaricare", () async
    {
      await caricaDettaglio();

      bloc.add(const EliminaPartitaRichiesta(idPartita: 10));

      await expectLater(bloc.stream, emitsInOrder([
        isA<OperazioneInCorso>().having((s) => s.dettaglio.id, "id", 10),
        isA<PartitaEliminata>(),
      ]));
      expect(repo.chiamateElimina, 1);
      expect(repo.idEliminaRicevuto, 10);
      expect(repo.chiamateEsci, 0);
      //il dettaglio era stato chiesto solo una volta, al caricamento
      expect(repo.chiamate, 1);
    });

    test("409: OperazioneInCorso, OperazioneErrore col messaggio, poi Caricato senza Loading", () async
    {
      await caricaDettaglio();
      repo.erroreElimina = OperazioneRifiutata(messaggio: "La partita non è più aperta");

      bloc.add(const EliminaPartitaRichiesta(idPartita: 10));

      //emitsInOrder vuole gli stati uno dopo l'altro: un Loading in mezzo farebbe fallire il test
      await expectLater(bloc.stream, emitsInOrder([
        isA<OperazioneInCorso>(),
        operazioneErroreCon("La partita non è più aperta"),
        isA<DettaglioPartitaCaricato>(),
      ]));
      expect(repo.chiamate, 2);
    });

    test("404: OperazioneErrore col messaggio di PartitaNonTrovata, poi ricarica", () async
    {
      await caricaDettaglio();
      repo.erroreElimina = PartitaNonTrovata(messaggio: "Partita non trovata");

      bloc.add(const EliminaPartitaRichiesta(idPartita: 10));

      await expectLater(bloc.stream, emitsInOrder([
        isA<OperazioneInCorso>(),
        operazioneErroreCon("Partita non trovata"),
        isA<DettaglioPartitaCaricato>(),
      ]));
    });

    test("errore generico seguito da una ricarica fallita: si arriva a DettaglioPartitaErrore", () async
    {
      await caricaDettaglio();
      repo.erroreElimina = ErroreGenericoServer();
      //anche la ricarica del dettaglio fallisce
      repo.errore = PartitaNonTrovata(messaggio: "Partita non trovata");

      bloc.add(const EliminaPartitaRichiesta(idPartita: 10));

      await expectLater(bloc.stream, emitsInOrder([
        isA<OperazioneInCorso>(),
        operazioneErroreCon(ErroreGenericoServer().messaggio),
        erroreCon("Partita non trovata"),
      ]));
    });

    test("senza un dettaglio caricato l'evento viene ignorato", () async
    {
      bloc.add(const EliminaPartitaRichiesta(idPartita: 10));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state, isA<DettaglioPartitaInitial>());
      expect(repo.chiamateElimina, 0);
    });
  });

  group("esci dalla partita", ()
  {
    test("successo: OperazioneInCorso col dettaglio poi UscitaCompletata, senza ricaricare", () async
    {
      await caricaDettaglio();

      bloc.add(const EsciDaPartitaRichiesta(idPartita: 10));

      await expectLater(bloc.stream, emitsInOrder([
        isA<OperazioneInCorso>().having((s) => s.dettaglio.id, "id", 10),
        isA<UscitaCompletata>(),
      ]));
      expect(repo.chiamateEsci, 1);
      expect(repo.idEsciRicevuto, 10);
      expect(repo.chiamateElimina, 0);
      expect(repo.chiamate, 1);
    });

    test("409: OperazioneInCorso, OperazioneErrore col messaggio, poi Caricato senza Loading", () async
    {
      await caricaDettaglio();
      repo.erroreEsci = OperazioneRifiutata(messaggio: "L'uscita è chiusa: mancano meno di 24 ore all'inizio");

      bloc.add(const EsciDaPartitaRichiesta(idPartita: 10));

      //emitsInOrder vuole gli stati uno dopo l'altro: un Loading in mezzo farebbe fallire il test
      await expectLater(bloc.stream, emitsInOrder([
        isA<OperazioneInCorso>(),
        operazioneErroreCon("L'uscita è chiusa: mancano meno di 24 ore all'inizio"),
        isA<DettaglioPartitaCaricato>(),
      ]));
      expect(repo.chiamate, 2);
    });

    test("errore generico: OperazioneErrore col messaggio di ErroreGenericoServer, poi ricarica", () async
    {
      await caricaDettaglio();
      repo.erroreEsci = ErroreGenericoServer();

      bloc.add(const EsciDaPartitaRichiesta(idPartita: 10));

      await expectLater(bloc.stream, emitsInOrder([
        isA<OperazioneInCorso>(),
        operazioneErroreCon(ErroreGenericoServer().messaggio),
        isA<DettaglioPartitaCaricato>(),
      ]));
    });

    test("errore seguito da una ricarica fallita: si arriva a DettaglioPartitaErrore", () async
    {
      await caricaDettaglio();
      repo.erroreEsci = OperazioneRifiutata(messaggio: "Non partecipi a questa partita");
      repo.errore = ErroreGenericoServer();

      bloc.add(const EsciDaPartitaRichiesta(idPartita: 10));

      await expectLater(bloc.stream, emitsInOrder([
        isA<OperazioneInCorso>(),
        operazioneErroreCon("Non partecipi a questa partita"),
        erroreCon(ErroreGenericoServer().messaggio),
      ]));
    });

    test("senza un dettaglio caricato l'evento viene ignorato", () async
    {
      bloc.add(const EsciDaPartitaRichiesta(idPartita: 10));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state, isA<DettaglioPartitaInitial>());
      expect(repo.chiamateEsci, 0);
    });
  });

  group("conferma partecipazione", ()
  {
    test("successo: OperazioneInCorso col dettaglio poi PartecipazioneConfermata col dettaglio del server, senza ricaricare", () async
    {
      await caricaDettaglio();
      repo.rispostaConferma = dettaglioDiTest(posti: [
        PostoPartita(tipo: "UTENTE", telefono: "3331234567", nome: "Mario", cognome: "Rossi", livello: 2.5, confermata: true),
        PostoPartita(tipo: "CAMPO", telefono: null, nome: null, cognome: null, livello: null, confermata: false),
      ]);

      bloc.add(const ConfermaPartitaRichiesta(idPartita: 10));

      await expectLater(bloc.stream, emitsInOrder([
        isA<OperazioneInCorso>().having((s) => s.dettaglio.id, "id", 10),
        isA<PartecipazioneConfermata>().having((s) => s.dettaglio.posti.first.confermata, "confermata", true),
      ]));
      expect(repo.chiamateConferma, 1);
      expect(repo.idConfermaRicevuto, 10);
      expect(repo.chiamateElimina, 0);
      expect(repo.chiamateEsci, 0);
      //il dettaglio era stato chiesto solo una volta, al caricamento
      expect(repo.chiamate, 1);
      //il bloc tiene il dettaglio nuovo per le operazioni successive
      expect(bloc.dettaglio!.posti.first.confermata, true);
    });

    test("409: OperazioneInCorso, OperazioneErrore col messaggio, poi Caricato senza Loading", () async
    {
      await caricaDettaglio();
      repo.erroreConferma = OperazioneRifiutata(messaggio: "Hai già confermato la partecipazione");

      bloc.add(const ConfermaPartitaRichiesta(idPartita: 10));

      //emitsInOrder vuole gli stati uno dopo l'altro: un Loading in mezzo farebbe fallire il test
      await expectLater(bloc.stream, emitsInOrder([
        isA<OperazioneInCorso>(),
        operazioneErroreCon("Hai già confermato la partecipazione"),
        isA<DettaglioPartitaCaricato>(),
      ]));
      expect(repo.chiamateConferma, 1);
      expect(repo.chiamate, 2);
    });

    test("404: OperazioneErrore col messaggio di PartitaNonTrovata, poi ricarica", () async
    {
      await caricaDettaglio();
      repo.erroreConferma = PartitaNonTrovata(messaggio: "Partita non trovata");

      bloc.add(const ConfermaPartitaRichiesta(idPartita: 10));

      await expectLater(bloc.stream, emitsInOrder([
        isA<OperazioneInCorso>(),
        operazioneErroreCon("Partita non trovata"),
        isA<DettaglioPartitaCaricato>(),
      ]));
    });

    test("errore generico: OperazioneErrore col messaggio di ErroreGenericoServer, poi ricarica", () async
    {
      await caricaDettaglio();
      repo.erroreConferma = ErroreGenericoServer();

      bloc.add(const ConfermaPartitaRichiesta(idPartita: 10));

      await expectLater(bloc.stream, emitsInOrder([
        isA<OperazioneInCorso>(),
        operazioneErroreCon(ErroreGenericoServer().messaggio),
        isA<DettaglioPartitaCaricato>(),
      ]));
    });

    test("senza un dettaglio caricato l'evento viene ignorato", () async
    {
      bloc.add(const ConfermaPartitaRichiesta(idPartita: 10));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state, isA<DettaglioPartitaInitial>());
      expect(repo.chiamateConferma, 0);
    });
  });
}
