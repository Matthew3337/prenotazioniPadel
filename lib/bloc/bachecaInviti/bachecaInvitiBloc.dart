//gestisce la bacheca degli inviti, cioe le partite in cui l'utente e stato aggiunto dal creatore
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:thepadel/bloc/bachecaInviti/bachecaInvitiEvent.dart';
import 'package:thepadel/bloc/bachecaInviti/bachecaInvitiState.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/useCase/bachecaInvitiUseCase.dart';

class BachecaInvitiBloc extends Bloc<BachecaInvitiEvent, BachecaInvitiState>{
  //attributi
  final BachecaInvitiUseCase bachecaInvitiUseCase;

  //metodi
  BachecaInvitiBloc({required this.bachecaInvitiUseCase}) : super(BachecaInvitiInitial()) {
    on<BachecaInvitiRichiesta>(_onBachecaInvitiRichiesta);
  }

  Future<void> _onBachecaInvitiRichiesta(BachecaInvitiRichiesta evento, Emitter<BachecaInvitiState> emit) async
  {
    emit(BachecaInvitiLoading());

    try
    {
      final partite = await bachecaInvitiUseCase.call();
      emit(BachecaInvitiCaricata(partite: partite));
    }
    on ErroreGenericoServer catch (e)
    {
      emit(BachecaInvitiErrore(messaggio: e.messaggio));
    }
  }
}
