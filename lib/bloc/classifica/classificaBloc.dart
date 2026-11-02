//gestisce la pagina della classifica degli utenti
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:thepadel/bloc/classifica/classificaEvent.dart';
import 'package:thepadel/bloc/classifica/classificaState.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/useCase/classificaUseCase.dart';

class ClassificaBloc extends Bloc<ClassificaEvent, ClassificaState>{
  //attributi
  final ClassificaUseCase classificaUseCase;

  //metodi
  ClassificaBloc({required this.classificaUseCase}) : super(ClassificaInitial()) {
    on<ClassificaRichiesta>(_onClassificaRichiesta);
  }

  Future<void> _onClassificaRichiesta(ClassificaRichiesta evento, Emitter<ClassificaState> emit) async
  {
    emit(ClassificaLoading());

    try
    {
      final voci = await classificaUseCase.call();
      emit(ClassificaCaricata(voci: voci));
    }
    on ErroreGenericoServer catch (e)
    {
      emit(ClassificaErrore(messaggio: e.messaggio));
    }
  }
}
