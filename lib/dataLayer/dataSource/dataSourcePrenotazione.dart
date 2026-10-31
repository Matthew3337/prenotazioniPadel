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

    Map<String, dynamic> res = await  c.get(elencoUrl.BaseUrl + elencoUrl.PrenotazioniProssima + telefono, token: token);

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

  Future<PrenotazioneModel> creaPartita(int idCampo, DateTime data, String oraInizio, String tipo) async
  {
    String token = sl<SharedPreferences>().getString("jwt")!;
    String dataFormattata = "${data.year.toString().padLeft(4,'0')}-${data.month.toString().padLeft(2,'0')}-${data.day.toString().padLeft(2,'0')}";
    //il server vuole l'ora nel formato HH:mm, se lo slot arriva con i secondi (HH:mm:ss) li tolgo
    String oraFormattata = oraInizio.length > 5 ? oraInizio.substring(0, 5) : oraInizio;

    //i telefoni dei giocatori non si mandano: il creatore e l'utente del token
    Map<String, dynamic> body = {"idCampo" : idCampo, "dataPrenotazione" : dataFormattata, "oraInizio" : oraFormattata, "tipo" : tipo};
    dynamic res = await c.post(elencoUrl.BaseUrl + elencoUrl.PrenotazioniCreate, body, token: token);

    if(res == null) //risposta senza body (es. token scaduto), non c'e niente da leggere
    {
      throw ErroreGenericoServer();
    }
    else if(res.containsKey("id")) //BUON FINE, PARTITA CREATA
    {
      return PrenotazioneModel.fromJson(res);
    }
    else if(res.containsKey("errore") && (res['status'] as int) == 400) //DATI NON VALIDI
    {
      throw PrenotazioneNonValida(messaggio: res['errore']);
    }
    else if(res.containsKey("errore") && (res['status'] as int) == 404) //CAMPO INESISTENTE
    {
      throw CampoInesistente(messaggio: res['errore']);
    }
    else if(res.containsKey("errore") && (res['status'] as int) == 409) //SLOT OCCUPATO, FUORI ORARIO O NEL PASSATO
    {
      throw SlotNonDisponibile(messaggio: res['errore']);
    }
    else
    { //ALTRI ERRORI
      throw ErroreGenericoServer();
    }
  }

  
}