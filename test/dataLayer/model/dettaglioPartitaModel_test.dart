import 'package:flutter_test/flutter_test.dart';
import 'package:thepadel/dataLayer/model/dettaglioPartitaModel.dart';

Map<String, dynamic> dettaglioJson()
{
  return {
    "id": 7,
    "idCampo": 1,
    "nomeCampo": "Campo 1",
    "dataPartita": "2026-11-05",
    "oraInizio": "18:00:00",
    "oraFine": "19:30:00",
    "stato": "giocata",
    "tipo": "PUBBLICA",
    "telefonoCreatore": "3331234567",
    "posti": [
      <String, dynamic>{"tipo": "UTENTE", "telefono": "3331234567", "nome": "Mario", "cognome": "Rossi", "livello": 3, "confermata": true},
      <String, dynamic>{"tipo": "CAMPO", "telefono": null, "nome": null, "cognome": null, "livello": null, "confermata": false},
    ],
    "azioni": {"puoInvitare": false, "puoEliminare": false, "puoUscire": false, "puoConfermare": false, "puoRegistrareRisultato": false},
  };
}

void main()
{
  group("DettaglioPartitaModel campi del risultato", ()
  {
    test("server non ancora aggiornato: idPosto, squadra e risultato mancano e valgono null", ()
    {
      final dettaglio = DettaglioPartitaModel.fromJson(dettaglioJson());

      expect(dettaglio.posti[0].idPosto, isNull);
      expect(dettaglio.posti[0].squadra, isNull);
      expect(dettaglio.posti[1].idPosto, isNull);
      expect(dettaglio.posti[1].squadra, isNull);
      expect(dettaglio.risultato, isNull);
    });

    test("partita senza risultato: idPosto valorizzato, squadra e risultato null", ()
    {
      final json = dettaglioJson();
      json["posti"][0]["idPosto"] = 11;
      json["posti"][0]["squadra"] = null;
      json["posti"][1]["idPosto"] = 12;
      json["posti"][1]["squadra"] = null;
      json["risultato"] = null;

      final dettaglio = DettaglioPartitaModel.fromJson(json);

      expect(dettaglio.posti[0].idPosto, 11);
      expect(dettaglio.posti[1].idPosto, 12);
      expect(dettaglio.posti[0].squadra, isNull);
      expect(dettaglio.risultato, isNull);
    });

    test("partita con risultato: squadre, set, squadra dell'utente, esito e punti", ()
    {
      final json = dettaglioJson();
      json["posti"][0]["idPosto"] = 11;
      json["posti"][0]["squadra"] = 1;
      json["posti"][1]["idPosto"] = 12;
      json["posti"][1]["squadra"] = 2;
      json["risultato"] = {
        "set": [{"squadra1": 6, "squadra2": 4}, {"squadra1": 3, "squadra2": 6}, {"squadra1": 6, "squadra2": 2}],
        "squadraUtente": 2,
        "esito": "PERSA",
        "puntiAssegnati": -1,
      };

      final dettaglio = DettaglioPartitaModel.fromJson(json);

      expect(dettaglio.posti[0].squadra, 1);
      expect(dettaglio.posti[1].squadra, 2);
      expect(dettaglio.risultato!.set.length, 3);
      expect(dettaglio.risultato!.set[1].squadra1, 3);
      expect(dettaglio.risultato!.set[1].squadra2, 6);
      expect(dettaglio.risultato!.squadraUtente, 2);
      expect(dettaglio.risultato!.esito, "PERSA");
      expect(dettaglio.risultato!.puntiAssegnati, -1);
    });

    test("admin o utente senza squadra: squadraUtente, esito e punti null", ()
    {
      final json = dettaglioJson();
      json["risultato"] = {
        "set": [{"squadra1": 6, "squadra2": 4}, {"squadra1": 6, "squadra2": 2}],
        "squadraUtente": null,
        "esito": null,
        "puntiAssegnati": null,
      };

      final dettaglio = DettaglioPartitaModel.fromJson(json);

      expect(dettaglio.risultato!.set.length, 2);
      expect(dettaglio.risultato!.squadraUtente, isNull);
      expect(dettaglio.risultato!.esito, isNull);
      expect(dettaglio.risultato!.puntiAssegnati, isNull);
    });
  });

  group("DettaglioPartitaModel con un account eliminato", ()
  {
    test("telefonoCreatore null: il dettaglio si legge lo stesso", ()
    {
      final json = dettaglioJson();
      json["telefonoCreatore"] = null;

      final dettaglio = DettaglioPartitaModel.fromJson(json);

      expect(dettaglio.telefonoCreatore, isNull);
      expect(dettaglio.posti.length, 2);
      expect(dettaglio.id, 7);
    });

    test("posto con eliminato true: tipo UTENTE e dati tutti null", ()
    {
      final json = dettaglioJson();
      json["posti"][0] = <String, dynamic>{"tipo": "UTENTE", "telefono": null, "nome": null, "cognome": null, "livello": null, "confermata": true, "eliminato": true};

      final dettaglio = DettaglioPartitaModel.fromJson(json);

      expect(dettaglio.posti[0].eliminato, true);
      expect(dettaglio.posti[0].tipo, "UTENTE");
      expect(dettaglio.posti[0].telefono, isNull);
      expect(dettaglio.posti[0].nome, isNull);
      expect(dettaglio.posti[0].livello, isNull);
    });

    test("eliminato false o mancante: il posto non e eliminato", ()
    {
      final json = dettaglioJson();
      json["posti"][0]["eliminato"] = false;

      final dettaglio = DettaglioPartitaModel.fromJson(json);

      expect(dettaglio.posti[0].eliminato, false);
      expect(dettaglio.posti[1].eliminato, false);
    });
  });
}
