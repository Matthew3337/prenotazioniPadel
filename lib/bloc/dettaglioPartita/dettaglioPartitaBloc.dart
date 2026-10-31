//gestisce la pagina di dettaglio di una partita, le azioni (invita, esci, conferma...) verranno aggiunte qui
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:thepadel/bloc/dettaglioPartita/dettaglioPartitaEvent.dart';
import 'package:thepadel/bloc/dettaglioPartita/dettaglioPartitaState.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/useCase/dettaglioPartitaUseCase.dart';

class DettaglioPartitaBloc extends Bloc<DettaglioPartitaEvent, DettaglioPartitaState>{
  //attributi
  final DettaglioPartitaUseCase dettaglioPartitaUseCase;

  //metodi
  DettaglioPartitaBloc({required this.dettaglioPartitaUseCase}) : super(DettaglioPartitaInitial()) {
    on<DettaglioPartitaRichiesto>(_onDettaglioPartitaRichiesto);
  }

  Future<void> _onDettaglioPartitaRichiesto(DettaglioPartitaRichiesto evento, Emitter<DettaglioPartitaState> emit) async
  {
    emit(DettaglioPartitaLoading());

    try
    {
      final dettaglio = await dettaglioPartitaUseCase.call(evento.idPartita);
      emit(DettaglioPartitaCaricato(dettaglio: dettaglio));
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
