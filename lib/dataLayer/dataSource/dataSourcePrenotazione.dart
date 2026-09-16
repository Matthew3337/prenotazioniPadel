import 'package:shared_preferences/shared_preferences.dart';
import 'package:thepadel/core/di/depInjection.dart';
import 'package:thepadel/core/network/client.dart';
import 'package:thepadel/core/network/myUrl.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/dataLayer/model/prenotazioneModel.dart';

class DataSourcePrenotazione{

  //attributi 
  final Client c;
  final MyUrl elencoUrl;

  //metodi 
  DataSourcePrenotazione({required this.c, required this.elencoUrl});

  Future<PrenotazioneModel?> getProssimaPartita() async
  {
    String telefono =  sl<SharedPreferences>().getString("telefono")!;
    String token = sl<SharedPreferences>().getString("jwt")!;

    Map<String, dynamic> res = await  c.get(elencoUrl.BaseUrl + elencoUrl.PrenotazioniProssima + telefono);

    if(res.containsKey("id")) //SUCCESSO PRENOTAZIONE TROVATA 
    {
      return PrenotazioneModel.fromJson(res);
    }
    else if(res["status"] == 404) //NESSUNA PRENOTAZIONE FUTUTRA 
    {
      return null;
    }
    else  
    { 
      throw ErroreGenericoServer();
    }
  }

  
}