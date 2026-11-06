import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thepadel/core/di/depInjection.dart';
import 'package:thepadel/core/network/client.dart';
import 'package:thepadel/dataLayer/dataSource/dataSourcePrenotazione.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/dataLayer/model/prenotazioneModel.dart';

import '../../fake/fakePrenotazioneRepo.dart';

//crea il data source con un client finto che risponde sempre con status e body indicati
//e salva l'ultima richiesta per poterla controllare
DataSourcePrenotazione creaDataSource(int status, String body, List<http.Request> richieste)
{
  final mock = MockClient((request) async
  {
    richieste.add(request);
    return http.Response(body, status, headers: {'content-type': 'application/json; charset=utf-8'});
  });
  return DataSourcePrenotazione(c: Client(c: mock), elencoUrl: urlDiTest());
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

  test("201: restituisce la prenotazione e manda la richiesta nel formato concordato", () async
  {
    final rispostaServer = jsonEncode({
      "id": 10,
      "idCampo": 3,
      "telefonoGiocatore1": "3331234567",
      "telefonoGiocatore2": null,
      "telefonoGiocatore3": null,
      "telefonoGiocatore4": null,
      "dataPrenotazione": "2026-11-02",
      "oraInizio": "18:30:00",
      "oraFine": "20:00:00",
      "stato": "CONFERMATA",
      "tipo": "PUBBLICA",
    });
    final ds = creaDataSource(201, rispostaServer, richieste);

    final PrenotazioneModel p = await ds.creaPartita(3, DateTime(2026, 11, 2), "18:30:00", "PUBBLICA");

    expect(p.id, 10);
    expect(p.idCampo, 3);
    expect(p.dataPrenotazione, DateTime(2026, 11, 2));
    expect(p.oraInizio.hour, 18);
    expect(p.oraInizio.minute, 30);
    expect(p.oraFine.hour, 20);
    expect(p.stato, "CONFERMATA");
    expect(p.tipo, "PUBBLICA");

    expect(richieste.length, 1);
    final r = richieste.first;
    expect(r.method, "POST");
    expect(r.url.toString(), "http://test/api/prenotazioni");
    expect(r.headers['Authorization'], "Bearer token-finto");
    expect(r.headers['Content-Type'], startsWith("application/json"));
    //i secondi dell'ora vengono tolti e mese e giorno hanno lo zero davanti
    expect(jsonDecode(r.body), {"idCampo": 3, "dataPrenotazione": "2026-11-02", "oraInizio": "18:30", "tipo": "PUBBLICA"});
  });

  test("201: un'ora gia nel formato HH:mm viene mandata cosi com'e", () async
  {
    final rispostaServer = jsonEncode({
      "id": 11,
      "idCampo": 1,
      "telefonoGiocatore1": "3331234567",
      "dataPrenotazione": "2026-01-05",
      "oraInizio": "09:00:00",
      "oraFine": "10:30:00",
      "stato": "CONFERMATA",
      "tipo": "PRIVATA",
    });
    final ds = creaDataSource(201, rispostaServer, richieste);

    final p = await ds.creaPartita(1, DateTime(2026, 1, 5), "09:00", "PRIVATA");

    expect(p.tipo, "PRIVATA");
    expect(jsonDecode(richieste.first.body), {"idCampo": 1, "dataPrenotazione": "2026-01-05", "oraInizio": "09:00", "tipo": "PRIVATA"});
  });

  test("201 con invitati: i telefoni partono nel campo invitati del body", () async
  {
    final rispostaServer = jsonEncode({
      "id": 12,
      "idCampo": 1,
      "telefonoGiocatore1": "3331234567",
      "telefonoGiocatore2": "3335550001",
      "dataPrenotazione": "2026-01-05",
      "oraInizio": "09:00:00",
      "oraFine": "10:30:00",
      "stato": "CREATA",
      "tipo": "PRIVATA",
    });
    final ds = creaDataSource(201, rispostaServer, richieste);

    final p = await ds.creaPartita(1, DateTime(2026, 1, 5), "09:00", "PRIVATA", invitati: ["3335550001", "3335550002"]);

    expect(p.id, 12);
    expect(jsonDecode(richieste.first.body), {"idCampo": 1, "dataPrenotazione": "2026-01-05", "oraInizio": "09:00", "tipo": "PRIVATA", "invitati": ["3335550001", "3335550002"]});
  });

  test("senza invitati il campo invitati non viene mandato", () async
  {
    final ds = creaDataSource(201, jsonEncode({"id": 13, "idCampo": 1, "telefonoGiocatore1": "3331234567", "dataPrenotazione": "2026-01-05", "oraInizio": "09:00:00", "oraFine": "10:30:00", "stato": "CREATA", "tipo": "PUBBLICA"}), richieste);

    await ds.creaPartita(1, DateTime(2026, 1, 5), "09:00", "PUBBLICA", invitati: []);

    expect((jsonDecode(richieste.first.body) as Map).containsKey("invitati"), false);
  });

  test("404 per invitato non trovato: lancia CampoInesistente con il messaggio del server", () async
  {
    final ds = creaDataSource(404, erroreServer(404, "Utente non trovato"), richieste);

    await expectLater(
      ds.creaPartita(1, DateTime(2026, 1, 5), "09:00", "PRIVATA", invitati: ["3330000000"]),
      throwsA(isA<CampoInesistente>().having((e) => e.messaggio, "messaggio", "Utente non trovato")),
    );
  });

  test("409 per invitato amministratore o oltre i 15 giorni: lancia SlotNonDisponibile col messaggio del server", () async
  {
    final ds = creaDataSource(409, erroreServer(409, "Non è possibile invitare un amministratore"), richieste);

    await expectLater(
      ds.creaPartita(1, DateTime(2026, 1, 5), "09:00", "PRIVATA", invitati: ["3330000000"]),
      throwsA(isA<SlotNonDisponibile>().having((e) => e.messaggio, "messaggio", "Non è possibile invitare un amministratore")),
    );
  });

  test("409 con errore: lancia SlotNonDisponibile con il messaggio del server", () async
  {
    final ds = creaDataSource(409, erroreServer(409, "Lo slot selezionato è già occupato"), richieste);

    await expectLater(
      ds.creaPartita(3, DateTime(2026, 11, 2), "18:30:00", "PUBBLICA"),
      throwsA(isA<SlotNonDisponibile>().having((e) => e.messaggio, "messaggio", "Lo slot selezionato è già occupato")),
    );
  });

  test("400 con errore: lancia PrenotazioneNonValida con il messaggio del server", () async
  {
    final ds = creaDataSource(400, erroreServer(400, "Il tipo della partita è obbligatorio"), richieste);

    await expectLater(
      ds.creaPartita(3, DateTime(2026, 11, 2), "18:30:00", "PUBBLICA"),
      throwsA(isA<PrenotazioneNonValida>().having((e) => e.messaggio, "messaggio", "Il tipo della partita è obbligatorio")),
    );
  });

  test("404 con errore: lancia CampoInesistente con il messaggio del server", () async
  {
    final ds = creaDataSource(404, erroreServer(404, "Campo non trovato"), richieste);

    await expectLater(
      ds.creaPartita(99, DateTime(2026, 11, 2), "18:30:00", "PUBBLICA"),
      throwsA(isA<CampoInesistente>().having((e) => e.messaggio, "messaggio", "Campo non trovato")),
    );
  });

  test("risposta senza body (es. 401/403): lancia ErroreGenericoServer", () async
  {
    final ds = creaDataSource(403, "", richieste);

    await expectLater(
      ds.creaPartita(3, DateTime(2026, 11, 2), "18:30:00", "PUBBLICA"),
      throwsA(isA<ErroreGenericoServer>()),
    );
  });

  test("altro status con errore (500): lancia ErroreGenericoServer", () async
  {
    final ds = creaDataSource(500, erroreServer(500, "Errore interno"), richieste);

    await expectLater(
      ds.creaPartita(3, DateTime(2026, 11, 2), "18:30:00", "PUBBLICA"),
      throwsA(isA<ErroreGenericoServer>()),
    );
  });

  group("getProssimaPartita", ()
  {
    test("risposta senza body (token scaduto): ErroreGenericoServer", ()
    {
      final ds = creaDataSource(401, '', richieste);

      expect(ds.getProssimaPartita(), throwsA(isA<ErroreGenericoServer>()));
    });

    test("404: nessuna partita in programma", () async
    {
      final ds = creaDataSource(404, erroreServer(404, "Nessuna prenotazione"), richieste);

      expect(await ds.getProssimaPartita(), isNull);
    });

    test("altro errore del server: ErroreGenericoServer", ()
    {
      final ds = creaDataSource(500, erroreServer(500, "Errore"), richieste);

      expect(ds.getProssimaPartita(), throwsA(isA<ErroreGenericoServer>()));
    });
  });
}
