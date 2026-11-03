//gestisce la pagina delle partite del giorno dell'admin, divise per campo
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:thepadel/bloc/partiteGiorno/partiteGiornoEvent.dart';
import 'package:thepadel/bloc/partiteGiorno/partiteGiornoState.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/useCase/adminUseCase.dart';

class PartiteGiornoBloc extends Bloc<PartiteGiornoEvent, PartiteGiornoState>{
  //attributi
  final PartiteGiornoUseCase partiteGiornoUseCase;

  //metodi
  PartiteGiornoBloc({required this.partiteGiornoUseCase}) : super(PartiteGiornoInitial()) {
    on<PartiteGiornoRichieste>(_onPartiteGiornoRichieste);
  }

  Future<void> _onPartiteGiornoRichieste(PartiteGiornoRichieste evento, Emitter<PartiteGiornoState> emit) async
  {
    emit(PartiteGiornoLoading());

    try
    {
      final campi = await partiteGiornoUseCase.call(evento.data);
      emit(PartiteGiornoCaricate(campi: campi));
    }
    on PartitaNonTrovata catch (e)
    {
      emit(PartiteGiornoErrore(messaggio: e.messaggio));
    }
    on OperazioneRifiutata catch (e)
    {
      emit(PartiteGiornoErrore(messaggio: e.messaggio));
    }
    on ErroreGenericoServer catch (e)
    {
      emit(PartiteGiornoErrore(messaggio: e.messaggio));
    }
    on Exception //timeout o rete assente: il Client li lascia passare cosi come sono, senza questo la pagina resterebbe ferma
    {
      emit(PartiteGiornoErrore(messaggio: ErroreGenericoServer().messaggio));
    }
  }
}
