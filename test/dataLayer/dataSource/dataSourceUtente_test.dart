import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thepadel/core/di/depInjection.dart';
import 'package:thepadel/core/network/client.dart';
import 'package:thepadel/dataLayer/dataSource/dataSourceUtente.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/repositoryImpl/utenteRepoImpl.dart';

import '../../fake/fakePrenotazioneRepo.dart';

//crea il data source con un client finto che risponde sempre con status e body indicati
//e salva l'ultima richiesta per poterla controllare
DataSourceUtente creaDataSource(int status, String body, List<http.Request> richieste)
{
  final mock = MockClient((request) async
  {
    richieste.add(request);
    return http.Response(body, status, headers: {'content-type': 'application/json; charset=utf-8'});
  });
  return DataSourceUtente(c: Client(c: mock), elencoUrl: urlDiTest());
}

Map<String, dynamic> voceJson({int posizione = 1, String telefono = "3331234567", String nome = "Mario", String cognome = "Rossi", int punteggio = 3, bool utenteCorrente = true})
{
  return {"posizione": posizione, "telefono": telefono, "nome": nome, "cognome": cognome, "punteggio": punteggio, "utenteCorrente": utenteCorrente};
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

  group("getClassifica", ()
  {
    test("200: legge tutti i campi e manda GET col token", () async
    {
      final ds = creaDataSource(200, jsonEncode([voceJson()]), richieste);

      final voci = await ds.getClassifica();

      expect(voci.length, 1);
      expect(voci[0].posizione, 1);
      expect(voci[0].telefono, "3331234567");
      expect(voci[0].nome, "Mario");
      expect(voci[0].cognome, "Rossi");
      expect(voci[0].punteggio, 3);
      expect(voci[0].utenteCorrente, true);

      expect(richieste.single.method, "GET");
      expect(richieste.single.url.toString(), "http://test/api/classifica");
      expect(richieste.single.headers["Authorization"], "Bearer token-finto");
    });

    test("200: mantiene l'ordine del server e le posizioni a pari merito", () async
    {
      final ds = creaDataSource(200, jsonEncode([
        voceJson(posizione: 1, telefono: "1", punteggio: 9, utenteCorrente: false),
        voceJson(posizione: 2, telefono: "2", punteggio: 5, utenteCorrente: false),
        voceJson(posizione: 2, telefono: "3", punteggio: 5, utenteCorrente: true),
        voceJson(posizione: 4, telefono: "4", punteggio: 0, utenteCorrente: false),
      ]), richieste);

      final voci = await ds.getClassifica();

      expect(voci.map((v) => v.telefono).toList(), ["1", "2", "3", "4"]);
      expect(voci.map((v) => v.posizione).toList(), [1, 2, 2, 4]);
      expect(voci.map((v) => v.utenteCorrente).toList(), [false, false, true, false]);
    });

    test("200 con lista vuota: restituisce una lista vuota", () async
    {
      final ds = creaDataSource(200, "[]", richieste);

      expect(await ds.getClassifica(), isEmpty);
    });

    test("500: ErroreGenericoServer", () async
    {
      final ds = creaDataSource(500, jsonEncode({"timestamp": "2026-11-02T10:00:00", "status": 500, "errore": "Errore interno"}), richieste);

      await expectLater(ds.getClassifica(), throwsA(isA<ErroreGenericoServer>()));
    });

    test("risposta senza body (es. token scaduto): ErroreGenericoServer", () async
    {
      final ds = creaDataSource(403, "", richieste);

      await expectLater(ds.getClassifica(), throwsA(isA<ErroreGenericoServer>()));
    });

    test("il repository restituisce le voci del data source", () async
    {
      final ds = creaDataSource(200, jsonEncode([voceJson()]), richieste);

      final voci = await UtenteRepoImpl(dsUtente: ds).getClassifica();

      expect(voci.single.nome, "Mario");
    });
  });

  group("login", ()
  {
    test("salva nome e cognome con gli altri dati dell'utente", () async
    {
      final ds = creaDataSource(200, jsonEncode({"telefono": "3339998887", "nome": "Paola", "cognome": "Neri", "dataNascita": "1990-01-01", "isAdmin": true, "livello": 2.5, "token": "jwt-nuovo"}), richieste);

      await ds.login("3339998887", "segreta");

      final preferenze = sl<SharedPreferences>();
      expect(preferenze.getString("nome"), "Paola");
      expect(preferenze.getString("cognome"), "Neri");
      expect(preferenze.getBool("isAdmin"), true);
      expect(preferenze.getBool("isLogged"), true);
      expect(preferenze.getString("telefono"), "3339998887");
      expect(preferenze.getString("jwt"), "jwt-nuovo");
    });
  });

  group("logout", ()
  {
    final chiaviDelLogin = ["isLogged", "jwt", "isAdmin", "telefono", "nome", "cognome"];

    Future<void> preparaPreferenze() async
    {
      await sl.reset();
      SharedPreferences.setMockInitialValues({
        "isLogged": true,
        "jwt": "token-finto",
        "isAdmin": true,
        "telefono": "3331234567",
        "nome": "Mario",
        "cognome": "Rossi",
        "chiaveEstranea": "resta",
        "numeroEstraneo": 3,
      });
      sl.registerSingleton<SharedPreferences>(await SharedPreferences.getInstance());
    }

    test("toglie le 6 chiavi del login e non chiama il server", () async
    {
      await preparaPreferenze();
      final ds = creaDataSource(500, "", richieste);

      await ds.logout();

      final preferenze = sl<SharedPreferences>();
      for(final chiave in chiaviDelLogin)
      {
        expect(preferenze.containsKey(chiave), false, reason: chiave);
      }
      expect(richieste, isEmpty);
    });

    test("le chiavi estranee restano intatte", () async
    {
      await preparaPreferenze();
      final ds = creaDataSource(500, "", richieste);

      await ds.logout();

      final preferenze = sl<SharedPreferences>();
      expect(preferenze.getString("chiaveEstranea"), "resta");
      expect(preferenze.getInt("numeroEstraneo"), 3);
    });

    test("il repository passa dal data source", () async
    {
      await preparaPreferenze();
      final ds = creaDataSource(500, "", richieste);

      await UtenteRepoImpl(dsUtente: ds).logout();

      expect(sl<SharedPreferences>().containsKey("jwt"), false);
    });

    test("senza login fatto non da errori", () async
    {
      final ds = creaDataSource(500, "", richieste);
      await sl<SharedPreferences>().remove("jwt");

      await ds.logout();

      expect(sl<SharedPreferences>().containsKey("telefono"), false);
    });
  });

  group("eliminaAccount", ()
  {
    final chiaviDelLogin = ["isLogged", "jwt", "isAdmin", "telefono", "nome", "cognome"];

    Future<void> preparaPreferenze() async
    {
      await sl.reset();
      SharedPreferences.setMockInitialValues({
        "isLogged": true,
        "jwt": "token-finto",
        "isAdmin": false,
        "telefono": "3331234567",
        "nome": "Mario",
        "cognome": "Rossi",
        "chiaveEstranea": "resta",
      });
      sl.registerSingleton<SharedPreferences>(await SharedPreferences.getInstance());
    }

    test("204: manda DELETE col token su /api/utenti/me e toglie le chiavi del login", () async
    {
      await preparaPreferenze();
      final ds = creaDataSource(204, "", richieste);

      await ds.eliminaAccount();

      expect(richieste.single.method, "DELETE");
      expect(richieste.single.url.toString(), "http://test/api/utenti/me");
      expect(richieste.single.headers["Authorization"], "Bearer token-finto");
      final preferenze = sl<SharedPreferences>();
      for(final chiave in chiaviDelLogin)
      {
        expect(preferenze.containsKey(chiave), false, reason: chiave);
      }
      expect(preferenze.getString("chiaveEstranea"), "resta");
    });

    test("il repository passa dal data source", () async
    {
      await preparaPreferenze();
      final ds = creaDataSource(204, "", richieste);

      await UtenteRepoImpl(dsUtente: ds).eliminaAccount();

      expect(richieste.single.method, "DELETE");
      expect(sl<SharedPreferences>().containsKey("jwt"), false);
    });

    test("404: UtenteNonTrovato col messaggio del server, le chiavi restano", () async
    {
      await preparaPreferenze();
      final ds = creaDataSource(404, jsonEncode({"timestamp": "2026-11-07T10:00:00", "status": 404, "errore": "Utente non trovato"}), richieste);

      await expectLater(ds.eliminaAccount(), throwsA(isA<UtenteNonTrovato>().having((e) => e.messaggio, "messaggio", "Utente non trovato")));
      expect(sl<SharedPreferences>().getString("jwt"), "token-finto");
      expect(sl<SharedPreferences>().getBool("isLogged"), true);
    });

    test("500: ErroreGenericoServer, le chiavi restano", () async
    {
      await preparaPreferenze();
      final ds = creaDataSource(500, jsonEncode({"timestamp": "2026-11-07T10:00:00", "status": 500, "errore": "boom"}), richieste);

      await expectLater(ds.eliminaAccount(), throwsA(isA<ErroreGenericoServer>()));
      expect(sl<SharedPreferences>().getString("jwt"), "token-finto");
    });

    test("risposta senza body (es. 401 col token scaduto): ErroreGenericoServer", () async
    {
      await preparaPreferenze();
      final ds = creaDataSource(401, "", richieste);

      await expectLater(ds.eliminaAccount(), throwsA(isA<ErroreGenericoServer>()));
      expect(sl<SharedPreferences>().getString("jwt"), "token-finto");
    });
  });
}
