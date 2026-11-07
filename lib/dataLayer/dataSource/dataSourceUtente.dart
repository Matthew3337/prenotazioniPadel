import 'package:shared_preferences/shared_preferences.dart';
import 'package:thepadel/core/di/depInjection.dart';
import 'package:thepadel/core/network/client.dart';
import 'package:thepadel/core/network/myUrl.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/dataLayer/model/utenteModel.dart';
import 'package:thepadel/dataLayer/model/voceClassificaModel.dart';

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

    if(res.containsKey("telefono")) //BUON FINE
    {
      await sl<SharedPreferences>().setBool('isLogged', true);
      await sl<SharedPreferences>().setBool('isAdmin', UtenteModel.fromJson(res).isAdmin);  
      await sl<SharedPreferences>().setString('telefono', UtenteModel.fromJson(res).telefono); 
      await sl<SharedPreferences>().setString('nome', UtenteModel.fromJson(res).nome); 
      await sl<SharedPreferences>().setString('cognome', UtenteModel.fromJson(res).cognome); 
      await sl<SharedPreferences>().setString('jwt', res['token']); 

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

  //il server non ha un endpoint di revoca del JWT: uscire significa dimenticare i dati salvati al login
  Future<void> logout() async
  {
    //isLogged va via per primo: se ci si fermasse a meta, all'avvio l'app non cercherebbe di aprire la home senza token
    await sl<SharedPreferences>().remove('isLogged');
    await sl<SharedPreferences>().remove('jwt');
    await sl<SharedPreferences>().remove('isAdmin');
    await sl<SharedPreferences>().remove('telefono');
    await sl<SharedPreferences>().remove('nome');
    await sl<SharedPreferences>().remove('cognome');
  }

  Future<void> eliminaAccount() async
  {
    String token = sl<SharedPreferences>().getString("jwt")!;
    dynamic res = await c.delete(elencoUrl.BaseUrl + elencoUrl.UtenteMe, token: token);

    if(res == null) //risposta senza body (es. token scaduto), non c'e niente da leggere
    {
      throw ErroreGenericoServer();
    }
    else if(!res.containsKey("errore") && (res['status'] as int) == 204) //BUON FINE, il server non manda nessun body
    {
      //l'account non esiste piu: tolgo i dati salvati esattamente come quando si esce
      await logout();
      return;
    }
    else if(res.containsKey("errore") && (res['status'] as int) == 404) //UTENTE GIA ELIMINATO O INESISTENTE
    {
      throw UtenteNonTrovato(messaggio: res['errore']);
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

    if(res.containsKey("telefono")) //BUON FINE
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

  Future<List<VoceClassificaModel>> getClassifica() async
  {
    String token = sl<SharedPreferences>().getString("jwt")!;
    dynamic res = await c.get(elencoUrl.BaseUrl + elencoUrl.Classifica, token: token);

    if(res is List) //BUON FINE
    {
      return res.map((e) => VoceClassificaModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    else
    { //se c'e un errore arriva una mappa (o niente), non c'e un caso specifico da gestire
      throw ErroreGenericoServer();
    }
  }
}