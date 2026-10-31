//gestisce la pagina di dettaglio di una partita, le azioni (invita, esci, conferma...) verranno aggiunte qui
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:thepadel/bloc/dettaglioPartita/dettaglioPartitaEvent.dart';
import 'package:thepadel/bloc/dettaglioPartita/dettaglioPartitaState.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/domainLayer/enetity/dettaglioPartita.dart';
import 'package:thepadel/useCase/dettaglioPartitaUseCase.dart';

class DettaglioPartitaBloc extends Bloc<DettaglioPartitaEvent, DettaglioPartitaState>{
  //attributi
  final DettaglioPartitaUseCase dettaglioPartitaUseCase;
  final EliminaPartitaUseCase eliminaPartitaUseCase;
  final EsciDaPartitaUseCase esciDaPartitaUseCase;

  //l'ultimo dettaglio caricato, serve agli stati di elimina ed esci per non far sparire la pagina
  DettaglioPartita? dettaglio;

  //metodi
  DettaglioPartitaBloc({required this.dettaglioPartitaUseCase, required this.eliminaPartitaUseCase, required this.esciDaPartitaUseCase}) : super(DettaglioPartitaInitial()) {
    on<DettaglioPartitaRichiesto>(_onDettaglioPartitaRichiesto);
    on<EliminaPartitaRichiesta>(_onEliminaPartitaRichiesta);
    on<EsciDaPartitaRichiesta>(_onEsciDaPartitaRichiesta);
  }

  Future<void> _onDettaglioPartitaRichiesto(DettaglioPartitaRichiesto evento, Emitter<DettaglioPartitaState> emit) async
  {
    emit(DettaglioPartitaLoading());
    await _caricaDettaglio(evento.idPartita, emit);
  }

  Future<void> _onEliminaPartitaRichiesta(EliminaPartitaRichiesta evento, Emitter<DettaglioPartitaState> emit) async
  {
    //i bottoni compaiono solo con il dettaglio a schermo, se non c'e ancora non ha senso procedere
    final dettaglioAttuale = dettaglio;
    if(dettaglioAttuale == null)
    {
      return;
    }

    emit(OperazioneInCorso(dettaglio: dettaglioAttuale));

    try
    {
      await eliminaPartitaUseCase.call(evento.idPartita);
      emit(PartitaEliminata());
      return;
    }
    on PartitaNonTrovata catch (e)
    {
      emit(OperazioneErrore(dettaglio: dettaglioAttuale, messaggio: e.messaggio));
    }
    on OperazioneRifiutata catch (e)
    {
      emit(OperazioneErrore(dettaglio: dettaglioAttuale, messaggio: e.messaggio));
    }
    on ErroreGenericoServer catch (e)
    {
      emit(OperazioneErrore(dettaglio: dettaglioAttuale, messaggio: e.messaggio));
    }

    //se il server ha rifiutato la partita e probabilmente cambiata (stato o azioni possibili),
    //quindi la ricarico; non emetto il Loading cosi il dettaglio resta a schermo finche non arriva quello nuovo
    await _caricaDettaglio(evento.idPartita, emit);
  }

  Future<void> _onEsciDaPartitaRichiesta(EsciDaPartitaRichiesta evento, Emitter<DettaglioPartitaState> emit) async
  {
    final dettaglioAttuale = dettaglio;
    if(dettaglioAttuale == null)
    {
      return;
    }

    emit(OperazioneInCorso(dettaglio: dettaglioAttuale));

    try
    {
      await esciDaPartitaUseCase.call(evento.idPartita);
      emit(UscitaCompletata());
      return;
    }
    on PartitaNonTrovata catch (e)
    {
      emit(OperazioneErrore(dettaglio: dettaglioAttuale, messaggio: e.messaggio));
    }
    on OperazioneRifiutata catch (e)
    {
      emit(OperazioneErrore(dettaglio: dettaglioAttuale, messaggio: e.messaggio));
    }
    on ErroreGenericoServer catch (e)
    {
      emit(OperazioneErrore(dettaglio: dettaglioAttuale, messaggio: e.messaggio));
    }

    //come per l'eliminazione, ricarico il dettaglio aggiornato senza passare dal Loading
    await _caricaDettaglio(evento.idPartita, emit);
  }

  Future<void> _caricaDettaglio(int idPartita, Emitter<DettaglioPartitaState> emit) async
  {
    try
    {
      dettaglio = await dettaglioPartitaUseCase.call(idPartita);
      emit(DettaglioPartitaCaricato(dettaglio: dettaglio!));
    }
    on PartitaNonTrovata catch (e)
    {
      emit(DettaglioPartitaErrore(messaggio: e.messaggio));
    }
    on ErroreGenericoServer catch (e)
    {
      emit(DettaglioPartitaErrore(messaggio: e.messaggio));
    }
  }
}
