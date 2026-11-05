import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thepadel/core/di/depInjection.dart';
import 'package:thepadel/core/network/client.dart';
import 'package:thepadel/dataLayer/dataSource/dataSourceAdmin.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/domainLayer/enetity/setPartita.dart';
import 'package:thepadel/repositoryImpl/adminRepoImpl.dart';

import '../../fake/fakePrenotazioneRepo.dart';

DataSourceAdmin creaDataSource(int status, String body, List<http.Request> richieste)
{
  final mock = MockClient((request) async
  {
    richieste.add(request);
    return http.Response(body, status, headers: {'content-type': 'application/json; charset=utf-8'});
  });
  return DataSourceAdmin(c: Client(c: mock), elencoUrl: urlDiTest());
}

String dettaglioJson()
{
  return jsonEncode({
    "id": 7,
    "idCampo": 1,
    "nomeCampo": "Campo 1",
    "dataPartita": "2026-11-05",
    "oraInizio": "18:00:00",
    "oraFine": "19:30:00",
    "stato": "confermata",
    "tipo": "PUBBLICA",
    "telefonoCreatore": "3331234567",
    "posti": [
      {"tipo": "UTENTE", "telefono": "3331234567", "nome": "Mario", "cognome": "Rossi", "livello": 2.5, "confermata": true},
    ],
    "azioni": {"puoInvitare": false, "puoEliminare": false, "puoUscire": false, "puoConfermare": false, "puoRegistrareRisultato": false},
  });
}

const String utenteJson = '{"telefono":"3335550001","nome":"Luca","cognome":"Bianchi","livello":3,"punteggio":12}';

String erroreServer(int status, String errore)
{
  return jsonEncode({"timestamp": "2026-11-01T10:00:00", "status": status, "errore": errore});
}

