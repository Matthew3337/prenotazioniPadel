import 'package:thepadel/bloc/bachecaAvvisi/bachecaAvvisiBloc.dart';
import 'package:thepadel/bloc/bachecaInviti/bachecaInvitiBloc.dart';
import 'package:thepadel/bloc/bachecaPubbliche/bachecaPubblicheBloc.dart';
import 'package:thepadel/bloc/classifica/classificaBloc.dart';
import 'package:thepadel/bloc/creaPartita/creaPartitaBloc.dart';
import 'package:thepadel/bloc/dettaglioAdmin/dettaglioAdminBloc.dart';
import 'package:thepadel/bloc/dettaglioPartita/dettaglioPartitaBloc.dart';
import 'package:thepadel/bloc/gestioneCampi/gestioneCampiBloc.dart';
import 'package:thepadel/bloc/gestioneLivelli/gestioneLivelliBloc.dart';
import 'package:thepadel/bloc/homePage/homeBloc.dart';
import 'package:thepadel/bloc/invitaUtenti/invitaUtentiBloc.dart';
import 'package:thepadel/bloc/livelloCampo/livelloCampoBloc.dart';
import 'package:thepadel/bloc/nuovaPartitaAdmin/nuovaPartitaAdminBloc.dart';
import 'package:thepadel/bloc/partiteGiorno/partiteGiornoBloc.dart';
import 'package:thepadel/bloc/prenota/prenotaBloc.dart';
import 'package:thepadel/bloc/registraRisultato/registraRisultatoBloc.dart';
import 'package:thepadel/bloc/storico/storicoBloc.dart';
import 'package:thepadel/core/di/depInjection.dart';
import 'package:thepadel/useCase/adminUseCase.dart';
import 'package:thepadel/useCase/bachecaInvitiUseCase.dart';
import 'package:thepadel/useCase/bachecaPubblicheUseCase.dart';
import 'package:thepadel/useCase/classificaUseCase.dart';
import 'package:thepadel/useCase/creaPartitaUseCase.dart';
import 'package:thepadel/useCase/dettaglioPartitaUseCase.dart';
import 'package:thepadel/useCase/homeUseCase.dart';
import 'package:thepadel/useCase/invitaUtentiUseCase.dart';
import 'package:thepadel/useCase/prenotaUseCase.dart';
import 'package:thepadel/useCase/registraRisultatoUseCase.dart';
import 'package:thepadel/useCase/storicoUseCase.dart';

import 'fakeAdminRepo.dart';
import 'fakeCampoRepo.dart';
import 'fakePartitaRepo.dart';
import 'fakePrenotazioneRepo.dart';
import 'fakeUtenteRepo.dart';

