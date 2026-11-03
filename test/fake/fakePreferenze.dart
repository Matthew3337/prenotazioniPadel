import 'package:shared_preferences/shared_preferences.dart';
import 'package:thepadel/core/di/depInjection.dart';

//le pagine riconoscono il posto dell'utente dal telefono salvato al login: di default e quello del creatore di dettaglioDiTest
Future<void> registraPreferenzeDiTest({String telefono = "3331234567"}) async
{
  SharedPreferences.setMockInitialValues({"jwt": "token-finto", "telefono": telefono});
  sl.registerSingleton<SharedPreferences>(await SharedPreferences.getInstance());
}
