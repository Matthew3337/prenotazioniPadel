import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thepadel/core/di/depInjection.dart';
import 'package:thepadel/core/network/client.dart';
import 'package:thepadel/dataLayer/dataSource/dataSourcePartita.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/dataLayer/model/dettaglioPartitaModel.dart';
import 'package:thepadel/dataLayer/model/partitaPubblicaModel.dart';
import 'package:thepadel/dataLayer/model/partitaInvitoModel.dart';
import 'package:thepadel/dataLayer/model/partitaStoricoModel.dart';
import 'package:thepadel/dataLayer/model/utenteInvitabileModel.dart';
import 'package:thepadel/domainLayer/enetity/setPartita.dart';
import 'package:thepadel/repositoryImpl/partitaRepoImpl.dart';

import '../../fake/fakePrenotazioneRepo.dart';

//crea il data source con un client finto che risponde sempre con status e body indicati
//e salva le richieste per poterle controllare
DataSourcePartita creaDataSource(int status, String body, List<http.Request> richieste)
{
  final mock = MockClient((request) async
  {
    richieste.add(request);
    return http.Response(body, status, headers: {'content-type': 'application/json; charset=utf-8'});
  });
  return DataSourcePartita(c: Client(c: mock), elencoUrl: urlDiTest());
}

//risposta 200 del contratto T3, con il livello del creatore passato dal test (intero o decimale)
String rispostaDettaglio(num livelloCreatore)
{
  return jsonEncode({
    "id": 7,
    "idCampo": 1,
    "nomeCampo": "Campo 1",
    "dataPartita": "2026-11-05",
    "oraInizio": "18:00:00",
    "oraFine": "19:30:00",
    "stato": "creata",
    "tipo": "PUBBLICA",
    "telefonoCreatore": "3331234567",
    "posti": [
      {"tipo": "UTENTE", "telefono": "3331234567", "nome": "Mario", "cognome": "Rossi", "livello": livelloCreatore, "confermata": false},
      {"tipo": "CAMPO", "telefono": null, "nome": null, "cognome": null, "livello": null, "confermata": false},
    ],
    "azioni": {"puoInvitare": true, "puoEliminare": true, "puoUscire": false, "puoConfermare": false, "puoRegistrareRisultato": false},
  });
}

String erroreServer(int status, String errore)
{
  return jsonEncode({"timestamp": "2026-11-01T10:00:00", "status": status, "errore": errore});
}

//una partita della bacheca come da contratto T4
Map<String, dynamic> partitaPubblicaJson(int id, num livelloCreatore, int postiLiberi)
{
  return {
    "id": id,
    "idCampo": 1,
    "nomeCampo": "Campo $id",
    "dataPartita": "2026-11-05",
    "oraInizio": "18:00:00",
    "oraFine": "19:30:00",
    "nomeCreatore": "Mario",
    "cognomeCreatore": "Rossi",
    "livelloCreatore": livelloCreatore,
    "postiLiberi": postiLiberi,
  };
}

//una partita dello storico come da contratto T6, col risultato passato dal test (anche null)
Map<String, dynamic> partitaStoricoJson(int id, Map<String, dynamic>? risultato)
{
  return {
    "id": id,
    "idCampo": 1,
    "nomeCampo": "Campo 1",
    "dataPartita": "2026-11-05",
    "oraInizio": "18:00:00",
    "oraFine": "19:30:00",
    "stato": "giocata",
    "tipo": "PUBBLICA",
    "risultato": risultato,
  };
}

