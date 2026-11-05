import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thepadel/core/di/depInjection.dart';
import 'package:thepadel/core/network/client.dart';
import 'package:thepadel/dataLayer/dataSource/dataSourceCampo.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/repositoryImpl/campoRepoImpl.dart';

import '../../fake/fakePrenotazioneRepo.dart';

const String campoJson = '{"id":5,"nome":"Campo Nuovo","alCoperto":true,"oraApertura":"08:30:00","oraChiusura":"23:00:00"}';
const TimeOfDay apertura = TimeOfDay(hour: 8, minute: 30);
const TimeOfDay chiusura = TimeOfDay(hour: 23, minute: 0);

DataSourceCampo creaDataSource(int status, String body, List<http.Request> richieste)
{
  final mock = MockClient((request) async
  {
    richieste.add(request);
    return http.Response(body, status, headers: {'content-type': 'application/json; charset=utf-8'});
  });
  return DataSourceCampo(c: Client(c: mock), elencoUrl: urlDiTest());
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
    SharedPreferences.setMockInitialValues({"jwt": "token-finto"});
    sl.registerSingleton<SharedPreferences>(await SharedPreferences.getInstance());
    richieste = [];
  });

  tearDown(() async
  {
    await sl.reset();
  });

  void controllaRichiesta(String metodo, String url)
  {
    final richiesta = richieste.single;
    expect(richiesta.method, metodo);
    expect(richiesta.url.toString(), url);
    expect(richiesta.headers["Authorization"], "Bearer token-finto");
  }

  test("creaCampo: POST con i dati e le ore in HH:mm, 201 legge il campo", () async
  {
    final ds = creaDataSource(201, campoJson, richieste);

    final campo = await ds.creaCampo("Campo Nuovo", true, apertura, chiusura);

    controllaRichiesta("POST", "http://test/api/campi");
    expect(jsonDecode(richieste.single.body), {"nome": "Campo Nuovo", "alCoperto": true, "oraApertura": "08:30", "oraChiusura": "23:00"});
    expect(campo.id, 5);
    expect(campo.nome, "Campo Nuovo");
    expect(campo.alCoperto, true);
    expect(campo.oraApertura, apertura);
    expect(campo.oraChiusura, chiusura);
  });

  test("modificaCampo: PUT con l'id nell'url e gli stessi dati, 200 legge il campo", () async
  {
    final ds = creaDataSource(200, campoJson, richieste);

    final campo = await ds.modificaCampo(5, "Campo Nuovo", false, apertura, chiusura);

    controllaRichiesta("PUT", "http://test/api/campi/5");
    expect(jsonDecode(richieste.single.body), {"nome": "Campo Nuovo", "alCoperto": false, "oraApertura": "08:30", "oraChiusura": "23:00"});
    expect(campo.id, 5);
  });

  test("eliminaCampo: DELETE con l'id nell'url, 204 senza body va bene", () async
  {
    final ds = creaDataSource(204, "", richieste);

    await ds.eliminaCampo(5);

    controllaRichiesta("DELETE", "http://test/api/campi/5");
  });

  final operazioni = <String, Future<Object?> Function(DataSourceCampo)>{
    "creaCampo": (ds) => ds.creaCampo("Campo", true, apertura, chiusura),
    "modificaCampo": (ds) => ds.modificaCampo(5, "Campo", true, apertura, chiusura),
    "eliminaCampo": (ds) => ds.eliminaCampo(5),
  };

  operazioni.forEach((nome, operazione)
  {
    group("errori di $nome", ()
    {
      test("400 e 409: OperazioneRifiutata col messaggio del server", () async
      {
        for(final status in [400, 409])
        {
          final ds = creaDataSource(status, erroreServer(status, "Il campo ha partite collegate e non può essere eliminato"), richieste);

          await expectLater(operazione(ds), throwsA(isA<OperazioneRifiutata>().having((e) => e.messaggio, "messaggio", "Il campo ha partite collegate e non può essere eliminato")));
        }
      });

      test("404: PartitaNonTrovata col messaggio del server", () async
      {
        final ds = creaDataSource(404, erroreServer(404, "Campo non trovato"), richieste);

        await expectLater(operazione(ds), throwsA(isA<PartitaNonTrovata>().having((e) => e.messaggio, "messaggio", "Campo non trovato")));
      });

      test("500 e risposta senza body: ErroreGenericoServer", () async
      {
        await expectLater(operazione(creaDataSource(500, erroreServer(500, "Boom"), richieste)), throwsA(isA<ErroreGenericoServer>()));
        await expectLater(operazione(creaDataSource(401, "", richieste)), throwsA(isA<ErroreGenericoServer>()));
      });
    });
  });

  test("il repository delega al data source", () async
  {
    final repo = CampoRepoImpl(dsCampo: creaDataSource(200, campoJson, richieste));

    expect((await repo.creaCampo("Campo", true, apertura, chiusura)).id, 5);
    expect((await repo.modificaCampo(5, "Campo", true, apertura, chiusura)).id, 5);
    await CampoRepoImpl(dsCampo: creaDataSource(204, "", richieste)).eliminaCampo(5);
    expect(richieste.length, 3);
  });
}
