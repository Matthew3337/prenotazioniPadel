import 'package:http/http.dart' as http;

import 'package:get_it/get_it.dart';
import 'package:thepadel/core/network/client.dart';
import 'package:thepadel/core/network/myUrl.dart';
import 'package:thepadel/dataLayer/dataSource/dataSourceUtente.dart';

final sl = GetIt.instance;

void init()
{
  sl.registerSingletonAsync<MyUrl>(() => MyUrl.loadUrl() ); //registro l oggetto degli url 

  sl.registerLazySingleton<http.Client>(() => http.Client()); //registro il client http di basso livello 

  sl.registerLazySingleton<Client>(()=> Client(c: sl())); //registro il client http di alto livello che dipende da quello a basso livello

  sl.registerSingletonWithDependencies<DataSourceUtente>(() => DataSourceUtente(c: sl(), elencoUrl: sl()), dependsOn: [MyUrl]); //registro il datasource passandogli i due oggetti gia registrati, essendo una registrazione async quella di myUrl devo usare dependsOn

}