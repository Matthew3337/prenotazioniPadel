import 'dart:convert';

import 'package:http/http.dart' as http;
class Client {

  //attributi 
  final http.Client c;
  final Duration timeout;

  Client({required this.c,  this.timeout =  const Duration(seconds: 15)});

  //metodi 

  Future<dynamic> get(String url)
  {
    return _handleRequest(()=> c.get(Uri.parse(url)));
  }

  Future<dynamic> post(String url, Map<String, dynamic> body)
  {
    return _handleRequest(()=> c.post(Uri.parse(url), body: jsonEncode(body)));
  }

  Future<dynamic> _handleRequest(Future<http.Response> Function() request) async{
   
    final resp = await request().timeout(timeout);
    String bodyResp = resp.body;
    return bodyResp.isNotEmpty ? jsonDecode(bodyResp) : null;
   
  }


}
