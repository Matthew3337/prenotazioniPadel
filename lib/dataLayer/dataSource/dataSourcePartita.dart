import 'package:shared_preferences/shared_preferences.dart';
import 'package:thepadel/core/di/depInjection.dart';
import 'package:thepadel/core/network/client.dart';
import 'package:thepadel/core/network/myUrl.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/dataLayer/model/dettaglioPartitaModel.dart';
import 'package:thepadel/dataLayer/model/partitaInvitoModel.dart';
import 'package:thepadel/dataLayer/model/partitaPubblicaModel.dart';
import 'package:thepadel/dataLayer/model/partitaStoricoModel.dart';
import 'package:thepadel/dataLayer/model/utenteInvitabileModel.dart';

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

  Future<List<PartitaPubblicaModel>> getPartitePubbliche() async
  {
    String token = sl<SharedPreferences>().getString("jwt")!;
    dynamic res = await c.get(elencoUrl.BaseUrl + elencoUrl.PartitePubbliche, token: token);

    if(res is List) //BUON FINE, se non ci sono partite arriva una lista vuota
    {
      return res.map((e) => PartitaPubblicaModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    else
    { //se c'e un errore arriva una mappa (o niente), non c'e un caso specifico da gestire
      throw ErroreGenericoServer();
    }
  }

  Future<DettaglioPartitaModel> entraInPartita(int idPartita) async
  {
    String token = sl<SharedPreferences>().getString("jwt")!;
    //l'endpoint non vuole un body, ma il nostro Client.post lo richiede: passo una mappa vuota
    dynamic res = await c.post(elencoUrl.BaseUrl + elencoUrl.PartiteEntra.replaceFirst("{id}", idPartita.toString()), {}, token: token);

    if(res == null) //risposta senza body (es. token scaduto), non c'e niente da leggere
    {
      throw ErroreGenericoServer();
    }
    else if(res.containsKey("posti")) //BUON FINE, il server restituisce il dettaglio gia aggiornato
    {
      return DettaglioPartitaModel.fromJson(res);
    }
    else if(res.containsKey("errore") && (res['status'] as int) == 404) //PARTITA INESISTENTE O NON PIU VISIBILE
    {
      throw PartitaNonTrovata(messaggio: res['errore']);
    }
    else if(res.containsKey("errore") && (res['status'] as int) == 409) //INGRESSO RIFIUTATO, il messaggio dice quale regola e stata violata
    {
      throw IngressoRifiutato(messaggio: res['errore']);
    }
    else
    { //ALTRI ERRORI, compreso il 403 dell'admin che non puo entrare
      throw ErroreGenericoServer();
    }
  }

  Future<void> eliminaPartita(int idPartita) async
  {
    String token = sl<SharedPreferences>().getString("jwt")!;
    dynamic res = await c.delete(elencoUrl.BaseUrl + elencoUrl.PartiteElimina.replaceFirst("{id}", idPartita.toString()), token: token);

    if(res == null) //risposta senza body (es. token scaduto), non c'e niente da leggere
    {
      throw ErroreGenericoServer();
    }
    else if(!res.containsKey("errore") && (res['status'] as int) == 204) //BUON FINE, il server non manda nessun body
    {
      return;
    }
    else if(res.containsKey("errore") && (res['status'] as int) == 404) //PARTITA INESISTENTE O NON VISIBILE
    {
      throw PartitaNonTrovata(messaggio: res['errore']);
    }
    else if(res.containsKey("errore") && ((res['status'] as int) == 403 || (res['status'] as int) == 409)) //NON E IL CREATORE, E L'ADMIN, PARTITA NON PIU APERTA O MENO DI 24 ORE ALL'INIZIO
    {
      throw OperazioneRifiutata(messaggio: res['errore']);
    }
    else
    { //ALTRI ERRORI
      throw ErroreGenericoServer();
    }
  }

  Future<void> esciDaPartita(int idPartita) async
  {
    String token = sl<SharedPreferences>().getString("jwt")!;
    //come per entra, l'endpoint non vuole un body: passo una mappa vuota
    dynamic res = await c.post(elencoUrl.BaseUrl + elencoUrl.PartiteEsci.replaceFirst("{id}", idPartita.toString()), {}, token: token);

    if(res == null) //risposta senza body (es. token scaduto), non c'e niente da leggere
    {
      throw ErroreGenericoServer();
    }
    else if(!res.containsKey("errore") && (res['status'] as int) == 204) //BUON FINE, il server non manda nessun body
    {
      return;
    }
    else if(res.containsKey("errore") && (res['status'] as int) == 404) //PARTITA INESISTENTE O NON VISIBILE
    {
      throw PartitaNonTrovata(messaggio: res['errore']);
    }
    else if(res.containsKey("errore") && ((res['status'] as int) == 403 || (res['status'] as int) == 409)) //E L'ADMIN, E IL CREATORE, NON PARTECIPA, PARTITA NON PIU APERTA O MENO DI 24 ORE ALL'INIZIO
    {
      throw OperazioneRifiutata(messaggio: res['errore']);
    }
    else
    { //ALTRI ERRORI
      throw ErroreGenericoServer();
    }
  }

  Future<List<PartitaStoricoModel>> getStorico() async
  {
    String token = sl<SharedPreferences>().getString("jwt")!;
    dynamic res = await c.get(elencoUrl.BaseUrl + elencoUrl.PartiteStorico, token: token);

    if(res is List) //BUON FINE, se l'utente non ha partite (o e l'admin) arriva una lista vuota
    {
      return res.map((e) => PartitaStoricoModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    else
    { //se c'e un errore arriva una mappa (o niente), non c'e un caso specifico da gestire
      throw ErroreGenericoServer();
    }
  }

  Future<List<UtenteInvitabileModel>> getInvitabili(int idPartita, String cerca) async
  {
    String token = sl<SharedPreferences>().getString("jwt")!;
    //il testo della ricerca puo contenere spazi o accenti, quindi va codificato prima di metterlo nell'url
    String url = elencoUrl.BaseUrl + elencoUrl.PartiteInvitabili.replaceFirst("{id}", idPartita.toString()).replaceFirst("{cerca}", Uri.encodeQueryComponent(cerca));
    dynamic res = await c.get(url, token: token);

    if(res == null) //risposta senza body (es. token scaduto), non c'e niente da leggere
    {
      throw ErroreGenericoServer();
    }
    else if(res is List) //BUON FINE, se nessun utente corrisponde alla ricerca arriva una lista vuota
    {
      return res.map((e) => UtenteInvitabileModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    else if(res.containsKey("errore") && (res['status'] as int) == 404) //PARTITA INESISTENTE O NON VISIBILE
    {
      throw PartitaNonTrovata(messaggio: res['errore']);
    }
    else if(res.containsKey("errore") && (res['status'] as int) == 403) //NON E IL CREATORE (O E L'ADMIN)
    {
      throw OperazioneRifiutata(messaggio: res['errore']);
    }
    else
    { //ALTRI ERRORI
      throw ErroreGenericoServer();
    }
  }

  Future<DettaglioPartitaModel> invitaUtente(int idPartita, String telefono) async
  {
    String token = sl<SharedPreferences>().getString("jwt")!;
    dynamic res = await c.post(elencoUrl.BaseUrl + elencoUrl.PartiteInvita.replaceFirst("{id}", idPartita.toString()), {"telefono": telefono}, token: token);

    if(res == null) //risposta senza body (es. token scaduto), non c'e niente da leggere
    {
      throw ErroreGenericoServer();
    }
    else if(res.containsKey("posti")) //BUON FINE, il server restituisce il dettaglio gia aggiornato con l'invitato
    {
      return DettaglioPartitaModel.fromJson(res);
    }
    else if(res.containsKey("errore") && (res['status'] as int) == 404) //PARTITA INESISTENTE O NON VISIBILE, OPPURE UTENTE NON TROVATO
    {
      throw PartitaNonTrovata(messaggio: res['errore']);
    }
    else if(res.containsKey("errore") && ((res['status'] as int) == 400 || (res['status'] as int) == 403 || (res['status'] as int) == 409)) //TELEFONO MANCANTE, NON E IL CREATORE, PARTITA AL COMPLETO, INVITI CHIUSI, GIA PARTECIPANTE, PARTITA NON PIU APERTA O UTENTE ADMIN
    {
      throw OperazioneRifiutata(messaggio: res['errore']);
    }
    else
    { //ALTRI ERRORI
      throw ErroreGenericoServer();
    }
  }

  Future<List<PartitaInvitoModel>> getInviti() async
  {
    String token = sl<SharedPreferences>().getString("jwt")!;
    dynamic res = await c.get(elencoUrl.BaseUrl + elencoUrl.PartiteInviti, token: token);

    if(res is List) //BUON FINE, se l'utente non ha inviti (o e l'admin) arriva una lista vuota
    {
      return res.map((e) => PartitaInvitoModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    else
    { //se c'e un errore arriva una mappa (o niente), non c'e un caso specifico da gestire
      throw ErroreGenericoServer();
    }
  }

}
