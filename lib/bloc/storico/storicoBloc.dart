//gestisce lo storico delle partite a cui l'utente ha partecipato
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:thepadel/bloc/storico/storicoEvent.dart';
import 'package:thepadel/bloc/storico/storicoState.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/useCase/storicoUseCase.dart';

class StoricoBloc extends Bloc<StoricoEvent, StoricoState>{
  //attributi
  final StoricoUseCase storicoUseCase;

  //metodi
  StoricoBloc({required this.storicoUseCase}) : super(StoricoInitial()) {
    on<StoricoRichiesto>(_onStoricoRichiesto);
  }

  Future<void> _onStoricoRichiesto(StoricoRichiesto evento, Emitter<StoricoState> emit) async
  {
    emit(StoricoLoading());

    try
    {
      final partite = await storicoUseCase.call();
      emit(StoricoCaricato(partite: partite));
    }
    on ErroreGenericoServer catch (e)
    {
      emit(StoricoErrore(messaggio: e.messaggio));
    }
  }
}
