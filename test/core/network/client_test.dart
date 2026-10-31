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
}
