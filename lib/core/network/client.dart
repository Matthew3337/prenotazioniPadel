import 'dart:convert';

import 'package:http/http.dart' as http;
class Client {

  //attributi 
  final http.Client c;
  final Duration timeout;

  Client({required this.c,  this.timeout =  const Duration(seconds: 15)});

  //metodi 

  Future<dynamic> get(String url, {String? token})
  {
     if(token != null)
    {
      return _handleRequest(()=> c.get(Uri.parse(url), headers: {'Authorization': 'Bearer $token'}));
    }
    else 
    {
      return _handleRequest(()=> c.get(Uri.parse(url)));
    } 
  }

  Future<dynamic> post(String url, Map<String, dynamic> body,{String? token})
  {
    if(token != null)
    {
      return _handleRequest(()=> c.post(Uri.parse(url), body: jsonEncode(body), headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'}));
    }
    else 
    {
      return _handleRequest(()=> c.post(Uri.parse(url), body: jsonEncode(body), headers: {'Content-Type': 'application/json'}));
    } 
  
  }

  Future<dynamic> put(String url, Map<String, dynamic> body,{String? token})
  {
    if(token != null)
    {
      return _handleRequest(()=> c.put(Uri.parse(url), body: jsonEncode(body), headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'}));
    }
    else 
    {
      return _handleRequest(()=> c.put(Uri.parse(url), body: jsonEncode(body), headers: {'Content-Type': 'application/json'}));
    } 
  }

  Future<dynamic> delete(String url, {String? token})
  {
    if(token != null)
    {
      return _handleRequest(()=> c.delete(Uri.parse(url), headers: {'Authorization': 'Bearer $token'}));
    }
    else 
    {
      return _handleRequest(()=> c.delete(Uri.parse(url)));
    } 
  }

  Future<dynamic> _handleRequest(Future<http.Response> Function() request) async{
   
    final resp = await request().timeout(timeout);
    //il 204 arriva senza body: restituisco una mappa con lo status, cosi chi chiama riesce a distinguerlo
    //dagli altri casi senza body (es. token scaduto) che continuano a restituire null
    if(resp.statusCode == 204)
    {
      return {"status": 204};
    }
    String bodyResp = resp.body;
    print(bodyResp); //DEBUG !!!!
    return bodyResp.isNotEmpty ? jsonDecode(bodyResp) : null;
   
  }


}
