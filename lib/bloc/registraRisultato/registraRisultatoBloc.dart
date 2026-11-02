//gestisce l'invio del risultato dalla pagina del form, le squadre e i game scelti li tiene la UI
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:thepadel/bloc/registraRisultato/registraRisultatoEvent.dart';
import 'package:thepadel/bloc/registraRisultato/registraRisultatoState.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/useCase/eccezioniUseCase.dart';
import 'package:thepadel/useCase/registraRisultatoUseCase.dart';

class RegistraRisultatoBloc extends Bloc<RegistraRisultatoEvent, RegistraRisultatoState>{
  //attributi
  final RegistraRisultatoUseCase registraRisultatoUseCase;

  //metodi
  RegistraRisultatoBloc({required this.registraRisultatoUseCase}) : super(RegistraRisultatoInitial()) {
    on<RegistraRisultatoRichiesto>(_onRegistraRisultatoRichiesto);
  }

  Future<void> _onRegistraRisultatoRichiesto(RegistraRisultatoRichiesto evento, Emitter<RegistraRisultatoState> emit) async
  {
    emit(RegistraRisultatoLoading());

    try
    {
      final dettaglio = await registraRisultatoUseCase.call(evento.idPartita, evento.squadra1, evento.squadra2, evento.set);
      emit(RisultatoRegistrato(dettaglio: dettaglio));
    }
    on SquadraIncompleta catch (e)
    {
      emit(RegistraRisultatoErrore(messaggio: e.message));
    }
    on GiocatoriRipetuti catch (e)
    {
      emit(RegistraRisultatoErrore(messaggio: e.message));
    }
    on NumeroSetNonValido catch (e)
    {
      emit(RegistraRisultatoErrore(messaggio: e.message));
    }
    on SetNonValido catch (e)
    {
      emit(RegistraRisultatoErrore(messaggio: e.message));
    }
    on PartitaNonTrovata catch (e)
    {
      emit(RegistraRisultatoErrore(messaggio: e.messaggio));
    }
    on OperazioneRifiutata catch (e)
    {
      emit(RegistraRisultatoErrore(messaggio: e.messaggio));
    }
    on ErroreGenericoServer catch (e)
    {
      emit(RegistraRisultatoErrore(messaggio: e.messaggio));
    }
  }
}
