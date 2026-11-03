import 'package:flutter_test/flutter_test.dart';
import 'package:thepadel/bloc/gestioneLivelli/gestioneLivelliBloc.dart';
import 'package:thepadel/bloc/gestioneLivelli/gestioneLivelliEvent.dart';
import 'package:thepadel/bloc/gestioneLivelli/gestioneLivelliState.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/useCase/adminUseCase.dart';
import 'package:thepadel/useCase/eccezioniUseCase.dart';

import '../../fake/fakeAdminRepo.dart';

List<double> livelli(List<dynamic> utenti)
{
  return utenti.map<double>((u) => u.livello as double).toList();
}

Matcher caricatiCon(List<double> attesi)
{
  return isA<UtentiCaricati>().having((s) => livelli(s.utenti), "livelli", attesi);
}

void main()
{
  late FakeAdminRepo repo;
  late GestioneLivelliBloc bloc;

  setUp(()
  {
    repo = FakeAdminRepo();
    repo.utenti = [utenteAdminDiTest(telefono: "1", livello: 1.0), utenteAdminDiTest(telefono: "2", livello: 2.0)];
    bloc = GestioneLivelliBloc(utentiAdminUseCase: UtentiAdminUseCase(repo: repo), cambiaLivelloUseCase: CambiaLivelloUseCase(repo: repo));
  });

  tearDown(() async
  {
    await bloc.close();
  });

  Future<void> caricaLista({String cerca = ""}) async
  {
    bloc.add(UtentiRichiesti(cerca: cerca));
    await expectLater(bloc.stream, emitsInOrder([isA<GestioneLivelliLoading>(), isA<UtentiCaricati>()]));
  }

  test("lo stato iniziale e GestioneLivelliInitial", ()
  {
    expect(bloc.state, isA<GestioneLivelliInitial>());
  });

  group("elenco", ()
  {
    test("caricamento ok: Loading poi UtentiCaricati, con il testo cercato", () async
    {
      bloc.add(const UtentiRichiesti(cerca: "mar"));

      await expectLater(bloc.stream, emitsInOrder([isA<GestioneLivelliLoading>(), caricatiCon([1.0, 2.0])]));
      expect(repo.cercaRicevuti, ["mar"]);
    });

    test("404: Loading poi UtentiErrore col messaggio del server", () async
    {
      repo.erroreUtenti = PartitaNonTrovata(messaggio: "Non trovato");
      bloc.add(const UtentiRichiesti(cerca: ""));

      await expectLater(bloc.stream, emitsInOrder([isA<GestioneLivelliLoading>(), isA<UtentiErrore>().having((s) => s.messaggio, "messaggio", "Non trovato")]));
    });

    test("403: Loading poi UtentiErrore col messaggio del server", () async
    {
      repo.erroreUtenti = OperazioneRifiutata(messaggio: "Non permesso");
      bloc.add(const UtentiRichiesti(cerca: ""));

      await expectLater(bloc.stream, emitsInOrder([isA<GestioneLivelliLoading>(), isA<UtentiErrore>().having((s) => s.messaggio, "messaggio", "Non permesso")]));
    });

    test("errore generico: Loading poi UtentiErrore", () async
    {
      repo.erroreUtenti = ErroreGenericoServer();
      bloc.add(const UtentiRichiesti(cerca: ""));

      await expectLater(bloc.stream, emitsInOrder([isA<GestioneLivelliLoading>(), isA<UtentiErrore>().having((s) => s.messaggio, "messaggio", ErroreGenericoServer().messaggio)]));
    });

    test("timeout o rete assente: Loading poi UtentiErrore col messaggio generico", () async
    {
      repo.erroreUtenti = Exception("timeout");
      bloc.add(const UtentiRichiesti(cerca: ""));

      await expectLater(bloc.stream, emitsInOrder([isA<GestioneLivelliLoading>(), isA<UtentiErrore>().having((s) => s.messaggio, "messaggio", ErroreGenericoServer().messaggio)]));
    });
  });

  group("cambio di livello", ()
  {
    test("ok: InCorso con la riga, poi Riuscito con la lista aggiornata, senza ricaricare", () async
    {
      await caricaLista();

      bloc.add(const CambiaLivelloRichiesto(telefono: "2", livello: 3.5));

      await expectLater(bloc.stream, emitsInOrder([
        isA<CambioLivelloInCorso>().having((s) => s.telefono, "telefono", "2").having((s) => livelli(s.utenti), "livelli", [1.0, 2.0]),
        isA<CambioLivelloRiuscito>().having((s) => s.utente.livello, "utente", 3.5).having((s) => livelli(s.utenti), "livelli", [1.0, 3.5]),
      ]));
      expect(repo.telefonoLivelloRicevuto, "2");
      expect(repo.cercaRicevuti.length, 1);
    });

    test("livello non valido: Errore senza chiamare il server e senza ricaricare", () async
    {
      await caricaLista();

      bloc.add(const CambiaLivelloRichiesto(telefono: "2", livello: 2.3));

      await expectLater(bloc.stream, emitsInOrder([
        isA<CambioLivelloInCorso>(),
        isA<CambioLivelloErrore>().having((s) => s.messaggio, "messaggio", LivelloNonValido().message).having((s) => livelli(s.utenti), "livelli", [1.0, 2.0]),
      ]));
      expect(repo.chiamateLivello, 0);
      expect(repo.cercaRicevuti.length, 1);
    });

    final errori = <String, Exception Function()>{
      "404": () => PartitaNonTrovata(messaggio: "Utente non trovato"),
      "400": () => OperazioneRifiutata(messaggio: "Il livello deve essere tra 0 e 5 con passo 0,5"),
      "generico": () => ErroreGenericoServer(),
    };
    final messaggi = {
      "404": "Utente non trovato",
      "400": "Il livello deve essere tra 0 e 5 con passo 0,5",
      "generico": ErroreGenericoServer().messaggio,
    };
    errori.forEach((nome, errore)
    {
      test("errore $nome: Errore col messaggio, poi la stessa ricerca viene ricaricata", () async
      {
        await caricaLista(cerca: "mar");
        repo.erroreLivello = errore();
        repo.utenti = [utenteAdminDiTest(telefono: "1", livello: 4.0)];

        bloc.add(const CambiaLivelloRichiesto(telefono: "2", livello: 3.5));

        await expectLater(bloc.stream, emitsInOrder([
          isA<CambioLivelloInCorso>(),
          isA<CambioLivelloErrore>().having((s) => s.messaggio, "messaggio", messaggi[nome]).having((s) => livelli(s.utenti), "livelli", [1.0, 2.0]),
          caricatiCon([4.0]),
        ]));
        expect(repo.cercaRicevuti, ["mar", "mar"]);
      });
    });

    test("timeout: Errore col messaggio generico, poi la ricarica", () async
    {
      await caricaLista();
      repo.erroreLivello = Exception("timeout");

      bloc.add(const CambiaLivelloRichiesto(telefono: "2", livello: 3.5));

      await expectLater(bloc.stream, emitsInOrder([
        isA<CambioLivelloInCorso>(),
        isA<CambioLivelloErrore>().having((s) => s.messaggio, "messaggio", ErroreGenericoServer().messaggio),
        caricatiCon([1.0, 2.0]),
      ]));
    });

    final erroriRicarica = <String, Exception Function()>{
      "404": () => PartitaNonTrovata(messaggio: "x"),
      "403": () => OperazioneRifiutata(messaggio: "x"),
      "generico": () => ErroreGenericoServer(),
      "timeout": () => Exception("timeout"),
    };
    erroriRicarica.forEach((nome, errore)
    {
      test("se fallisce anche la ricarica ($nome) la lista di prima resta a schermo", () async
      {
        await caricaLista();
        repo.erroreLivello = ErroreGenericoServer();
        repo.erroreUtenti = errore();

        bloc.add(const CambiaLivelloRichiesto(telefono: "2", livello: 3.5));

        await expectLater(bloc.stream, emitsInOrder([
          isA<CambioLivelloInCorso>(),
          isA<CambioLivelloErrore>(),
          caricatiCon([1.0, 2.0]),
        ]));
      });
    });
  });
}
