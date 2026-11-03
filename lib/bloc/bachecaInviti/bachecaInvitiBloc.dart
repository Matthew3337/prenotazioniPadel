//gestisce la bacheca degli inviti, cioe le partite in cui l'utente e stato aggiunto dal creatore, e la conferma dalla lista
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:thepadel/bloc/bachecaInviti/bachecaInvitiEvent.dart';
import 'package:thepadel/bloc/bachecaInviti/bachecaInvitiState.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/domainLayer/enetity/invitoBacheca.dart';
import 'package:thepadel/useCase/bachecaInvitiUseCase.dart';
import 'package:thepadel/useCase/dettaglioPartitaUseCase.dart';

class BachecaInvitiBloc extends Bloc<BachecaInvitiEvent, BachecaInvitiState>{
  //attributi
  final InvitiConStatoUseCase invitiConStatoUseCase;
  final ConfermaPartitaUseCase confermaPartitaUseCase;

  //l'ultima lista caricata, serve agli stati della conferma per non far sparire la bacheca
  List<InvitoBacheca> voci = [];

  //metodi
  BachecaInvitiBloc({required this.invitiConStatoUseCase, required this.confermaPartitaUseCase}) : super(BachecaInvitiInitial()) {
    on<BachecaInvitiRichiesta>(_onBachecaInvitiRichiesta);
    on<ConfermaInvitoRichiesta>(_onConfermaInvitoRichiesta);
  }

  Future<void> _onBachecaInvitiRichiesta(BachecaInvitiRichiesta evento, Emitter<BachecaInvitiState> emit) async
  {
    emit(BachecaInvitiLoading());

    try
    {
      voci = await invitiConStatoUseCase.call();
      emit(BachecaInvitiCaricata(voci: voci));
    }
    on ErroreGenericoServer catch (e)
    {
      emit(BachecaInvitiErrore(messaggio: e.messaggio));
    }
    on Exception //timeout o rete assente: senza questo la pagina resterebbe in caricamento per sempre
    {
      emit(BachecaInvitiErrore(messaggio: ErroreGenericoServer().messaggio));
    }
  }

  Future<void> _onConfermaInvitoRichiesta(ConfermaInvitoRichiesta evento, Emitter<BachecaInvitiState> emit) async
  {
    //lo stato indica un solo invito in corso, quindi una conferma per volta; senza lista non c'e niente da confermare
    if(state is! BachecaInvitiCaricata || state is ConfermaInvitoInCorso)
    {
      return;
    }

    emit(ConfermaInvitoInCorso(voci: voci, idPartita: evento.idPartita));

    try
    {
      final dettaglio = await confermaPartitaUseCase.call(evento.idPartita);

      List<InvitoBacheca> aggiornate = [];
      for(final voce in voci)
      {
        if(voce.partita.id == evento.idPartita)
        {
          aggiornate.add(InvitoBacheca(partita: voce.partita, puoConfermare: false, giaConfermato: true));
        }
        else
        {
          aggiornate.add(voce);
        }
      }
      voci = aggiornate;

      emit(ConfermaInvitoRiuscita(voci: voci, dettaglio: dettaglio));
    }
    on PartitaNonTrovata catch (e)
    {
      emit(ConfermaInvitoErrore(voci: voci, messaggio: e.messaggio));
    }
    on OperazioneRifiutata catch (e)
    {
      emit(ConfermaInvitoErrore(voci: voci, messaggio: e.messaggio));
    }
    on ErroreGenericoServer catch (e)
    {
      emit(ConfermaInvitoErrore(voci: voci, messaggio: e.messaggio));
    }
    on Exception //timeout o rete assente: senza questo l'invito resterebbe in corso per sempre
    {
      emit(ConfermaInvitoErrore(voci: voci, messaggio: ErroreGenericoServer().messaggio));
    }
  }
}
