import 'package:flutter_test/flutter_test.dart';
import 'package:thepadel/dataLayer/model/partitaPubblicaModel.dart';

Map<String, dynamic> partitaJson(Object? livelloCreatore)
{
  return {
    "id": 7,
    "idCampo": 1,
    "nomeCampo": "Campo 1",
    "dataPartita": "2026-11-05",
    "oraInizio": "18:00:00",
    "oraFine": "19:30:00",
    "nomeCreatore": "Mario",
    "cognomeCreatore": "Rossi",
    "livelloCreatore": livelloCreatore,
    "postiLiberi": 2,
  };
}

void main()
{
  group("PartitaPubblicaModel.fromJson livelloCreatore", ()
  {
    test("decimale: resta tale", ()
    {
      expect(PartitaPubblicaModel.fromJson(partitaJson(2.5)).livelloCreatore, 2.5);
    });

    test("intero: viene convertito in double", ()
    {
      final partita = PartitaPubblicaModel.fromJson(partitaJson(3));

      expect(partita.livelloCreatore, isA<double>());
      expect(partita.livelloCreatore, 3.0);
    });

    test("null, creatore admin: resta null e gli altri campi si leggono lo stesso", ()
    {
      final partita = PartitaPubblicaModel.fromJson(partitaJson(null));

      expect(partita.livelloCreatore, isNull);
      expect(partita.id, 7);
      expect(partita.nomeCreatore, "Mario");
      expect(partita.cognomeCreatore, "Rossi");
      expect(partita.postiLiberi, 2);
    });
  });
}
