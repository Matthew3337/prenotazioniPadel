import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:thepadel/core/network/client.dart';

//client finto che risponde sempre con status e body indicati e salva le richieste
Client creaClient(int status, String body, List<http.Request> richieste)
{
  final mock = MockClient((request) async
  {
    richieste.add(request);
    return http.Response(body, status, headers: {'content-type': 'application/json; charset=utf-8'});
  });
  return Client(c: mock);
}

void main()
{
  late List<http.Request> richieste;

  setUp(()
  {
    richieste = [];
  });

  test("delete: 204 senza body restituisce la mappa con lo status e manda il token", () async
  {
    final client = creaClient(204, "", richieste);

    final res = await client.delete("http://test/api/partite/7", token: "token-finto");

    expect(res, {"status": 204});
    expect(richieste.length, 1);
    expect(richieste.first.method, "DELETE");
    expect(richieste.first.url.toString(), "http://test/api/partite/7");
    expect(richieste.first.headers['Authorization'], "Bearer token-finto");
  });

  test("delete senza token: nessun header Authorization", () async
  {
    final client = creaClient(204, "", richieste);

    await client.delete("http://test/api/partite/7");

    expect(richieste.first.headers.containsKey('Authorization'), false);
  });

  test("post: anche qui il 204 restituisce la mappa con lo status", () async
  {
    final client = creaClient(204, "", richieste);

    final res = await client.post("http://test/api/partite/7/esci", {}, token: "token-finto");

    expect(res, {"status": 204});
    expect(richieste.first.method, "POST");
    expect(richieste.first.body, "{}");
  });

  test("risposta vuota con uno status diverso da 204 (es. 401): restituisce null", () async
  {
    final client = creaClient(401, "", richieste);

    expect(await client.delete("http://test/api/partite/7", token: "token-finto"), isNull);
    expect(await client.get("http://test/api/partite/7", token: "token-finto"), isNull);
  });

  test("risposta con body: restituisce il json decodificato", () async
  {
    final client = creaClient(409, '{"status":409,"errore":"La partita non è più aperta"}', richieste);

    final res = await client.delete("http://test/api/partite/7", token: "token-finto");

    expect(res, {"status": 409, "errore": "La partita non è più aperta"});
  });

  group("put", ()
  {
    test("manda metodo, url, body in json e token", () async
    {
      final client = creaClient(200, '{"telefono":"3331234567"}', richieste);

      final res = await client.put("http://test/api/admin/utenti/3331234567/livello", {"livello": 2.5}, token: "token-finto");

      expect(res, {"telefono": "3331234567"});
      expect(richieste.single.method, "PUT");
      expect(richieste.single.url.toString(), "http://test/api/admin/utenti/3331234567/livello");
      expect(richieste.single.body, '{"livello":2.5}');
      expect(richieste.single.headers['Content-Type'], startsWith("application/json"));
      expect(richieste.single.headers['Authorization'], "Bearer token-finto");
    });

    test("senza token: nessun header Authorization, il Content-Type resta", () async
    {
      final client = creaClient(200, "{}", richieste);

      await client.put("http://test/x", {"a": 1});

      expect(richieste.single.headers.containsKey('Authorization'), false);
      expect(richieste.single.headers['Content-Type'], startsWith("application/json"));
    });

    test("204: restituisce la mappa con lo status", () async
    {
      final client = creaClient(204, "", richieste);

      expect(await client.put("http://test/x", {}, token: "token-finto"), {"status": 204});
    });

    test("403 senza body, come risponde Spring Security: restituisce null", () async
    {
      final client = creaClient(403, "", richieste);

      expect(await client.put("http://test/x", {}, token: "token-finto"), isNull);
    });

    test("errore con body: restituisce il json decodificato", () async
    {
      final client = creaClient(409, '{"status":409,"errore":"La partita è già annullata"}', richieste);

      expect(await client.put("http://test/x", {}, token: "token-finto"), {"status": 409, "errore": "La partita è già annullata"});
    });

    test("il timeout arriva a chi chiama", () async
    {
      final mock = MockClient((request) async
      {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return http.Response("{}", 200);
      });
      final client = Client(c: mock, timeout: const Duration(milliseconds: 1));

      await expectLater(client.put("http://test/x", {}), throwsA(isA<TimeoutException>()));
    });
  });
}
