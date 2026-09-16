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

  Future<dynamic> _handleRequest(Future<http.Response> Function() request) async{
   
    final resp = await request().timeout(timeout);
    String bodyResp = resp.body;
    print(bodyResp); //DEBUG !!!!
    return bodyResp.isNotEmpty ? jsonDecode(bodyResp) : null;
   
  }


}