//le pagine della barra si aprono l'una dall'altra: registro tutti i bloc che servono per navigare, tutti sopra i repository finti
void registraBlocDiTest({required FakePartitaRepo repoPartita, required FakeCampoRepo repoCampo, required FakePrenotazioneRepo repoPrenotazione, required FakeUtenteRepo repoUtente, FakeAdminRepo? repoAdmin})
{
  //i test che non guardano l'area admin non devono preparare il suo repository
  final FakeAdminRepo admin = repoAdmin ?? FakeAdminRepo();

  sl.registerFactory<HomeBloc>(() => HomeBloc(
    prossimaPartitaUseCase: ProssimaPartitaUseCase(repo: repoPrenotazione),
    slotOggiUseCase: SlotOggiUseCase(repo: repoCampo),
    classificaUseCase: ClassificaUseCase(repo: repoUtente),
    dettaglioPartitaUseCase: DettaglioPartitaUseCase(repo: repoPartita),
    bachecaInvitiUseCase: BachecaInvitiUseCase(repo: repoPartita),
    partitePubblicheUseCase: PartitePubblicheUseCase(repo: repoPartita),
  ));
  sl.registerFactory<PrenotaBloc>(() => PrenotaBloc(listaCampiUseCase: ListaCampiUseCase(repo: repoCampo), slotUseCase: SlotDisponibiliUseCase(repo: repoCampo), storicoUseCase: StoricoUseCase(repo: repoPartita)));
  sl.registerFactory<CreaPartitaBloc>(() => CreaPartitaBloc(creaPartitaUseCase: CreaPartitaUseCase(repo: repoPrenotazione), slotLiberiDataUseCase: SlotLiberiDataUseCase(repo: repoCampo)));
  sl.registerFactory<BachecaPubblicheBloc>(() => BachecaPubblicheBloc(partitePubblicheUseCase: PartitePubblicheUseCase(repo: repoPartita), entraInPartitaUseCase: EntraInPartitaUseCase(repo: repoPartita)));
  sl.registerFactory<BachecaInvitiBloc>(() => BachecaInvitiBloc(invitiConStatoUseCase: InvitiConStatoUseCase(repo: repoPartita), confermaPartitaUseCase: ConfermaPartitaUseCase(repo: repoPartita)));
  sl.registerFactory<StoricoBloc>(() => StoricoBloc(storicoUseCase: StoricoUseCase(repo: repoPartita)));
  sl.registerFactory<ClassificaBloc>(() => ClassificaBloc(classificaUseCase: ClassificaUseCase(repo: repoUtente)));
  sl.registerFactory<DettaglioPartitaBloc>(() => DettaglioPartitaBloc(dettaglioPartitaUseCase: DettaglioPartitaUseCase(repo: repoPartita), eliminaPartitaUseCase: EliminaPartitaUseCase(repo: repoPartita), esciDaPartitaUseCase: EsciDaPartitaUseCase(repo: repoPartita), confermaPartitaUseCase: ConfermaPartitaUseCase(repo: repoPartita)));
  sl.registerFactory<InvitaUtentiBloc>(() => InvitaUtentiBloc(invitabiliUseCase: InvitabiliUseCase(repo: repoPartita), invitaUtenteUseCase: InvitaUtenteUseCase(repo: repoPartita), dettaglioPartitaUseCase: DettaglioPartitaUseCase(repo: repoPartita)));
  sl.registerFactory<RegistraRisultatoBloc>(() => RegistraRisultatoBloc(registraRisultatoUseCase: RegistraRisultatoUseCase(repo: repoPartita)));
  sl.registerFactory<PartiteGiornoBloc>(() => PartiteGiornoBloc(partiteGiornoUseCase: PartiteGiornoUseCase(repo: admin)));
  sl.registerFactory<BachecaAvvisiBloc>(() => BachecaAvvisiBloc(bachecaAvvisiUseCase: BachecaAvvisiUseCase(repo: admin)));
  sl.registerFactory<GestioneLivelliBloc>(() => GestioneLivelliBloc(utentiAdminUseCase: UtentiAdminUseCase(repo: admin), cambiaLivelloUseCase: CambiaLivelloUseCase(repo: admin)));
  sl.registerFactory<DettaglioAdminBloc>(() => DettaglioAdminBloc(dettaglioPartitaUseCase: DettaglioPartitaUseCase(repo: repoPartita), modificaPartecipantiUseCase: ModificaPartecipantiUseCase(repo: admin), modificaRisultatoUseCase: ModificaRisultatoUseCase(repo: admin), modificaStatoUseCase: ModificaStatoUseCase(repo: admin), annullaPartitaUseCase: AnnullaPartitaUseCase(repo: admin), aggiungiGiocatoriCampoUseCase: AggiungiGiocatoriCampoUseCase(repo: admin), rimuoviGiocatoreCampoUseCase: RimuoviGiocatoreCampoUseCase(repo: admin)));
  sl.registerFactory<LivelloCampoBloc>(() => LivelloCampoBloc(livelloCampoUseCase: LivelloCampoUseCase(repo: admin), cambiaLivelloCampoUseCase: CambiaLivelloCampoUseCase(repo: admin)));
  sl.registerFactory<NuovaPartitaAdminBloc>(() => NuovaPartitaAdminBloc(creaPartitaAdminUseCase: CreaPartitaAdminUseCase(repo: admin)));
  sl.registerFactory<GestioneCampiBloc>(() => GestioneCampiBloc(listaCampiUseCase: ListaCampiUseCase(repo: repoCampo), salvaCampoUseCase: SalvaCampoUseCase(repo: repoCampo), eliminaCampoUseCase: EliminaCampoUseCase(repo: repoCampo)));
}
