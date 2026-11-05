//gestisce la creazione di una partita da parte dell'admin
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:thepadel/bloc/nuovaPartitaAdmin/nuovaPartitaAdminEvent.dart';
import 'package:thepadel/bloc/nuovaPartitaAdmin/nuovaPartitaAdminState.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/useCase/adminUseCase.dart';
import 'package:thepadel/useCase/eccezioniUseCase.dart';

class NuovaPartitaAdminBloc extends Bloc<NuovaPartitaAdminEvent, NuovaPartitaAdminState>{
  //attributi
  final CreaPartitaAdminUseCase creaPartitaAdminUseCase;

  //metodi
  NuovaPartitaAdminBloc({required this.creaPartitaAdminUseCase}) : super(NuovaPartitaAdminInitial()) {
    on<CreaPartitaAdminRichiesta>(_onCreaPartitaAdminRichiesta);
  }

  Future<void> _onCreaPartitaAdminRichiesta(CreaPartitaAdminRichiesta evento, Emitter<NuovaPartitaAdminState> emit) async
  {
    emit(NuovaPartitaAdminLoading());

    try
    {
      final dettaglio = await creaPartitaAdminUseCase.call(evento.idCampo, evento.data, evento.oraInizio, evento.tipo, evento.telefoni, evento.giocatoriCampo);
      emit(PartitaAdminCreata(dettaglio: dettaglio));
    }
    on PartecipantiMancanti catch (e)
    {
      emit(NuovaPartitaAdminErrore(messaggio: e.message));
    }
    on TroppiPartecipanti catch (e)
    {
      emit(NuovaPartitaAdminErrore(messaggio: e.message));
    }
    on PartitaNonTrovata catch (e)
    {
      emit(NuovaPartitaAdminErrore(messaggio: e.messaggio));
    }
    on OperazioneRifiutata catch (e)
    {
      emit(NuovaPartitaAdminErrore(messaggio: e.messaggio));
    }
    on ErroreGenericoServer catch (e)
    {
      emit(NuovaPartitaAdminErrore(messaggio: e.messaggio));
    }
    on Exception //timeout o rete assente: il Client li lascia passare cosi come sono, senza questo la pagina resterebbe ferma
    {
      emit(NuovaPartitaAdminErrore(messaggio: ErroreGenericoServer().messaggio));
    }
  }
}
