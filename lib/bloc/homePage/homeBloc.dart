//gestisce tutta la home page 
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:thepadel/bloc/homePage/homeEvent.dart';
import 'package:thepadel/bloc/homePage/homeState.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/useCase/homeUseCase.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState>{
  //attrubuti 
  ProssimaPartitaUseCase prossimaPartitaUseCase;

  //metodi 
  HomeBloc({required this.prossimaPartitaUseCase}) : super(HomeState.initial()) {//dichiaro lo stato iniziale 
    on<HomeProssimaPartitaRequested>(_onPPartitaDownload);
  }

  Future<void> _onPPartitaDownload(HomeProssimaPartitaRequested event, Emitter<HomeState> emit ) async
  {
    emit(state.copyWith(prossimaPartita: SectionLoading())); // emetto lo stato home ma con lo stato della sezione prossima partita in loading 
    try
    {
      //usecase
      final prenotazione = await prossimaPartitaUseCase.call();
      if(prenotazione != null)
      {
        emit(state.copyWith(prossimaPartita: SectionSuccess(prenotazione)));
      }
      else
      {
        emit(state.copyWith(prossimaPartita: SectionEmpty()));
      }
      
    }
    on ErroreGenericoServer catch(e)
    {
      emit(state.copyWith(prossimaPartita: SectionError(e.messaggio)));
    }
  }
}