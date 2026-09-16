import 'package:http/http.dart' as http;

import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thepadel/bloc/autenticazione/authBloc.dart';
import 'package:thepadel/core/network/client.dart';
import 'package:thepadel/core/network/myUrl.dart';
import 'package:thepadel/dataLayer/dataSource/dataSourceUtente.dart';
import 'package:thepadel/repositoryImpl/utenteRepoImpl.dart';
import 'package:thepadel/useCase/authUseCase.dart';

final sl = GetIt.instance;

void init()
{
  sl.registerSingletonAsync<MyUrl>(() => MyUrl.loadUrl() ); //registro l oggetto degli url 

  sl.registerLazySingleton<http.Client>(() => http.Client()); //registro il client http di basso livello 

  sl.registerLazySingleton<Client>(()=> Client(c: sl())); //registro il client http di alto livello che dipende da quello a basso livello

  sl.registerSingletonWithDependencies<DataSourceUtente>(() => DataSourceUtente(c: sl(), elencoUrl: sl()), dependsOn: [MyUrl]); //registro il datasource passandogli i due oggetti gia registrati, essendo una registrazione async quella di myUrl devo usare dependsOn

  sl.registerLazySingleton<UtenteRepoImpl>(() => UtenteRepoImpl(dsUtente: sl()));

  sl.registerSingletonAsync( () =>  SharedPreferences.getInstance());

  sl.registerLazySingleton<LoginUseCase>(() => LoginUseCase(repo: sl()));

  sl.registerLazySingleton<RegistrazioneUseCase>(() => RegistrazioneUseCase(repo: sl()));

  sl.registerFactory(() => AuthBloc(loginUseCase: sl(), registrazioneUseCase: sl())); //registro solo il bloc non gli eventi o gli stati 
}