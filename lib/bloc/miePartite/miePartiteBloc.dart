//gestisce la pagina Le mie partite: quelle a cui l'utente partecipa e che non sono ancora finite
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:thepadel/bloc/miePartite/miePartiteEvent.dart';
import 'package:thepadel/bloc/miePartite/miePartiteState.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/useCase/miePartiteUseCase.dart';

class MiePartiteBloc extends Bloc<MiePartiteEvent, MiePartiteState>{
  //attributi
  final MiePartiteUseCase miePartiteUseCase;

  //metodi
  MiePartiteBloc({required this.miePartiteUseCase}) : super(MiePartiteInitial()) {
    on<MiePartiteRichieste>(_onMiePartiteRichieste);
  }

  Future<void> _onMiePartiteRichieste(MiePartiteRichieste evento, Emitter<MiePartiteState> emit) async
  {
    emit(MiePartiteLoading());

    try
    {
      final partite = await miePartiteUseCase.call();
      emit(MiePartiteCaricate(partite: partite));
    }
    on ErroreGenericoServer catch (e)
    {
      emit(MiePartiteErrore(messaggio: e.messaggio));
    }
    on Exception //timeout o rete assente: il Client li lascia passare cosi come sono, senza questo la pagina resterebbe ferma
    {
      emit(MiePartiteErrore(messaggio: ErroreGenericoServer().messaggio));
    }
  }
}
