//gestisce il livello unico dei giocatori del campo: lettura e salvataggio
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:thepadel/bloc/livelloCampo/livelloCampoEvent.dart';
import 'package:thepadel/bloc/livelloCampo/livelloCampoState.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/useCase/adminUseCase.dart';
import 'package:thepadel/useCase/eccezioniUseCase.dart';

class LivelloCampoBloc extends Bloc<LivelloCampoEvent, LivelloCampoState>{
  //attributi
  final LivelloCampoUseCase livelloCampoUseCase;
  final CambiaLivelloCampoUseCase cambiaLivelloCampoUseCase;

  //l'ultimo livello arrivato dal server, se il salvataggio fallisce il selettore deve tornare a questo
  double? livello;

  //metodi
  LivelloCampoBloc({required this.livelloCampoUseCase, required this.cambiaLivelloCampoUseCase}) : super(LivelloCampoInitial()) {
    on<LivelloCampoRichiesto>(_onLivelloCampoRichiesto);
    on<CambiaLivelloCampoRichiesto>(_onCambiaLivelloCampoRichiesto);
  }

  Future<void> _onLivelloCampoRichiesto(LivelloCampoRichiesto evento, Emitter<LivelloCampoState> emit) async
  {
    emit(LivelloCampoLoading(livello: livello));

    try
    {
      livello = await livelloCampoUseCase.call();
      emit(LivelloCampoCaricato(livello: livello!));
    }
    on PartitaNonTrovata catch (e)
    {
      emit(LivelloCampoErrore(livello: livello, messaggio: e.messaggio));
    }
    on OperazioneRifiutata catch (e)
    {
      emit(LivelloCampoErrore(livello: livello, messaggio: e.messaggio));
    }
    on ErroreGenericoServer catch (e)
    {
      emit(LivelloCampoErrore(livello: livello, messaggio: e.messaggio));
    }
    on Exception //timeout o rete assente: il Client li lascia passare cosi come sono, senza questo la pagina resterebbe ferma
    {
      emit(LivelloCampoErrore(livello: livello, messaggio: ErroreGenericoServer().messaggio));
    }
  }

  Future<void> _onCambiaLivelloCampoRichiesto(CambiaLivelloCampoRichiesto evento, Emitter<LivelloCampoState> emit) async
  {
    emit(LivelloCampoLoading(livello: livello));

    try
    {
      livello = await cambiaLivelloCampoUseCase.call(evento.livello);
      emit(LivelloCampoCaricato(livello: livello!));
    }
    on LivelloNonValido catch (e)
    {
      emit(LivelloCampoErrore(livello: livello, messaggio: e.message));
    }
    on PartitaNonTrovata catch (e)
    {
      emit(LivelloCampoErrore(livello: livello, messaggio: e.messaggio));
    }
    on OperazioneRifiutata catch (e)
    {
      emit(LivelloCampoErrore(livello: livello, messaggio: e.messaggio));
    }
    on ErroreGenericoServer catch (e)
    {
      emit(LivelloCampoErrore(livello: livello, messaggio: e.messaggio));
    }
    on Exception
    {
      emit(LivelloCampoErrore(livello: livello, messaggio: ErroreGenericoServer().messaggio));
    }
  }
}