void main()
{
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<http.Request> richieste;

  setUp(() async
  {
    await sl.reset();
    SharedPreferences.setMockInitialValues({"jwt": "token-finto", "telefono": "3331234567"});
    sl.registerSingleton<SharedPreferences>(await SharedPreferences.getInstance());
    richieste = [];
  });

  tearDown(() async
  {
    await sl.reset();
  });

  void controllaRichiesta(String metodo, String url, {Object? body})
  {
    final richiesta = richieste.single;
    expect(richiesta.method, metodo);
    expect(richiesta.url.toString(), url);
    expect(richiesta.headers["Authorization"], "Bearer token-finto");
    if(body != null)
    {
      expect(jsonDecode(richiesta.body), body);
    }
  }

  group("getPartiteDelGiorno", ()
  {
    test("200: GET con la data, legge campi, partite e risultato; un campo senza partite resta", () async
    {
      final ds = creaDataSource(200, jsonEncode([
        {
          "idCampo": 1,
          "nomeCampo": "Campo Centrale",
          "partite": [
            {"id": 7, "oraInizio": "18:30:00", "oraFine": "20:00:00", "stato": "annullata", "tipo": "PUBBLICA", "giocatori": ["Mario Rossi", "Giocatore del campo"], "postiLiberi": 2, "risultato": [{"squadra1": 6, "squadra2": 4}]},
            {"id": 8, "oraInizio": "20:00:00", "oraFine": "21:30:00", "stato": "creata", "tipo": "PRIVATA", "giocatori": [], "postiLiberi": 4, "risultato": null},
          ],
        },
        {"idCampo": 2, "nomeCampo": "Campo 2", "partite": []},
      ]), richieste);

      final campi = await ds.getPartiteDelGiorno(DateTime(2026, 3, 5));

      controllaRichiesta("GET", "http://test/api/admin/partite?data=2026-03-05");
      expect(campi.length, 2);
      expect(campi[0].idCampo, 1);
      expect(campi[0].nomeCampo, "Campo Centrale");
      expect(campi[1].partite, isEmpty);

      final annullata = campi[0].partite[0];
      expect(annullata.id, 7);
      expect(annullata.oraInizio, const TimeOfDay(hour: 18, minute: 30));
      expect(annullata.oraFine, const TimeOfDay(hour: 20, minute: 0));
      expect(annullata.stato, "annullata");
      expect(annullata.tipo, "PUBBLICA");
      expect(annullata.giocatori, ["Mario Rossi", "Giocatore del campo"]);
      expect(annullata.postiLiberi, 2);
      expect(annullata.risultato!.single.squadra1, 6);
      expect(annullata.risultato!.single.squadra2, 4);

      expect(campi[0].partite[1].risultato, isNull);
    });
  });

  group("getAvvisi", ()
  {
    test("200: GET, legge tutti i campi", () async
    {
      final ds = creaDataSource(200, jsonEncode([
        {"id": 3, "idPartita": 7, "nomeCampo": "Campo 1", "dataPartita": "2026-11-05", "oraInizio": "18:30:00", "oraFine": "20:00:00", "postiLiberi": 1},
      ]), richieste);

      final avvisi = await ds.getAvvisi();

      controllaRichiesta("GET", "http://test/api/admin/avvisi");
      expect(avvisi.single.id, 3);
      expect(avvisi.single.idPartita, 7);
      expect(avvisi.single.nomeCampo, "Campo 1");
      expect(avvisi.single.dataPartita, DateTime(2026, 11, 5));
      expect(avvisi.single.oraInizio, const TimeOfDay(hour: 18, minute: 30));
      expect(avvisi.single.oraFine, const TimeOfDay(hour: 20, minute: 0));
      expect(avvisi.single.postiLiberi, 1);
    });

    test("200 con lista vuota: nessun avviso", () async
    {
      final ds = creaDataSource(200, "[]", richieste);

      expect(await ds.getAvvisi(), isEmpty);
    });
  });

  group("getUtenti", ()
  {
    test("200: GET col testo cercato, il livello intero diventa double", () async
    {
      final ds = creaDataSource(200, "[$utenteJson]", richieste);

      final utenti = await ds.getUtenti("mar");

      controllaRichiesta("GET", "http://test/api/admin/utenti?cerca=mar");
      expect(utenti.single.telefono, "3335550001");
      expect(utenti.single.nome, "Luca");
      expect(utenti.single.cognome, "Bianchi");
      expect(utenti.single.livello, 3.0);
      expect(utenti.single.punteggio, 12);
    });

    test("cerca vuoto: il parametro resta, senza valore", () async
    {
      final ds = creaDataSource(200, "[]", richieste);

      await ds.getUtenti("");

      controllaRichiesta("GET", "http://test/api/admin/utenti?cerca=");
    });

    test("spazi e accenti vengono codificati e il server legge il testo originale", () async
    {
      final ds = creaDataSource(200, "[]", richieste);

      await ds.getUtenti("niccolò de & co");

      expect(richieste.single.url.queryParameters["cerca"], "niccolò de & co");
    });
  });

  group("cambiaLivello", ()
  {
    test("200: PUT col livello nel body, restituisce l'utente aggiornato", () async
    {
      final ds = creaDataSource(200, utenteJson, richieste);

      final utente = await ds.cambiaLivello("3335550001", 2.5);

      controllaRichiesta("PUT", "http://test/api/admin/utenti/3335550001/livello", body: {"livello": 2.5});
      expect(utente.telefono, "3335550001");
      expect(utente.livello, 3.0);
    });
  });

  group("operazioni sulla partita", ()
  {
    test("modificaPartecipanti: PUT coi telefoni, restituisce il dettaglio", () async
    {
      final ds = creaDataSource(200, dettaglioJson(), richieste);

      final dettaglio = await ds.modificaPartecipanti(7, ["3331234567", "3335550001"]);

      controllaRichiesta("PUT", "http://test/api/admin/partite/7/partecipanti", body: {"telefoni": ["3331234567", "3335550001"]});
      expect(dettaglio.id, 7);
      expect(dettaglio.posti.single.nome, "Mario");
    });

    test("modificaRisultato: PUT con squadre e set come POST /risultato", () async
    {
      final ds = creaDataSource(200, dettaglioJson(), richieste);

      final dettaglio = await ds.modificaRisultato(7, [11, 12], [13, 14], [SetPartita(squadra1: 6, squadra2: 4), SetPartita(squadra1: 3, squadra2: 6)]);

      controllaRichiesta("PUT", "http://test/api/admin/partite/7/risultato", body: {
        "squadra1": [11, 12],
        "squadra2": [13, 14],
        "set": [{"squadra1": 6, "squadra2": 4}, {"squadra1": 3, "squadra2": 6}],
      });
      expect(dettaglio.id, 7);
    });

    test("modificaStato: PUT con lo stato", () async
    {
      final ds = creaDataSource(200, dettaglioJson(), richieste);

      final dettaglio = await ds.modificaStato(7, "annullata");

      controllaRichiesta("PUT", "http://test/api/admin/partite/7/stato", body: {"stato": "annullata"});
      expect(dettaglio.stato, "confermata");
    });

    test("annullaPartita: POST con body vuoto", () async
    {
      final ds = creaDataSource(200, dettaglioJson(), richieste);

      final dettaglio = await ds.annullaPartita(7);

      controllaRichiesta("POST", "http://test/api/admin/partite/7/annulla", body: {});
      expect(dettaglio.id, 7);
    });
  });

  //tutti gli endpoint trattano gli errori allo stesso modo
  final Map<String, Future<dynamic> Function(DataSourceAdmin)> operazioni = {
    "getPartiteDelGiorno": (ds) => ds.getPartiteDelGiorno(DateTime(2026, 11, 5)),
    "getAvvisi": (ds) => ds.getAvvisi(),
    "getUtenti": (ds) => ds.getUtenti("mar"),
    "cambiaLivello": (ds) => ds.cambiaLivello("3335550001", 2.5),
    "modificaPartecipanti": (ds) => ds.modificaPartecipanti(7, ["3331234567"]),
    "modificaRisultato": (ds) => ds.modificaRisultato(7, [11, 12], [13, 14], [SetPartita(squadra1: 6, squadra2: 4)]),
    "modificaStato": (ds) => ds.modificaStato(7, "giocata"),
    "annullaPartita": (ds) => ds.annullaPartita(7),
  };

  operazioni.forEach((nome, operazione)
  {
    group("errori di $nome", ()
    {
      for(final status in [400, 403, 409])
      {
        test("$status: OperazioneRifiutata col messaggio del server", () async
        {
          final ds = creaDataSource(status, erroreServer(status, "Regola violata"), richieste);

          await expectLater(operazione(ds), throwsA(isA<OperazioneRifiutata>().having((e) => e.messaggio, "messaggio", "Regola violata")));
        });
      }

      test("404: PartitaNonTrovata col messaggio del server", () async
      {
        final ds = creaDataSource(404, erroreServer(404, "Utente non trovato"), richieste);

        await expectLater(operazione(ds), throwsA(isA<PartitaNonTrovata>().having((e) => e.messaggio, "messaggio", "Utente non trovato")));
      });

      test("500: ErroreGenericoServer", () async
      {
        final ds = creaDataSource(500, erroreServer(500, "Errore interno"), richieste);

        await expectLater(operazione(ds), throwsA(isA<ErroreGenericoServer>()));
      });

      //Spring Security risponde cosi al non admin e al token scaduto
      for(final status in [401, 403])
      {
        test("$status senza body: ErroreGenericoServer", () async
        {
          final ds = creaDataSource(status, "", richieste);

          await expectLater(operazione(ds), throwsA(isA<ErroreGenericoServer>()));
        });
      }

      test("mappa senza errore: ErroreGenericoServer", () async
      {
        final ds = creaDataSource(200, '{"qualcosa":1}', richieste);

        await expectLater(operazione(ds), throwsA(isA<ErroreGenericoServer>()));
      });
    });
  });

  group("giocatori del campo e impostazioni", ()
  {
    test("getLivelloGiocatoriCampo: GET, legge anche un intero", () async
    {
      final ds = creaDataSource(200, '{"livelloGiocatoriCampo":3}', richieste);

      expect(await ds.getLivelloGiocatoriCampo(), 3.0);
      controllaRichiesta("GET", "http://test/api/admin/impostazioni");
    });

    test("setLivelloGiocatoriCampo: PUT con il livello, legge la risposta", () async
    {
      final ds = creaDataSource(200, '{"livelloGiocatoriCampo":2.5}', richieste);

      expect(await ds.setLivelloGiocatoriCampo(2.5), 2.5);
      controllaRichiesta("PUT", "http://test/api/admin/impostazioni/livello-giocatori-campo", body: {"livello": 2.5});
    });

    test("aggiungiGiocatoriCampo: POST con il numero, legge il dettaglio", () async
    {
      final ds = creaDataSource(200, dettaglioJson(), richieste);

      expect((await ds.aggiungiGiocatoriCampo(7, 2)).id, 7);
      controllaRichiesta("POST", "http://test/api/admin/partite/7/giocatori-campo", body: {"numero": 2});
    });

    test("rimuoviGiocatoreCampo: DELETE con partita e posto, legge il dettaglio", () async
    {
      final ds = creaDataSource(200, dettaglioJson(), richieste);

      expect((await ds.rimuoviGiocatoreCampo(7, 14)).id, 7);
      controllaRichiesta("DELETE", "http://test/api/admin/partite/7/giocatori-campo/14");
    });

    test("creaPartitaAdmin: POST con tutti i dati, 201 legge il dettaglio e dall'ora toglie i secondi", () async
    {
      final ds = creaDataSource(201, dettaglioJson(), richieste);

      final creata = await ds.creaPartitaAdmin(1, DateTime(2026, 3, 5), "18:00:00", "PUBBLICA", ["3335550001"], 1);

      expect(creata.id, 7);
      controllaRichiesta("POST", "http://test/api/admin/partite", body: {
        "idCampo": 1,
        "dataPartita": "2026-03-05",
        "oraInizio": "18:00",
        "tipo": "PUBBLICA",
        "telefoni": ["3335550001"],
        "giocatoriCampo": 1,
      });
    });

    test("creaPartitaAdmin: un'ora gia senza secondi resta uguale", () async
    {
      final ds = creaDataSource(201, dettaglioJson(), richieste);

      await ds.creaPartitaAdmin(1, DateTime(2026, 3, 5), "18:00", "PRIVATA", ["3335550001"], 0);

      expect(jsonDecode(richieste.single.body)["oraInizio"], "18:00");
    });

    final operazioni = <String, Future<Object?> Function(DataSourceAdmin)>{
      "getLivelloGiocatoriCampo": (ds) => ds.getLivelloGiocatoriCampo(),
      "setLivelloGiocatoriCampo": (ds) => ds.setLivelloGiocatoriCampo(2.5),
      "aggiungiGiocatoriCampo": (ds) => ds.aggiungiGiocatoriCampo(7, 2),
      "rimuoviGiocatoreCampo": (ds) => ds.rimuoviGiocatoreCampo(7, 14),
      "creaPartitaAdmin": (ds) => ds.creaPartitaAdmin(1, DateTime(2026, 3, 5), "18:00", "PUBBLICA", ["1"], 0),
    };

    operazioni.forEach((nome, operazione)
    {
      group("errori di $nome", ()
      {
        test("400 e 409: OperazioneRifiutata col messaggio del server", () async
        {
          for(final status in [400, 409])
          {
            final ds = creaDataSource(status, erroreServer(status, "Regola violata"), richieste);

            await expectLater(operazione(ds), throwsA(isA<OperazioneRifiutata>().having((e) => e.messaggio, "messaggio", "Regola violata")));
          }
        });

        test("404: PartitaNonTrovata col messaggio del server", () async
        {
          final ds = creaDataSource(404, erroreServer(404, "Partita non trovata"), richieste);

          await expectLater(operazione(ds), throwsA(isA<PartitaNonTrovata>().having((e) => e.messaggio, "messaggio", "Partita non trovata")));
        });

        test("500 e risposta senza body: ErroreGenericoServer", () async
        {
          await expectLater(operazione(creaDataSource(500, erroreServer(500, "Boom"), richieste)), throwsA(isA<ErroreGenericoServer>()));
          await expectLater(operazione(creaDataSource(401, "", richieste)), throwsA(isA<ErroreGenericoServer>()));
        });
      });
    });
  });

  group("repository", ()
  {
    test("delega al data source e restituisce le entity", () async
    {
      final repo = AdminRepoImpl(dsAdmin: creaDataSource(200, dettaglioJson(), richieste));

      expect((await repo.modificaPartecipanti(7, ["1"])).id, 7);
      expect((await repo.modificaRisultato(7, [1, 2], [3, 4], [])).id, 7);
      expect((await repo.modificaStato(7, "creata")).id, 7);
      expect((await repo.annullaPartita(7)).id, 7);
      expect(richieste.length, 4);

      expect((await repo.aggiungiGiocatoriCampo(7, 1)).id, 7);
      expect((await repo.rimuoviGiocatoreCampo(7, 14)).id, 7);
      expect((await repo.creaPartitaAdmin(1, DateTime(2026, 11, 5), "18:00", "PUBBLICA", ["1"], 0)).id, 7);
      expect(await AdminRepoImpl(dsAdmin: creaDataSource(200, '{"livelloGiocatoriCampo":2}', richieste)).getLivelloGiocatoriCampo(), 2.0);
      expect(await AdminRepoImpl(dsAdmin: creaDataSource(200, '{"livelloGiocatoriCampo":2}', richieste)).setLivelloGiocatoriCampo(2), 2.0);

      expect((await AdminRepoImpl(dsAdmin: creaDataSource(200, "[]", richieste)).getPartiteDelGiorno(DateTime(2026, 11, 5))), isEmpty);
      expect((await AdminRepoImpl(dsAdmin: creaDataSource(200, "[]", richieste)).getAvvisi()), isEmpty);
      expect((await AdminRepoImpl(dsAdmin: creaDataSource(200, "[]", richieste)).getUtenti("")), isEmpty);
      expect((await AdminRepoImpl(dsAdmin: creaDataSource(200, utenteJson, richieste)).cambiaLivello("3335550001", 3)).livello, 3.0);
    });
  });
}
