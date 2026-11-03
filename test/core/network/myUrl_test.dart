import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thepadel/core/network/myUrl.dart';

void main()
{
  TestWidgetsFlutterBinding.ensureInitialized();

  //i test dei data source usano urlDiTest: qui si controlla il file vero che legge l'app
  test("api-endpoints.json contiene l'endpoint del risultato", () async
  {
    final json = await rootBundle.loadString("assets/json/api-endpoints.json");

    final url = MyUrl.fromJsom(jsonDecode(json) as Map<String, dynamic>);

    expect(url.PartiteRisultato, "/api/partite/{id}/risultato");
  });

  test("api-endpoints.json contiene l'endpoint della classifica", () async
  {
    final json = await rootBundle.loadString("assets/json/api-endpoints.json");

    final url = MyUrl.fromJsom(jsonDecode(json) as Map<String, dynamic>);

    expect(url.Classifica, "/api/classifica");
  });

  test("api-endpoints.json contiene gli endpoint dell'area admin", () async
  {
    final json = await rootBundle.loadString("assets/json/api-endpoints.json");

    final url = MyUrl.fromJsom(jsonDecode(json) as Map<String, dynamic>);

    expect(url.AdminPartite, "/api/admin/partite?data={data}");
    expect(url.AdminAvvisi, "/api/admin/avvisi");
    expect(url.AdminUtenti, "/api/admin/utenti?cerca={cerca}");
    expect(url.AdminLivello, "/api/admin/utenti/{telefono}/livello");
    expect(url.AdminPartecipanti, "/api/admin/partite/{id}/partecipanti");
    expect(url.AdminRisultato, "/api/admin/partite/{id}/risultato");
    expect(url.AdminStato, "/api/admin/partite/{id}/stato");
    expect(url.AdminAnnulla, "/api/admin/partite/{id}/annulla");
  });
}
