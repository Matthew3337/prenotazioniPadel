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
}
