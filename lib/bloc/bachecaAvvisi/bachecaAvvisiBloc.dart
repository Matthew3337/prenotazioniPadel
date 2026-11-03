//gestisce la bacheca avvisi dell'admin; la home admin lo usa anche per contare gli avvisi aperti
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:thepadel/bloc/bachecaAvvisi/bachecaAvvisiEvent.dart';
import 'package:thepadel/bloc/bachecaAvvisi/bachecaAvvisiState.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/useCase/adminUseCase.dart';

class BachecaAvvisiBloc extends Bloc<BachecaAvvisiEvent, BachecaAvvisiState>{
  //attributi
  final BachecaAvvisiUseCase bachecaAvvisiUseCase;

  //metodi
  BachecaAvvisiBloc({required this.bachecaAvvisiUseCase}) : super(BachecaAvvisiInitial()) {
    on<BachecaAvvisiRichiesta>(_onBachecaAvvisiRichiesta);
  }

  Future<void> _onBachecaAvvisiRichiesta(BachecaAvvisiRichiesta evento, Emitter<BachecaAvvisiState> emit) async
  {
    emit(BachecaAvvisiLoading());

    try
    {
      final avvisi = await bachecaAvvisiUseCase.call();
      emit(BachecaAvvisiCaricata(avvisi: avvisi));
    }
    on PartitaNonTrovata catch (e)
    {
      emit(BachecaAvvisiErrore(messaggio: e.messaggio));
    }
    on OperazioneRifiutata catch (e)
    {
      emit(BachecaAvvisiErrore(messaggio: e.messaggio));
    }
    on ErroreGenericoServer catch (e)
    {
      emit(BachecaAvvisiErrore(messaggio: e.messaggio));
    }
    on Exception //timeout o rete assente: il Client li lascia passare cosi come sono, senza questo la pagina resterebbe ferma
    {
      emit(BachecaAvvisiErrore(messaggio: ErroreGenericoServer().messaggio));
    }
  }
}
