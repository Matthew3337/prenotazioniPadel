//gestisce la pagina di riepilogo dello slot e la creazione della partita
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:thepadel/bloc/creaPartita/creaPartitaEvent.dart';
import 'package:thepadel/bloc/creaPartita/creaPartitaState.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/useCase/creaPartitaUseCase.dart';
import 'package:thepadel/useCase/eccezioniUseCase.dart';

class CreaPartitaBloc extends Bloc<CreaPartitaEvent, CreaPartitaState>{
  //attributi
  final CreaPartitaUseCase creaPartitaUseCase;

  //metodi
  CreaPartitaBloc({required this.creaPartitaUseCase}) : super(CreaPartitaInitial()) {
    on<CreaPartitaRichiesta>(_onCreaPartitaRichiesta);
  }

  Future<void> _onCreaPartitaRichiesta(CreaPartitaRichiesta evento, Emitter<CreaPartitaState> emit) async
  {
    emit(CreaPartitaLoading());

    try
    {
      final prenotazione = await creaPartitaUseCase.call(evento.slot, evento.data, evento.tipo);
      emit(CreaPartitaSuccess(prenotazione: prenotazione));
    }
    on TipoPartitaMancante catch (e)
    {
      emit(CreaPartitaErrore(messaggio: e.message));
    }
    on PrenotazioneNonValida catch (e)
    {
      emit(CreaPartitaErrore(messaggio: e.messaggio));
    }
    on CampoInesistente catch (e)
    {
      emit(CreaPartitaErrore(messaggio: e.messaggio));
    }
    on SlotNonDisponibile catch (e)
    {
      emit(CreaPartitaErrore(messaggio: e.messaggio));
    }
    on ErroreGenericoServer catch (e)
    {
      emit(CreaPartitaErrore(messaggio: e.messaggio));
    }
  }
}
