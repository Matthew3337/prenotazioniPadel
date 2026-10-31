import 'package:shared_preferences/shared_preferences.dart';
import 'package:thepadel/core/di/depInjection.dart';
import 'package:thepadel/core/network/client.dart';
import 'package:thepadel/core/network/myUrl.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/dataLayer/model/dettaglioPartitaModel.dart';

class DataSourcePartita{

  //attributi
  final Client c;
  final MyUrl elencoUrl;

  //metodi
  DataSourcePartita({required this.c, required this.elencoUrl});

  Future<DettaglioPartitaModel> getDettaglioPartita(int idPartita) async
  {
    String token = sl<SharedPreferences>().getString("jwt")!;
    dynamic res = await c.get(elencoUrl.BaseUrl + elencoUrl.PartiteDettaglio.replaceFirst("{id}", idPartita.toString()), token: token);

    if(res == null) //risposta senza body (es. token scaduto), non c'e niente da leggere
    {
      throw ErroreGenericoServer();
    }
    else if(res.containsKey("posti")) //BUON FINE, solo il dettaglio ha la lista dei posti
    {
      return DettaglioPartitaModel.fromJson(res);
    }
    else if(res.containsKey("errore") && (res['status'] as int) == 404) //PARTITA INESISTENTE O NON VISIBILE ALL'UTENTE
    {
      throw PartitaNonTrovata(messaggio: res['errore']);
    }
    else
    { //ALTRI ERRORI
      throw ErroreGenericoServer();
    }
  }

}
