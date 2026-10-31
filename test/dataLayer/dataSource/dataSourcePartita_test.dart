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
}
