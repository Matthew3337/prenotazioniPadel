//gestisce tutta la home page 
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:thepadel/bloc/homePage/homeEvent.dart';
import 'package:thepadel/bloc/homePage/homeState.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/useCase/homeUseCase.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState>{
  //attrubuti 
  ProssimaPartitaUseCase prossimaPartitaUseCase;
  SlotDisponibiliUseCase slotUseCase;

  //metodi 
  HomeBloc({required this.prossimaPartitaUseCase, required this.slotUseCase}) : super(HomeState.initial()) {//dichiaro lo stato iniziale 
    on<HomeProssimaPartitaRequested>(_onPPartitaDownload);
    on<HomeSlotOggiRequested>(_onSlotDownload);
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

  Future<void> _onSlotDownload(HomeSlotOggiRequested event, Emitter<HomeState> emit) async
  {
    emit(state.copyWith(slotOggi: SectionLoading()));

    try
    {
      //use case 
      final slots = await slotUseCase.call(DateTime.now());
      emit(state.copyWith(slotOggi: SectionSuccess(slots)));
    }
    on ErroreGenericoServer catch (e)
    {
      emit(state.copyWith(slotOggi: SectionError(e.messaggio)));
    }


  }
}