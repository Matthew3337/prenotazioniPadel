import 'package:flutter_test/flutter_test.dart';
import 'package:thepadel/dataLayer/model/partitaInvitoModel.dart';
import 'package:thepadel/dataLayer/model/prenotazioneModel.dart';

Map<String, dynamic> prenotazioneJson()
{
  return {
    "id": 10,
    "idCampo": 3,
    "nomeCampo": "Campo Centrale",
    "telefonoGiocatore1": "3331234567",
    "telefonoGiocatore2": null,
    "telefonoGiocatore3": null,
    "telefonoGiocatore4": null,
    "dataPrenotazione": "2026-11-05",
    "oraInizio": "18:00:00",
    "oraFine": "19:30:00",
    "stato": "creata",
    "tipo": "PUBBLICA",
  };
}

void main()
{
  test("PrenotazioneModel: telefonoGiocatore1 presente si legge", ()
  {
    expect(PrenotazioneModel.fromJson(prenotazioneJson()).telefonoGiocatore1, "3331234567");
  });

  test("PrenotazioneModel: telefonoGiocatore1 null (creatore eliminato) non rompe la lettura", ()
  {
    final json = prenotazioneJson();
    json["telefonoGiocatore1"] = null;

    final prenotazione = PrenotazioneModel.fromJson(json);

    expect(prenotazione.telefonoGiocatore1, isNull);
    expect(prenotazione.id, 10);
    expect(prenotazione.stato, "creata");
  });

  test("PartitaInvitoModel: nome e cognome del creatore null restano null", ()
  {
    final invito = PartitaInvitoModel.fromJson({
      "id": 7,
      "idCampo": 1,
      "nomeCampo": "Campo 1",
      "dataPartita": "2026-11-05",
      "oraInizio": "18:00:00",
      "oraFine": "19:30:00",
      "stato": "creata",
      "tipo": "PRIVATA",
      "nomeCreatore": null,
      "cognomeCreatore": null,
    });

    expect(invito.nomeCreatore, isNull);
    expect(invito.cognomeCreatore, isNull);
    expect(invito.id, 7);
  });
}
