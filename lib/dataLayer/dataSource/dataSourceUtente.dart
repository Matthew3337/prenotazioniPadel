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

    if(res.containsKey("errore") && (res['status'] as int) == 409 ) //TELEFONO GIA REGISTRATO 
    {
      throw TelefonoDuplicatoException();
    }
    else if(res.containsKey("id")) //BUON FINE
    {
      return UtenteModel.fromJson(res);
    }
    else { //ALTRI ERRORI 
      throw ErroreGenericoServer();
    }

  }
}