//una partita della bacheca inviti come da contratto T7
Map<String, dynamic> partitaInvitoJson(int id, String stato, String tipo)
{
  return {
    "id": id,
    "idCampo": 1,
    "nomeCampo": "Campo $id",
    "dataPartita": "2026-11-05",
    "oraInizio": "18:00:00",
    "oraFine": "19:30:00",
    "stato": stato,
    "tipo": tipo,
    "nomeCreatore": "Mario",
    "cognomeCreatore": "Rossi",
  };
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

  test("200 con livello decimale: restituisce il dettaglio con posti UTENTE e CAMPO e chiama l'url giusto col token", () async
  {
    final ds = creaDataSource(200, rispostaDettaglio(2.5), richieste);

    final dettaglio = await ds.getDettaglioPartita(7);

    expect(richieste.length, 1);
    expect(richieste.first.method, "GET");
    expect(richieste.first.url.toString(), "http://test/api/partite/7");
    expect(richieste.first.headers['Authorization'], "Bearer token-finto");

    expect(dettaglio, isA<DettaglioPartitaModel>());
    expect(dettaglio.id, 7);
    expect(dettaglio.idCampo, 1);
    expect(dettaglio.nomeCampo, "Campo 1");
    expect(dettaglio.dataPartita, DateTime(2026, 11, 5));
    expect(dettaglio.oraInizio.hour, 18);
    expect(dettaglio.oraInizio.minute, 0);
    expect(dettaglio.oraFine.hour, 19);
    expect(dettaglio.oraFine.minute, 30);
    expect(dettaglio.stato, "creata");
    expect(dettaglio.tipo, "PUBBLICA");
    expect(dettaglio.telefonoCreatore, "3331234567");

    expect(dettaglio.posti.length, 2);
    expect(dettaglio.postiLiberi, 2);

    final creatore = dettaglio.posti[0];
    expect(creatore.tipo, "UTENTE");
    expect(creatore.telefono, "3331234567");
    expect(creatore.nome, "Mario");
    expect(creatore.cognome, "Rossi");
    expect(creatore.livello, 2.5);
    expect(creatore.confermata, false);

    final campo = dettaglio.posti[1];
    expect(campo.tipo, "CAMPO");
    expect(campo.telefono, isNull);
    expect(campo.nome, isNull);
    expect(campo.cognome, isNull);
    expect(campo.livello, isNull);
    expect(campo.confermata, false);

    expect(dettaglio.azioni.puoInvitare, true);
    expect(dettaglio.azioni.puoEliminare, true);
    expect(dettaglio.azioni.puoUscire, false);
    expect(dettaglio.azioni.puoConfermare, false);
    expect(dettaglio.azioni.puoRegistrareRisultato, false);
  });

  test("200 con livello intero: il livello viene convertito in double", () async
  {
    final ds = creaDataSource(200, rispostaDettaglio(3), richieste);

    final dettaglio = await ds.getDettaglioPartita(7);

    expect(dettaglio.posti[0].livello, isA<double>());
    expect(dettaglio.posti[0].livello, 3.0);
  });

  test("404: lancia PartitaNonTrovata col messaggio del server", () async
  {
    final ds = creaDataSource(404, erroreServer(404, "Partita non trovata"), richieste);

    await expectLater(
      ds.getDettaglioPartita(99),
      throwsA(isA<PartitaNonTrovata>().having((e) => e.messaggio, "messaggio", "Partita non trovata")),
    );
  });

  test("altro errore del server (500): lancia ErroreGenericoServer", () async
  {
    final ds = creaDataSource(500, erroreServer(500, "Errore interno"), richieste);

    await expectLater(ds.getDettaglioPartita(7), throwsA(isA<ErroreGenericoServer>()));
  });

  test("risposta senza body (es. 401 col token scaduto): lancia ErroreGenericoServer", () async
  {
    final ds = creaDataSource(401, "", richieste);

    await expectLater(ds.getDettaglioPartita(7), throwsA(isA<ErroreGenericoServer>()));
  });

  group("getPartitePubbliche", ()
  {
    test("200 con lista: restituisce le partite nell'ordine del server e chiama l'url giusto col token", () async
    {
      final body = jsonEncode([partitaPubblicaJson(7, 2.5, 2), partitaPubblicaJson(8, 3, 1)]);
      final ds = creaDataSource(200, body, richieste);

      final partite = await ds.getPartitePubbliche();

      expect(richieste.length, 1);
      expect(richieste.first.method, "GET");
      expect(richieste.first.url.toString(), "http://test/api/partite/pubbliche");
      expect(richieste.first.headers['Authorization'], "Bearer token-finto");

      expect(partite.length, 2);
      expect(partite[0], isA<PartitaPubblicaModel>());
      expect(partite[0].id, 7);
      expect(partite[0].idCampo, 1);
      expect(partite[0].nomeCampo, "Campo 7");
      expect(partite[0].dataPartita, DateTime(2026, 11, 5));
      expect(partite[0].oraInizio.hour, 18);
      expect(partite[0].oraInizio.minute, 0);
      expect(partite[0].oraFine.hour, 19);
      expect(partite[0].oraFine.minute, 30);
      expect(partite[0].nomeCreatore, "Mario");
      expect(partite[0].cognomeCreatore, "Rossi");
      expect(partite[0].livelloCreatore, 2.5);
      expect(partite[0].postiLiberi, 2);
      expect(partite[1].id, 8);
      expect(partite[1].postiLiberi, 1);
    });

    test("200 con livelloCreatore intero: viene convertito in double", () async
    {
      final ds = creaDataSource(200, jsonEncode([partitaPubblicaJson(8, 3, 1)]), richieste);

      final partite = await ds.getPartitePubbliche();

      expect(partite[0].livelloCreatore, isA<double>());
      expect(partite[0].livelloCreatore, 3.0);
    });

    test("200 con lista vuota: restituisce una lista vuota", () async
    {
      final ds = creaDataSource(200, "[]", richieste);

      final partite = await ds.getPartitePubbliche();

      expect(partite, isEmpty);
    });

    test("errore del server (500): lancia ErroreGenericoServer", () async
    {
      final ds = creaDataSource(500, erroreServer(500, "Errore interno"), richieste);

      await expectLater(ds.getPartitePubbliche(), throwsA(isA<ErroreGenericoServer>()));
    });

    test("risposta senza body (401): lancia ErroreGenericoServer", () async
    {
      final ds = creaDataSource(401, "", richieste);

      await expectLater(ds.getPartitePubbliche(), throwsA(isA<ErroreGenericoServer>()));
    });
  });

  group("entraInPartita", ()
  {
    test("200: POST all'url con l'id, body vuoto e token, restituisce il dettaglio aggiornato", () async
    {
      final ds = creaDataSource(200, rispostaDettaglio(2.5), richieste);

      final dettaglio = await ds.entraInPartita(7);

      expect(richieste.length, 1);
      expect(richieste.first.method, "POST");
      expect(richieste.first.url.toString(), "http://test/api/partite/7/entra");
      expect(richieste.first.headers['Authorization'], "Bearer token-finto");
      expect(richieste.first.body, "{}");

      expect(dettaglio, isA<DettaglioPartitaModel>());
      expect(dettaglio.id, 7);
      expect(dettaglio.posti.length, 2);
      expect(dettaglio.azioni.puoInvitare, true);
    });

    test("409: lancia IngressoRifiutato col messaggio della regola violata", () async
    {
      final ds = creaDataSource(409, erroreServer(409, "La partita è al completo"), richieste);

      await expectLater(
        ds.entraInPartita(7),
        throwsA(isA<IngressoRifiutato>().having((e) => e.messaggio, "messaggio", "La partita è al completo")),
      );
    });

    test("409 per ingresso chiuso: il messaggio arriva intatto", () async
    {
      final ds = creaDataSource(409, erroreServer(409, "L'ingresso è chiuso: mancano meno di 24 ore all'inizio"), richieste);

      await expectLater(
        ds.entraInPartita(7),
        throwsA(isA<IngressoRifiutato>().having((e) => e.messaggio, "messaggio", "L'ingresso è chiuso: mancano meno di 24 ore all'inizio")),
      );
    });

    test("404: lancia PartitaNonTrovata col messaggio del server", () async
    {
      final ds = creaDataSource(404, erroreServer(404, "Partita non trovata"), richieste);

      await expectLater(
        ds.entraInPartita(99),
        throwsA(isA<PartitaNonTrovata>().having((e) => e.messaggio, "messaggio", "Partita non trovata")),
      );
    });

    test("403 senza body (admin): lancia ErroreGenericoServer", () async
    {
      final ds = creaDataSource(403, "", richieste);

      await expectLater(ds.entraInPartita(7), throwsA(isA<ErroreGenericoServer>()));
    });

    test("altro errore del server (500): lancia ErroreGenericoServer", () async
    {
      final ds = creaDataSource(500, erroreServer(500, "Errore interno"), richieste);

      await expectLater(ds.entraInPartita(7), throwsA(isA<ErroreGenericoServer>()));
    });
  });

  group("eliminaPartita", ()
  {
    test("204: DELETE all'url con l'id e il token, termina senza errori", () async
    {
      final ds = creaDataSource(204, "", richieste);

      await ds.eliminaPartita(7);

      expect(richieste.length, 1);
      expect(richieste.first.method, "DELETE");
      expect(richieste.first.url.toString(), "http://test/api/partite/7");
      expect(richieste.first.headers['Authorization'], "Bearer token-finto");
    });

    test("403 partecipante non creatore: lancia OperazioneRifiutata col messaggio del server", () async
    {
      final ds = creaDataSource(403, erroreServer(403, "Solo il creatore può eliminare la partita"), richieste);

      await expectLater(
        ds.eliminaPartita(7),
        throwsA(isA<OperazioneRifiutata>().having((e) => e.messaggio, "messaggio", "Solo il creatore può eliminare la partita")),
      );
    });

    test("403 admin: lancia OperazioneRifiutata col messaggio del server", () async
    {
      final ds = creaDataSource(403, erroreServer(403, "L'amministratore non può eliminare le partite da qui"), richieste);

      await expectLater(
        ds.eliminaPartita(7),
        throwsA(isA<OperazioneRifiutata>().having((e) => e.messaggio, "messaggio", "L'amministratore non può eliminare le partite da qui")),
      );
    });

    test("409 partita non piu aperta: lancia OperazioneRifiutata col messaggio del server", () async
    {
      final ds = creaDataSource(409, erroreServer(409, "La partita non è più aperta"), richieste);

      await expectLater(
        ds.eliminaPartita(7),
        throwsA(isA<OperazioneRifiutata>().having((e) => e.messaggio, "messaggio", "La partita non è più aperta")),
      );
    });

    test("409 meno di 24 ore: il messaggio arriva intatto", () async
    {
      const messaggio = "L'eliminazione è chiusa: mancano meno di 24 ore all'inizio. Solo l'amministratore può annullare la partita";
      final ds = creaDataSource(409, erroreServer(409, messaggio), richieste);

      await expectLater(
        ds.eliminaPartita(7),
        throwsA(isA<OperazioneRifiutata>().having((e) => e.messaggio, "messaggio", messaggio)),
      );
    });

    test("404: lancia PartitaNonTrovata col messaggio del server", () async
    {
      final ds = creaDataSource(404, erroreServer(404, "Partita non trovata"), richieste);

      await expectLater(
        ds.eliminaPartita(99),
        throwsA(isA<PartitaNonTrovata>().having((e) => e.messaggio, "messaggio", "Partita non trovata")),
      );
    });

    test("risposta senza body (401 col token scaduto): lancia ErroreGenericoServer", () async
    {
      final ds = creaDataSource(401, "", richieste);

      await expectLater(ds.eliminaPartita(7), throwsA(isA<ErroreGenericoServer>()));
    });

    test("altro errore del server (500): lancia ErroreGenericoServer", () async
    {
      final ds = creaDataSource(500, erroreServer(500, "Errore interno"), richieste);

      await expectLater(ds.eliminaPartita(7), throwsA(isA<ErroreGenericoServer>()));
    });
  });

  group("esciDaPartita", ()
  {
    test("204: POST all'url con l'id, body vuoto e token, termina senza errori", () async
    {
      final ds = creaDataSource(204, "", richieste);

      await ds.esciDaPartita(7);

      expect(richieste.length, 1);
      expect(richieste.first.method, "POST");
      expect(richieste.first.url.toString(), "http://test/api/partite/7/esci");
      expect(richieste.first.headers['Authorization'], "Bearer token-finto");
      expect(richieste.first.body, "{}");
    });

    test("403 admin: lancia OperazioneRifiutata col messaggio del server", () async
    {
      final ds = creaDataSource(403, erroreServer(403, "L'amministratore non può uscire dalle partite"), richieste);

      await expectLater(
        ds.esciDaPartita(7),
        throwsA(isA<OperazioneRifiutata>().having((e) => e.messaggio, "messaggio", "L'amministratore non può uscire dalle partite")),
      );
    });

    test("409 creatore: lancia OperazioneRifiutata col messaggio del server", () async
    {
      final ds = creaDataSource(409, erroreServer(409, "Il creatore non può uscire dalla partita: può eliminarla"), richieste);

      await expectLater(
        ds.esciDaPartita(7),
        throwsA(isA<OperazioneRifiutata>().having((e) => e.messaggio, "messaggio", "Il creatore non può uscire dalla partita: può eliminarla")),
      );
    });

    test("409 non partecipa: lancia OperazioneRifiutata col messaggio del server", () async
    {
      final ds = creaDataSource(409, erroreServer(409, "Non partecipi a questa partita"), richieste);

      await expectLater(
        ds.esciDaPartita(7),
        throwsA(isA<OperazioneRifiutata>().having((e) => e.messaggio, "messaggio", "Non partecipi a questa partita")),
      );
    });

    test("409 meno di 24 ore: il messaggio arriva intatto", () async
    {
      final ds = creaDataSource(409, erroreServer(409, "L'uscita è chiusa: mancano meno di 24 ore all'inizio"), richieste);

      await expectLater(
        ds.esciDaPartita(7),
        throwsA(isA<OperazioneRifiutata>().having((e) => e.messaggio, "messaggio", "L'uscita è chiusa: mancano meno di 24 ore all'inizio")),
      );
    });

    test("404: lancia PartitaNonTrovata col messaggio del server", () async
    {
      final ds = creaDataSource(404, erroreServer(404, "Partita non trovata"), richieste);

      await expectLater(
        ds.esciDaPartita(99),
        throwsA(isA<PartitaNonTrovata>().having((e) => e.messaggio, "messaggio", "Partita non trovata")),
      );
    });

    test("risposta senza body (401 col token scaduto): lancia ErroreGenericoServer", () async
    {
      final ds = creaDataSource(401, "", richieste);

      await expectLater(ds.esciDaPartita(7), throwsA(isA<ErroreGenericoServer>()));
    });

    test("altro errore del server (500): lancia ErroreGenericoServer", () async
    {
      final ds = creaDataSource(500, erroreServer(500, "Errore interno"), richieste);

      await expectLater(ds.esciDaPartita(7), throwsA(isA<ErroreGenericoServer>()));
    });
  });

  group("getStorico", ()
  {
    test("200 con risultato null: restituisce la partita senza risultato e chiama l'url giusto col token", () async
    {
      final ds = creaDataSource(200, jsonEncode([partitaStoricoJson(7, null)]), richieste);

      final partite = await ds.getStorico();

      expect(richieste.length, 1);
      expect(richieste.first.method, "GET");
      expect(richieste.first.url.toString(), "http://test/api/partite/storico");
      expect(richieste.first.headers['Authorization'], "Bearer token-finto");

      expect(partite.length, 1);
      expect(partite[0], isA<PartitaStoricoModel>());
      expect(partite[0].id, 7);
      expect(partite[0].idCampo, 1);
      expect(partite[0].nomeCampo, "Campo 1");
      expect(partite[0].dataPartita, DateTime(2026, 11, 5));
      expect(partite[0].oraInizio.hour, 18);
      expect(partite[0].oraInizio.minute, 0);
      expect(partite[0].oraFine.hour, 19);
      expect(partite[0].oraFine.minute, 30);
      expect(partite[0].stato, "giocata");
      expect(partite[0].tipo, "PUBBLICA");
      expect(partite[0].risultato, isNull);
    });

    test("200 con risultato di 3 set e di 2 set: set nell'ordine del server, squadra, esito e punti", () async
    {
      final body = jsonEncode([
        partitaStoricoJson(7, {
          "set": [{"squadra1": 6, "squadra2": 4}, {"squadra1": 3, "squadra2": 6}, {"squadra1": 6, "squadra2": 2}],
          "squadraUtente": 1,
          "esito": "VINTA",
          "puntiAssegnati": 12,
        }),
        partitaStoricoJson(8, {
          "set": [{"squadra1": 6, "squadra2": 1}, {"squadra1": 6, "squadra2": 3}],
          "squadraUtente": 2,
          "esito": "PERSA",
          "puntiAssegnati": -7,
        }),
      ]);
      final ds = creaDataSource(200, body, richieste);

      final partite = await ds.getStorico();

      expect(partite.length, 2);
      final tre = partite[0].risultato!;
      expect(tre.set.length, 3);
      expect(tre.set[0].squadra1, 6);
      expect(tre.set[0].squadra2, 4);
      expect(tre.set[1].squadra1, 3);
      expect(tre.set[1].squadra2, 6);
      expect(tre.set[2].squadra1, 6);
      expect(tre.set[2].squadra2, 2);
      expect(tre.squadraUtente, 1);
      expect(tre.esito, "VINTA");
      expect(tre.puntiAssegnati, 12);

      final due = partite[1].risultato!;
      expect(partite[1].id, 8);
      expect(due.set.length, 2);
      expect(due.set[1].squadra1, 6);
      expect(due.set[1].squadra2, 3);
      expect(due.squadraUtente, 2);
      expect(due.esito, "PERSA");
      expect(due.puntiAssegnati, -7);
    });

    test("200 con squadraUtente, esito e puntiAssegnati null: restano null", () async
    {
      final body = jsonEncode([
        partitaStoricoJson(7, {
          "set": [{"squadra1": 6, "squadra2": 4}, {"squadra1": 6, "squadra2": 4}],
          "squadraUtente": null,
          "esito": null,
          "puntiAssegnati": null,
        }),
      ]);
      final ds = creaDataSource(200, body, richieste);

      final partite = await ds.getStorico();

      final risultato = partite[0].risultato!;
      expect(risultato.set.length, 2);
      expect(risultato.squadraUtente, isNull);
      expect(risultato.esito, isNull);
      expect(risultato.puntiAssegnati, isNull);
    });

    test("200 con lista vuota (utente senza partite o admin): restituisce una lista vuota", () async
    {
      final ds = creaDataSource(200, "[]", richieste);

      final partite = await ds.getStorico();

      expect(partite, isEmpty);
    });

    test("errore del server (500): lancia ErroreGenericoServer", () async
    {
      final ds = creaDataSource(500, erroreServer(500, "Errore interno"), richieste);

      await expectLater(ds.getStorico(), throwsA(isA<ErroreGenericoServer>()));
    });

    test("risposta senza body (403 senza token): lancia ErroreGenericoServer", () async
    {
      final ds = creaDataSource(403, "", richieste);

      await expectLater(ds.getStorico(), throwsA(isA<ErroreGenericoServer>()));
    });
  });

  group("getInvitabili", ()
  {
    test("200 con lista: restituisce gli utenti nell'ordine del server e chiama l'url giusto col token", () async
    {
      final body = jsonEncode([
        {"telefono": "3335550001", "nome": "Luca", "cognome": "Bianchi", "livello": 3},
        {"telefono": "3335550002", "nome": "Anna", "cognome": "Verdi", "livello": 2.5},
      ]);
      final ds = creaDataSource(200, body, richieste);

      final utenti = await ds.getInvitabili(7, "");

      expect(richieste.length, 1);
      expect(richieste.first.method, "GET");
      expect(richieste.first.url.path, "/api/partite/7/invitabili");
      expect(richieste.first.headers['Authorization'], "Bearer token-finto");

      expect(utenti.length, 2);
      expect(utenti[0], isA<UtenteInvitabileModel>());
      expect(utenti[0].telefono, "3335550001");
      expect(utenti[0].nome, "Luca");
      expect(utenti[0].cognome, "Bianchi");
      //il livello intero diventa double
      expect(utenti[0].livello, isA<double>());
      expect(utenti[0].livello, 3.0);
      expect(utenti[1].telefono, "3335550002");
      expect(utenti[1].livello, 2.5);
    });

    test("cerca vuoto: il parametro cerca c'e ma e vuoto", () async
    {
      final ds = creaDataSource(200, "[]", richieste);

      await ds.getInvitabili(7, "");

      expect(richieste.first.url.toString(), "http://test/api/partite/7/invitabili?cerca=");
      expect(richieste.first.url.queryParameters['cerca'], "");
    });

    test("cerca con spazi, accenti e caratteri speciali: viene codificato e il server lo riceve intatto", () async
    {
      final ds = creaDataSource(200, "[]", richieste);

      await ds.getInvitabili(7, "De Niccolò & co");

      final url = richieste.first.url;
      expect(url.queryParameters.length, 1);
      expect(url.queryParameters['cerca'], "De Niccolò & co");
      //nell'url non devono restare spazi o & non codificati
      expect(url.query.contains(" "), false);
      expect(url.query.split("&").length, 1);
    });

    test("200 con lista vuota (nessun utente corrisponde): restituisce una lista vuota", () async
    {
      final ds = creaDataSource(200, "[]", richieste);

      final utenti = await ds.getInvitabili(7, "zzz");

      expect(utenti, isEmpty);
    });

    test("404: lancia PartitaNonTrovata col messaggio del server", () async
    {
      final ds = creaDataSource(404, erroreServer(404, "Partita non trovata"), richieste);

      await expectLater(
        ds.getInvitabili(99, ""),
        throwsA(isA<PartitaNonTrovata>().having((e) => e.messaggio, "messaggio", "Partita non trovata")),
      );
    });

    test("403: lancia OperazioneRifiutata col messaggio del server", () async
    {
      final ds = creaDataSource(403, erroreServer(403, "Solo il creatore può invitare"), richieste);

      await expectLater(
        ds.getInvitabili(7, ""),
        throwsA(isA<OperazioneRifiutata>().having((e) => e.messaggio, "messaggio", "Solo il creatore può invitare")),
      );
    });

    test("risposta senza body (401 col token scaduto): lancia ErroreGenericoServer", () async
    {
      final ds = creaDataSource(401, "", richieste);

      await expectLater(ds.getInvitabili(7, ""), throwsA(isA<ErroreGenericoServer>()));
    });

    test("altro errore del server (500): lancia ErroreGenericoServer", () async
    {
      final ds = creaDataSource(500, erroreServer(500, "Errore interno"), richieste);

      await expectLater(ds.getInvitabili(7, ""), throwsA(isA<ErroreGenericoServer>()));
    });
  });

  group("invitaUtente", ()
  {
    test("200: POST all'url con l'id, body col telefono e token, restituisce il dettaglio aggiornato", () async
    {
      final ds = creaDataSource(200, rispostaDettaglio(2.5), richieste);

      final dettaglio = await ds.invitaUtente(7, "3335550001");

      expect(richieste.length, 1);
      expect(richieste.first.method, "POST");
      expect(richieste.first.url.toString(), "http://test/api/partite/7/inviti");
      expect(richieste.first.headers['Authorization'], "Bearer token-finto");
      expect(jsonDecode(richieste.first.body), {"telefono": "3335550001"});

      expect(dettaglio, isA<DettaglioPartitaModel>());
      expect(dettaglio.id, 7);
      expect(dettaglio.posti.length, 2);
      expect(dettaglio.postiLiberi, 2);
    });

    test("409 partita al completo: lancia OperazioneRifiutata col messaggio del server", () async
    {
      final ds = creaDataSource(409, erroreServer(409, "La partita è al completo"), richieste);

      await expectLater(
        ds.invitaUtente(7, "3335550001"),
        throwsA(isA<OperazioneRifiutata>().having((e) => e.messaggio, "messaggio", "La partita è al completo")),
      );
    });

    test("409 inviti chiusi: il messaggio arriva intatto", () async
    {
      const messaggio = "Gli inviti sono chiusi: mancano meno di 24 ore all'inizio";
      final ds = creaDataSource(409, erroreServer(409, messaggio), richieste);

      await expectLater(
        ds.invitaUtente(7, "3335550001"),
        throwsA(isA<OperazioneRifiutata>().having((e) => e.messaggio, "messaggio", messaggio)),
      );
    });

    test("400 telefono mancante: lancia OperazioneRifiutata col messaggio del server", () async
    {
      final ds = creaDataSource(400, erroreServer(400, "Il telefono è obbligatorio"), richieste);

      await expectLater(
        ds.invitaUtente(7, ""),
        throwsA(isA<OperazioneRifiutata>().having((e) => e.messaggio, "messaggio", "Il telefono è obbligatorio")),
      );
    });

    test("403 non creatore: lancia OperazioneRifiutata col messaggio del server", () async
    {
      final ds = creaDataSource(403, erroreServer(403, "Solo il creatore può invitare"), richieste);

      await expectLater(
        ds.invitaUtente(7, "3335550001"),
        throwsA(isA<OperazioneRifiutata>().having((e) => e.messaggio, "messaggio", "Solo il creatore può invitare")),
      );
    });

    test("404 Utente non trovato: lancia PartitaNonTrovata col messaggio del server", () async
    {
      final ds = creaDataSource(404, erroreServer(404, "Utente non trovato"), richieste);

      await expectLater(
        ds.invitaUtente(7, "3330000000"),
        throwsA(isA<PartitaNonTrovata>().having((e) => e.messaggio, "messaggio", "Utente non trovato")),
      );
    });

    test("404 partita: lancia PartitaNonTrovata col messaggio del server", () async
    {
      final ds = creaDataSource(404, erroreServer(404, "Partita non trovata"), richieste);

      await expectLater(
        ds.invitaUtente(99, "3335550001"),
        throwsA(isA<PartitaNonTrovata>().having((e) => e.messaggio, "messaggio", "Partita non trovata")),
      );
    });

    test("risposta senza body (401 col token scaduto): lancia ErroreGenericoServer", () async
    {
      final ds = creaDataSource(401, "", richieste);

      await expectLater(ds.invitaUtente(7, "3335550001"), throwsA(isA<ErroreGenericoServer>()));
    });

    test("altro errore del server (500): lancia ErroreGenericoServer", () async
    {
      final ds = creaDataSource(500, erroreServer(500, "Errore interno"), richieste);

      await expectLater(ds.invitaUtente(7, "3335550001"), throwsA(isA<ErroreGenericoServer>()));
    });
  });

  group("getInviti", ()
  {
    test("200 con lista: restituisce le partite nell'ordine del server e chiama l'url giusto col token", () async
    {
      final body = jsonEncode([partitaInvitoJson(7, "creata", "PRIVATA"), partitaInvitoJson(8, "confermata", "PUBBLICA")]);
      final ds = creaDataSource(200, body, richieste);

      final partite = await ds.getInviti();

      expect(richieste.length, 1);
      expect(richieste.first.method, "GET");
      expect(richieste.first.url.toString(), "http://test/api/partite/inviti");
      expect(richieste.first.headers['Authorization'], "Bearer token-finto");

      expect(partite.length, 2);
      expect(partite[0], isA<PartitaInvitoModel>());
      expect(partite[0].id, 7);
      expect(partite[0].idCampo, 1);
      expect(partite[0].nomeCampo, "Campo 7");
      expect(partite[0].dataPartita, DateTime(2026, 11, 5));
      expect(partite[0].oraInizio.hour, 18);
      expect(partite[0].oraInizio.minute, 0);
      expect(partite[0].oraFine.hour, 19);
      expect(partite[0].oraFine.minute, 30);
      expect(partite[0].stato, "creata");
      expect(partite[0].tipo, "PRIVATA");
      expect(partite[0].nomeCreatore, "Mario");
      expect(partite[0].cognomeCreatore, "Rossi");
      expect(partite[1].id, 8);
      expect(partite[1].stato, "confermata");
      expect(partite[1].tipo, "PUBBLICA");
    });

    test("200 con lista vuota (nessun invito o admin): restituisce una lista vuota", () async
    {
      final ds = creaDataSource(200, "[]", richieste);

      final partite = await ds.getInviti();

      expect(partite, isEmpty);
    });

    test("errore del server (500): lancia ErroreGenericoServer", () async
    {
      final ds = creaDataSource(500, erroreServer(500, "Errore interno"), richieste);

      await expectLater(ds.getInviti(), throwsA(isA<ErroreGenericoServer>()));
    });

    test("risposta senza body (401 col token scaduto): lancia ErroreGenericoServer", () async
    {
      final ds = creaDataSource(401, "", richieste);

      await expectLater(ds.getInviti(), throwsA(isA<ErroreGenericoServer>()));
    });
  });

  group("confermaPartita", ()
  {
    test("200: POST all'url con l'id, body vuoto e token, restituisce il dettaglio aggiornato", () async
    {
      final ds = creaDataSource(200, rispostaDettaglio(2.5), richieste);

      final dettaglio = await ds.confermaPartita(7);

      expect(richieste.length, 1);
      expect(richieste.first.method, "POST");
      expect(richieste.first.url.toString(), "http://test/api/partite/7/conferma");
      expect(richieste.first.headers['Authorization'], "Bearer token-finto");
      expect(richieste.first.body, "{}");

      expect(dettaglio, isA<DettaglioPartitaModel>());
      expect(dettaglio.id, 7);
      expect(dettaglio.posti.length, 2);
      expect(dettaglio.stato, "creata");
    });

    test("409: lancia OperazioneRifiutata col messaggio della regola violata", () async
    {
      final ds = creaDataSource(409, erroreServer(409, "La conferma è possibile solo tra 24 e 12 ore prima dell'inizio"), richieste);

      await expectLater(
        ds.confermaPartita(7),
        throwsA(isA<OperazioneRifiutata>().having((e) => e.messaggio, "messaggio", "La conferma è possibile solo tra 24 e 12 ore prima dell'inizio")),
      );
    });

    test("409 per conferma gia fatta: il messaggio arriva intatto", () async
    {
      final ds = creaDataSource(409, erroreServer(409, "Hai già confermato la partecipazione"), richieste);

      await expectLater(
        ds.confermaPartita(7),
        throwsA(isA<OperazioneRifiutata>().having((e) => e.messaggio, "messaggio", "Hai già confermato la partecipazione")),
      );
    });

    test("403 (admin): lancia OperazioneRifiutata col messaggio del server", () async
    {
      final ds = creaDataSource(403, erroreServer(403, "L'amministratore non conferma le partite"), richieste);

      await expectLater(
        ds.confermaPartita(7),
        throwsA(isA<OperazioneRifiutata>().having((e) => e.messaggio, "messaggio", "L'amministratore non conferma le partite")),
      );
    });

    test("404: lancia PartitaNonTrovata col messaggio del server", () async
    {
      final ds = creaDataSource(404, erroreServer(404, "Partita non trovata"), richieste);

      await expectLater(
        ds.confermaPartita(99),
        throwsA(isA<PartitaNonTrovata>().having((e) => e.messaggio, "messaggio", "Partita non trovata")),
      );
    });

    test("altro errore del server (500): lancia ErroreGenericoServer", () async
    {
      final ds = creaDataSource(500, erroreServer(500, "Errore interno"), richieste);

      await expectLater(ds.confermaPartita(7), throwsA(isA<ErroreGenericoServer>()));
    });

    test("risposta senza body (401 col token scaduto): lancia ErroreGenericoServer", () async
    {
      final ds = creaDataSource(401, "", richieste);

      await expectLater(ds.confermaPartita(7), throwsA(isA<ErroreGenericoServer>()));
    });
  });

  group("registraRisultato", ()
  {
    final squadra1 = [11, 12];
    final squadra2 = [13, 14];
    final set = [SetPartita(squadra1: 6, squadra2: 4), SetPartita(squadra1: 3, squadra2: 6), SetPartita(squadra1: 6, squadra2: 2)];

    //risposta 200 del contratto T9: il dettaglio con squadre e risultato valorizzati
    String rispostaConRisultato()
    {
      final dettaglio = jsonDecode(rispostaDettaglio(2.5)) as Map<String, dynamic>;
      dettaglio["stato"] = "giocata";
      dettaglio["posti"] = [
        {"idPosto": 11, "tipo": "UTENTE", "telefono": "3331234567", "nome": "Mario", "cognome": "Rossi", "livello": 2.5, "confermata": true, "squadra": 1},
        {"idPosto": 14, "tipo": "CAMPO", "telefono": null, "nome": null, "cognome": null, "livello": null, "confermata": false, "squadra": 2},
      ];
      dettaglio["risultato"] = {
        "set": [{"squadra1": 6, "squadra2": 4}, {"squadra1": 3, "squadra2": 6}, {"squadra1": 6, "squadra2": 2}],
        "squadraUtente": 1,
        "esito": "VINTA",
        "puntiAssegnati": null,
      };
      return jsonEncode(dettaglio);
    }

    test("200: POST all'url con l'id, token e body del contratto, restituisce il dettaglio aggiornato", () async
    {
      final ds = creaDataSource(200, rispostaConRisultato(), richieste);

      final dettaglio = await ds.registraRisultato(7, squadra1, squadra2, set);

      expect(richieste.length, 1);
      expect(richieste.first.method, "POST");
      expect(richieste.first.url.toString(), "http://test/api/partite/7/risultato");
      expect(richieste.first.headers['Authorization'], "Bearer token-finto");
      expect(jsonDecode(richieste.first.body), {
        "squadra1": [11, 12],
        "squadra2": [13, 14],
        "set": [{"squadra1": 6, "squadra2": 4}, {"squadra1": 3, "squadra2": 6}, {"squadra1": 6, "squadra2": 2}],
      });

      expect(dettaglio, isA<DettaglioPartitaModel>());
      expect(dettaglio.stato, "giocata");
      expect(dettaglio.posti[0].squadra, 1);
      expect(dettaglio.risultato!.set.length, 3);
      expect(dettaglio.risultato!.esito, "VINTA");
    });

    test("con due soli set il body ne contiene due", () async
    {
      final ds = creaDataSource(200, rispostaConRisultato(), richieste);

      await ds.registraRisultato(7, squadra1, squadra2, [SetPartita(squadra1: 6, squadra2: 4), SetPartita(squadra1: 6, squadra2: 2)]);

      final body = jsonDecode(richieste.first.body) as Map<String, dynamic>;
      expect(body["set"], [{"squadra1": 6, "squadra2": 4}, {"squadra1": 6, "squadra2": 2}]);
    });

    test("il repository delega al data source", () async
    {
      final ds = creaDataSource(200, rispostaConRisultato(), richieste);

      final dettaglio = await PartitaRepoImpl(dsPartita: ds).registraRisultato(7, squadra1, squadra2, set);

      expect(dettaglio.stato, "giocata");
      expect(richieste.length, 1);
    });

    for(final caso in {
      400: "Il terzo set non va inserito se una squadra ha vinto i primi due",
      403: "L'amministratore modifica i risultati dalla propria area",
      409: "Il risultato è già stato registrato",
    }.entries)
    {
      test("${caso.key}: lancia OperazioneRifiutata col messaggio del server", () async
      {
        final ds = creaDataSource(caso.key, erroreServer(caso.key, caso.value), richieste);

        await expectLater(
          ds.registraRisultato(7, squadra1, squadra2, set),
          throwsA(isA<OperazioneRifiutata>().having((e) => e.messaggio, "messaggio", caso.value)),
        );
      });
    }

    test("404: lancia PartitaNonTrovata col messaggio del server", () async
    {
      final ds = creaDataSource(404, erroreServer(404, "Partita non trovata"), richieste);

      await expectLater(
        ds.registraRisultato(99, squadra1, squadra2, set),
        throwsA(isA<PartitaNonTrovata>().having((e) => e.messaggio, "messaggio", "Partita non trovata")),
      );
    });

    test("altro errore del server (500): lancia ErroreGenericoServer", () async
    {
      final ds = creaDataSource(500, erroreServer(500, "Errore interno"), richieste);

      await expectLater(ds.registraRisultato(7, squadra1, squadra2, set), throwsA(isA<ErroreGenericoServer>()));
    });

    test("risposta senza body (401 col token scaduto): lancia ErroreGenericoServer", () async
    {
      final ds = creaDataSource(401, "", richieste);

      await expectLater(ds.registraRisultato(7, squadra1, squadra2, set), throwsA(isA<ErroreGenericoServer>()));
    });
  });

  test("getTelefonoUtente legge il telefono salvato al login, anche dal repository", ()
  {
    final ds = creaDataSource(200, '', <http.Request>[]);

    expect(ds.getTelefonoUtente(), sl<SharedPreferences>().getString("telefono"));
    expect(PartitaRepoImpl(dsPartita: ds).getTelefonoUtente(), sl<SharedPreferences>().getString("telefono"));
  });
}
