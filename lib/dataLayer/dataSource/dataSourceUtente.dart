import 'package:shared_preferences/shared_preferences.dart';
import 'package:thepadel/core/di/depInjection.dart';
import 'package:thepadel/core/network/client.dart';
import 'package:thepadel/core/network/myUrl.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/dataLayer/model/utenteModel.dart';

class DataSourceUtente{

  //attributi 
  final Client c;
  final MyUrl elencoUrl;

  //metodi 
  DataSourceUtente({required this.c, required this.elencoUrl});

  Future<UtenteModel> login(String telefono, String password) async
  {
    Map<String, String> body = {"telefono" : telefono, "password" : password};
    Map<String, dynamic> res = await c.post(elencoUrl.BaseUrl + elencoUrl.AuthLogin, body );

    if(res.containsKey("id")) //BUON FINE
    {
      await sl<SharedPreferences>().setBool('isLogged', true);
      await sl<SharedPreferences>().setBool('isAdmin', UtenteModel.fromJson(res).isAdmin);   
      return UtenteModel.fromJson(res);
    } 
    else if(res.containsKey("errore") && (res['status'] as int) == 401) //telefono o password sbagliata 
    {
      throw TelOPasswordErrata();
    } 
    else 
    { //ALTRI ERRORI 
      throw ErroreGenericoServer();
    }
  }

  Future<int> registrazione(String nome, String cognome, String telefono, DateTime dataNascita, String password) async
  {
    String dataFormattata = "${dataNascita.year.toString().padLeft(4,'0')}-${dataNascita.month.toString().padLeft(2,'0')}-${dataNascita.day.toString().padLeft(2,'0')}";
    Map<String, dynamic> body = {"nome" : nome, "cognome" : cognome, "telefono" : telefono, "dataNascita" : dataFormattata, "password" : password};
    Map<String, dynamic> res = await c.post(elencoUrl.BaseUrl + elencoUrl.AuthRegister, body);

    if(res.containsKey("id")) //BUON FINE
    {
      return 1;
    }
    else if(res.containsKey("errore") && (res['status'] as int) == 400 ) //DATA DI NASCITA NON VALIDA 
    {
      throw DataNonValida();
    }
    else if(res.containsKey("errore") && (res['status'] as int) == 409 ) //TELEFONO GIA REGISTRATO
    {
      throw TelefonoDuplicatoException();
    }
    else 
    { //ALTRI ERRORI 
      throw ErroreGenericoServer();
    }

  }
}