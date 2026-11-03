import 'package:shared_preferences/shared_preferences.dart';
import 'package:thepadel/core/di/depInjection.dart';
import 'package:thepadel/core/network/client.dart';
import 'package:thepadel/core/network/myUrl.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/dataLayer/model/avvisoAdminModel.dart';
import 'package:thepadel/dataLayer/model/dettaglioPartitaModel.dart';
import 'package:thepadel/dataLayer/model/partiteCampoAdminModel.dart';
import 'package:thepadel/dataLayer/model/utenteAdminModel.dart';
import 'package:thepadel/domainLayer/enetity/setPartita.dart';

class DataSourceAdmin{

  //attributi
  final Client c;
  final MyUrl elencoUrl;

  //metodi
  DataSourceAdmin({required this.c, required this.elencoUrl});

  Future<List<PartiteCampoAdminModel>> getPartiteDelGiorno(DateTime data) async
  {
    String token = sl<SharedPreferences>().getString("jwt")!;
    String dataFormattata = "${data.year.toString().padLeft(4,'0')}-${data.month.toString().padLeft(2,'0')}-${data.day.toString().padLeft(2,'0')}";
    dynamic res = await c.get(elencoUrl.BaseUrl + elencoUrl.AdminPartite.replaceFirst("{data}", dataFormattata), token: token);

    if(res is List) //BUON FINE, c'e un elemento per ogni campo anche se non ha partite
    {
      return res.map((e) => PartiteCampoAdminModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    else
    {
      throw _erroreDaRisposta(res);
    }
  }

  Future<List<AvvisoAdminModel>> getAvvisi() async
  {
    String token = sl<SharedPreferences>().getString("jwt")!;
    dynamic res = await c.get(elencoUrl.BaseUrl + elencoUrl.AdminAvvisi, token: token);

    if(res is List) //BUON FINE, se non ci sono avvisi arriva una lista vuota
    {
      return res.map((e) => AvvisoAdminModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    else
    {
      throw _erroreDaRisposta(res);
    }
  }

  Future<List<UtenteAdminModel>> getUtenti(String cerca) async
  {
    String token = sl<SharedPreferences>().getString("jwt")!;
    //il testo della ricerca puo contenere spazi o accenti, quindi va codificato prima di metterlo nell'url
    String url = elencoUrl.BaseUrl + elencoUrl.AdminUtenti.replaceFirst("{cerca}", Uri.encodeQueryComponent(cerca));
    dynamic res = await c.get(url, token: token);

    if(res is List) //BUON FINE, se nessun utente corrisponde alla ricerca arriva una lista vuota
    {
      return res.map((e) => UtenteAdminModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    else
    {
      throw _erroreDaRisposta(res);
    }
  }

  Future<UtenteAdminModel> cambiaLivello(String telefono, double livello) async
  {
    String token = sl<SharedPreferences>().getString("jwt")!;
    Map<String, dynamic> body = {"livello": livello};
    dynamic res = await c.put(elencoUrl.BaseUrl + elencoUrl.AdminLivello.replaceFirst("{telefono}", telefono), body, token: token);

    if(res is Map<String, dynamic> && res.containsKey("telefono")) //BUON FINE, il server restituisce l'utente aggiornato
    {
      return UtenteAdminModel.fromJson(res);
    }
    else
    {
      throw _erroreDaRisposta(res);
    }
  }

  Future<DettaglioPartitaModel> modificaPartecipanti(int idPartita, List<String> telefoni) async
  {
    String token = sl<SharedPreferences>().getString("jwt")!;
    Map<String, dynamic> body = {"telefoni": telefoni};
    dynamic res = await c.put(elencoUrl.BaseUrl + elencoUrl.AdminPartecipanti.replaceFirst("{id}", idPartita.toString()), body, token: token);

    return _leggiDettaglio(res);
  }

  Future<DettaglioPartitaModel> modificaRisultato(int idPartita, List<int> squadra1, List<int> squadra2, List<SetPartita> set) async
  {
    String token = sl<SharedPreferences>().getString("jwt")!;

    //i set sono entity, il body invece vuole una lista di mappe con i game delle due squadre
    List<Map<String, dynamic>> setJson = [];
    for (SetPartita s in set)
    {
      setJson.add({"squadra1": s.squadra1, "squadra2": s.squadra2});
    }
    Map<String, dynamic> body = {"squadra1": squadra1, "squadra2": squadra2, "set": setJson};

    dynamic res = await c.put(elencoUrl.BaseUrl + elencoUrl.AdminRisultato.replaceFirst("{id}", idPartita.toString()), body, token: token);

    return _leggiDettaglio(res);
  }

  Future<DettaglioPartitaModel> modificaStato(int idPartita, String stato) async
  {
    String token = sl<SharedPreferences>().getString("jwt")!;
    Map<String, dynamic> body = {"stato": stato};
    dynamic res = await c.put(elencoUrl.BaseUrl + elencoUrl.AdminStato.replaceFirst("{id}", idPartita.toString()), body, token: token);

    return _leggiDettaglio(res);
  }

  Future<DettaglioPartitaModel> annullaPartita(int idPartita) async
  {
    String token = sl<SharedPreferences>().getString("jwt")!;
    //l'endpoint non vuole un body, ma il nostro Client.post lo richiede: passo una mappa vuota
    dynamic res = await c.post(elencoUrl.BaseUrl + elencoUrl.AdminAnnulla.replaceFirst("{id}", idPartita.toString()), {}, token: token);

    return _leggiDettaglio(res);
  }

  //le quattro operazioni sulla partita rispondono tutte con il dettaglio aggiornato
  DettaglioPartitaModel _leggiDettaglio(dynamic res)
  {
    if(res is Map<String, dynamic> && res.containsKey("posti")) //BUON FINE, solo il dettaglio ha la lista dei posti
    {
      return DettaglioPartitaModel.fromJson(res);
    }
    else
    {
      throw _erroreDaRisposta(res);
    }
  }

  //tutti gli endpoint admin usano gli stessi codici, quindi la scelta dell'eccezione sta in un posto solo
  Exception _erroreDaRisposta(dynamic res)
  {
    if(res is Map<String, dynamic> && res.containsKey("errore"))
    {
      int status = res['status'] as int;

      if(status == 404) //PARTITA O UTENTE INESISTENTE, il messaggio del server dice quale dei due
      {
        return PartitaNonTrovata(messaggio: res['errore']);
      }
      else if(status == 400 || status == 403 || status == 409) //DATI NON VALIDI, NON ADMIN O REGOLA VIOLATA
      {
        return OperazioneRifiutata(messaggio: res['errore']);
      }
    }

    //ALTRI ERRORI, compresa la risposta senza body (es. token scaduto)
    return ErroreGenericoServer();
  }
}
