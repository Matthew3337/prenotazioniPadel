import 'package:http/http.dart' as http;

import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thepadel/bloc/autenticazione/authBloc.dart';
import 'package:thepadel/bloc/bachecaAvvisi/bachecaAvvisiBloc.dart';
import 'package:thepadel/bloc/bachecaInviti/bachecaInvitiBloc.dart';
import 'package:thepadel/bloc/bachecaPubbliche/bachecaPubblicheBloc.dart';
import 'package:thepadel/bloc/cercaInvitati/cercaInvitatiBloc.dart';
import 'package:thepadel/bloc/classifica/classificaBloc.dart';
import 'package:thepadel/bloc/creaPartita/creaPartitaBloc.dart';
import 'package:thepadel/bloc/dettaglioAdmin/dettaglioAdminBloc.dart';
import 'package:thepadel/bloc/dettaglioPartita/dettaglioPartitaBloc.dart';
import 'package:thepadel/bloc/gestioneCampi/gestioneCampiBloc.dart';
import 'package:thepadel/bloc/gestioneLivelli/gestioneLivelliBloc.dart';
import 'package:thepadel/bloc/homePage/homeBloc.dart';
import 'package:thepadel/bloc/invitaUtenti/invitaUtentiBloc.dart';
import 'package:thepadel/bloc/livelloCampo/livelloCampoBloc.dart';
import 'package:thepadel/bloc/miePartite/miePartiteBloc.dart';
import 'package:thepadel/bloc/nuovaPartitaAdmin/nuovaPartitaAdminBloc.dart';
import 'package:thepadel/bloc/partiteGiorno/partiteGiornoBloc.dart';
import 'package:thepadel/bloc/prenota/prenotaBloc.dart';
import 'package:thepadel/bloc/registraRisultato/registraRisultatoBloc.dart';
import 'package:thepadel/bloc/storico/storicoBloc.dart';
import 'package:thepadel/core/network/client.dart';
import 'package:thepadel/core/network/myUrl.dart';
import 'package:thepadel/dataLayer/dataSource/dataSourceAdmin.dart';
import 'package:thepadel/dataLayer/dataSource/dataSourceCampo.dart';
import 'package:thepadel/dataLayer/dataSource/dataSourcePartita.dart';
import 'package:thepadel/dataLayer/dataSource/dataSourcePrenotazione.dart';
import 'package:thepadel/dataLayer/dataSource/dataSourceUtente.dart';
import 'package:thepadel/repositoryImpl/adminRepoImpl.dart';
import 'package:thepadel/repositoryImpl/campoRepoImpl.dart';
import 'package:thepadel/repositoryImpl/partitaRepoImpl.dart';
import 'package:thepadel/repositoryImpl/prenotazioneRepoImpl.dart';
import 'package:thepadel/repositoryImpl/utenteRepoImpl.dart';
import 'package:thepadel/useCase/adminUseCase.dart';
import 'package:thepadel/useCase/authUseCase.dart';
import 'package:thepadel/useCase/bachecaInvitiUseCase.dart';
import 'package:thepadel/useCase/bachecaPubblicheUseCase.dart';
import 'package:thepadel/useCase/classificaUseCase.dart';
import 'package:thepadel/useCase/creaPartitaUseCase.dart';
import 'package:thepadel/useCase/dettaglioPartitaUseCase.dart';
import 'package:thepadel/useCase/homeUseCase.dart';
import 'package:thepadel/useCase/invitaUtentiUseCase.dart';
import 'package:thepadel/useCase/miePartiteUseCase.dart';
import 'package:thepadel/useCase/prenotaUseCase.dart';
import 'package:thepadel/useCase/registraRisultatoUseCase.dart';
import 'package:thepadel/useCase/storicoUseCase.dart';

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

  sl.registerLazySingleton<LogoutUseCase>(() => LogoutUseCase(repo: sl()));

  sl.registerFactory(() => AuthBloc(loginUseCase: sl(), registrazioneUseCase: sl(), logoutUseCase: sl())); //registro solo il bloc non gli eventi o gli stati 

  sl.registerSingletonWithDependencies<DataSourcePrenotazione>(() => DataSourcePrenotazione(c: sl(), elencoUrl: sl()), dependsOn: [MyUrl]);

  sl.registerLazySingleton<PrenotazioneRepoImpl>(() => PrenotazioneRepoImpl(dsPrenotazione: sl()));

  sl.registerLazySingleton<ProssimaPartitaUseCase>(() => ProssimaPartitaUseCase(repo: sl()));

  sl.registerSingletonWithDependencies<DataSourceCampo>(() => DataSourceCampo(c: sl(), elencoUrl: sl()), dependsOn: [MyUrl]);

  sl.registerLazySingleton<CampoRepoImpl>(() => CampoRepoImpl(dsCampo: sl()));

  sl.registerLazySingleton<SlotDisponibiliUseCase>(() => SlotDisponibiliUseCase(repo: sl()));

  sl.registerLazySingleton<SlotOggiUseCase>(() => SlotOggiUseCase(repo: sl()));

  sl.registerLazySingleton<ClassificaUseCase>(() => ClassificaUseCase(repo: sl()));

  sl.registerFactory<ClassificaBloc>(() => ClassificaBloc(classificaUseCase: sl()));

  sl.registerFactory<HomeBloc>(()=> HomeBloc(prossimaPartitaUseCase: sl(), slotOggiUseCase: sl(), classificaUseCase: sl(), dettaglioPartitaUseCase: sl(), bachecaInvitiUseCase: sl(), partitePubblicheUseCase: sl()));

  sl.registerLazySingleton<CreaPartitaUseCase>(() => CreaPartitaUseCase(repo: sl()));

  sl.registerLazySingleton<SlotLiberiDataUseCase>(() => SlotLiberiDataUseCase(repo: sl()));

  sl.registerFactory<CreaPartitaBloc>(() => CreaPartitaBloc(creaPartitaUseCase: sl(), slotLiberiDataUseCase: sl()));

  sl.registerSingletonWithDependencies<DataSourcePartita>(() => DataSourcePartita(c: sl(), elencoUrl: sl()), dependsOn: [MyUrl]);

  sl.registerLazySingleton<PartitaRepoImpl>(() => PartitaRepoImpl(dsPartita: sl()));

  sl.registerLazySingleton<DettaglioPartitaUseCase>(() => DettaglioPartitaUseCase(repo: sl()));

  sl.registerLazySingleton<EliminaPartitaUseCase>(() => EliminaPartitaUseCase(repo: sl()));

  sl.registerLazySingleton<EsciDaPartitaUseCase>(() => EsciDaPartitaUseCase(repo: sl()));

  sl.registerLazySingleton<ConfermaPartitaUseCase>(() => ConfermaPartitaUseCase(repo: sl()));

  sl.registerLazySingleton<CambiaTipoUseCase>(() => CambiaTipoUseCase(repo: sl()));

  sl.registerFactory<DettaglioPartitaBloc>(() => DettaglioPartitaBloc(dettaglioPartitaUseCase: sl(), eliminaPartitaUseCase: sl(), esciDaPartitaUseCase: sl(), confermaPartitaUseCase: sl(), cambiaTipoUseCase: sl()));

  sl.registerLazySingleton<PartitePubblicheUseCase>(() => PartitePubblicheUseCase(repo: sl()));

  sl.registerLazySingleton<EntraInPartitaUseCase>(() => EntraInPartitaUseCase(repo: sl()));

  sl.registerFactory<BachecaPubblicheBloc>(() => BachecaPubblicheBloc(partitePubblicheUseCase: sl(), entraInPartitaUseCase: sl()));

  sl.registerLazySingleton<StoricoUseCase>(() => StoricoUseCase(repo: sl()));

  sl.registerFactory<StoricoBloc>(() => StoricoBloc(storicoUseCase: sl()));

  sl.registerLazySingleton<MiePartiteUseCase>(() => MiePartiteUseCase(repo: sl()));

  sl.registerFactory<MiePartiteBloc>(() => MiePartiteBloc(miePartiteUseCase: sl()));

  sl.registerLazySingleton<InvitabiliUseCase>(() => InvitabiliUseCase(repo: sl()));

  sl.registerLazySingleton<InvitaUtenteUseCase>(() => InvitaUtenteUseCase(repo: sl()));

  sl.registerFactory<InvitaUtentiBloc>(() => InvitaUtentiBloc(invitabiliUseCase: sl(), invitaUtenteUseCase: sl(), dettaglioPartitaUseCase: sl()));

  sl.registerLazySingleton<UtentiInvitabiliUseCase>(() => UtentiInvitabiliUseCase(repo: sl()));

  sl.registerFactory<CercaInvitatiBloc>(() => CercaInvitatiBloc(utentiInvitabiliUseCase: sl()));

  sl.registerLazySingleton<BachecaInvitiUseCase>(() => BachecaInvitiUseCase(repo: sl()));

  sl.registerLazySingleton<InvitiConStatoUseCase>(() => InvitiConStatoUseCase(repo: sl()));

  sl.registerFactory<BachecaInvitiBloc>(() => BachecaInvitiBloc(invitiConStatoUseCase: sl(), confermaPartitaUseCase: sl()));

  sl.registerLazySingleton<RegistraRisultatoUseCase>(() => RegistraRisultatoUseCase(repo: sl()));

  sl.registerFactory<RegistraRisultatoBloc>(() => RegistraRisultatoBloc(registraRisultatoUseCase: sl()));

  sl.registerSingletonWithDependencies<DataSourceAdmin>(() => DataSourceAdmin(c: sl(), elencoUrl: sl()), dependsOn: [MyUrl]);

  sl.registerLazySingleton<AdminRepoImpl>(() => AdminRepoImpl(dsAdmin: sl()));

  sl.registerLazySingleton<PartiteGiornoUseCase>(() => PartiteGiornoUseCase(repo: sl()));

  sl.registerLazySingleton<BachecaAvvisiUseCase>(() => BachecaAvvisiUseCase(repo: sl()));

  sl.registerLazySingleton<UtentiAdminUseCase>(() => UtentiAdminUseCase(repo: sl()));

  sl.registerLazySingleton<CambiaLivelloUseCase>(() => CambiaLivelloUseCase(repo: sl()));

  sl.registerLazySingleton<ModificaPartecipantiUseCase>(() => ModificaPartecipantiUseCase(repo: sl()));

  sl.registerLazySingleton<ModificaRisultatoUseCase>(() => ModificaRisultatoUseCase(repo: sl()));

  sl.registerLazySingleton<ModificaStatoUseCase>(() => ModificaStatoUseCase(repo: sl()));

  sl.registerLazySingleton<AnnullaPartitaUseCase>(() => AnnullaPartitaUseCase(repo: sl()));

  sl.registerLazySingleton<LivelloCampoUseCase>(() => LivelloCampoUseCase(repo: sl()));

  sl.registerLazySingleton<CambiaLivelloCampoUseCase>(() => CambiaLivelloCampoUseCase(repo: sl()));

  sl.registerLazySingleton<AggiungiGiocatoriCampoUseCase>(() => AggiungiGiocatoriCampoUseCase(repo: sl()));

  sl.registerLazySingleton<RimuoviGiocatoreCampoUseCase>(() => RimuoviGiocatoreCampoUseCase(repo: sl()));

  sl.registerLazySingleton<CreaPartitaAdminUseCase>(() => CreaPartitaAdminUseCase(repo: sl()));

  sl.registerLazySingleton<SalvaCampoUseCase>(() => SalvaCampoUseCase(repo: sl()));

  sl.registerLazySingleton<EliminaCampoUseCase>(() => EliminaCampoUseCase(repo: sl()));

  sl.registerFactory<PartiteGiornoBloc>(() => PartiteGiornoBloc(partiteGiornoUseCase: sl()));

  sl.registerFactory<BachecaAvvisiBloc>(() => BachecaAvvisiBloc(bachecaAvvisiUseCase: sl()));

  sl.registerFactory<GestioneLivelliBloc>(() => GestioneLivelliBloc(utentiAdminUseCase: sl(), cambiaLivelloUseCase: sl()));

  sl.registerFactory<DettaglioAdminBloc>(() => DettaglioAdminBloc(dettaglioPartitaUseCase: sl(), modificaPartecipantiUseCase: sl(), modificaRisultatoUseCase: sl(), modificaStatoUseCase: sl(), annullaPartitaUseCase: sl(), aggiungiGiocatoriCampoUseCase: sl(), rimuoviGiocatoreCampoUseCase: sl()));

  sl.registerFactory<LivelloCampoBloc>(() => LivelloCampoBloc(livelloCampoUseCase: sl(), cambiaLivelloCampoUseCase: sl()));

  sl.registerFactory<NuovaPartitaAdminBloc>(() => NuovaPartitaAdminBloc(creaPartitaAdminUseCase: sl()));

  sl.registerFactory<GestioneCampiBloc>(() => GestioneCampiBloc(listaCampiUseCase: sl(), salvaCampoUseCase: sl(), eliminaCampoUseCase: sl()));

  sl.registerLazySingleton<ListaCampiUseCase>(() => ListaCampiUseCase(repo: sl()));

  sl.registerFactory<PrenotaBloc>(() => PrenotaBloc(listaCampiUseCase: sl(), slotUseCase: sl(), miePartiteUseCase: sl()));
}