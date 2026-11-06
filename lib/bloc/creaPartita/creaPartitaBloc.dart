//gestisce la pagina di riepilogo dello slot e la creazione della partita
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:thepadel/bloc/creaPartita/creaPartitaEvent.dart';
import 'package:thepadel/bloc/creaPartita/creaPartitaState.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/domainLayer/enetity/slotOrario.dart';
import 'package:thepadel/useCase/creaPartitaUseCase.dart';
import 'package:thepadel/useCase/eccezioniUseCase.dart';

class CreaPartitaBloc extends Bloc<CreaPartitaEvent, CreaPartitaState>{
  //attributi
  final CreaPartitaUseCase creaPartitaUseCase;
  final SlotLiberiDataUseCase slotLiberiDataUseCase;

  //metodi
  CreaPartitaBloc({required this.creaPartitaUseCase, required this.slotLiberiDataUseCase}) : super(CreaPartitaInitial()) {
    on<CreaPartitaRichiesta>(_onCreaPartitaRichiesta);
  }

  Future<void> _onCreaPartitaRichiesta(CreaPartitaRichiesta evento, Emitter<CreaPartitaState> emit) async
  {
    emit(CreaPartitaLoading());

    try
    {
      final prenotazione = await creaPartitaUseCase.call(evento.slot, evento.data, evento.tipo, invitati: evento.invitati);
      emit(CreaPartitaSuccess(prenotazione: prenotazione));
    }
    on TipoPartitaMancante catch (e)
    {
      emit(CreaPartitaErrore(messaggio: e.message));
    }
    on TroppiInvitati catch (e)
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
      final slotLiberi = await _caricaSlotLiberi(evento);
      emit(CreaPartitaSlotPreso(messaggio: e.messaggio, data: evento.data, slotLiberi: slotLiberi));
    }
    on ErroreGenericoServer catch (e)
    {
      emit(CreaPartitaErrore(messaggio: e.messaggio));
    }
    on Exception //timeout o rete assente: il Client li lascia passare cosi come sono, senza questo la pagina resterebbe ferma
    {
      emit(CreaPartitaErrore(messaggio: ErroreGenericoServer().messaggio));
    }
  }

  Future<List<SlotOrario>> _caricaSlotLiberi(CreaPartitaRichiesta evento) async
  {
    List<SlotOrario> slotLiberi = [];
    try
    {
      final slots = await slotLiberiDataUseCase.call(evento.data, DateTime.now());
      for(final slot in slots)
      {
        //lo slot appena rifiutato non va riproposto, anche se il server lo desse ancora per libero
        final eLoStesso = slot.idCampo == evento.slot.idCampo && slot.oraInizio == evento.slot.oraInizio;
        if(!eLoStesso)
        {
          slotLiberi.add(slot);
        }
      }
    }
    on Exception
    {
      //senza alternative la pagina puo comunque dire che lo slot e stato preso: la lista resta vuota
      slotLiberi = [];
    }
    return slotLiberi;
  }
}
