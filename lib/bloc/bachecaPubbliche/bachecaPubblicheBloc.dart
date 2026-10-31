//gestisce la bacheca delle partite pubbliche e l'ingresso dell'utente in una di queste
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:thepadel/bloc/bachecaPubbliche/bachecaPubblicheEvent.dart';
import 'package:thepadel/bloc/bachecaPubbliche/bachecaPubblicheState.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/domainLayer/enetity/partitaPubblica.dart';
import 'package:thepadel/useCase/bachecaPubblicheUseCase.dart';

class BachecaPubblicheBloc extends Bloc<BachecaPubblicheEvent, BachecaPubblicheState>{
  //attributi
  final PartitePubblicheUseCase partitePubblicheUseCase;
  final EntraInPartitaUseCase entraInPartitaUseCase;

  //l'ultima lista caricata, serve agli stati dell'ingresso per non far sparire la bacheca
  List<PartitaPubblica> partite = [];

  //metodi
  BachecaPubblicheBloc({required this.partitePubblicheUseCase, required this.entraInPartitaUseCase}) : super(BachecaPubblicheInitial()) {
    on<BachecaPubblicheRichiesta>(_onBachecaPubblicheRichiesta);
    on<EntraInPartitaRichiesto>(_onEntraInPartitaRichiesto);
  }

  Future<void> _onBachecaPubblicheRichiesta(BachecaPubblicheRichiesta evento, Emitter<BachecaPubblicheState> emit) async
  {
    emit(BachecaPubblicheLoading());
    await _caricaBacheca(emit);
  }

  Future<void> _onEntraInPartitaRichiesto(EntraInPartitaRichiesto evento, Emitter<BachecaPubblicheState> emit) async
  {
    emit(IngressoInCorso(partite: partite, idPartita: evento.idPartita));

    try
    {
      final dettaglio = await entraInPartitaUseCase.call(evento.idPartita);
      emit(IngressoRiuscito(partite: partite, dettaglio: dettaglio));
      return;
    }
    on PartitaNonTrovata catch (e)
    {
      emit(IngressoErrore(partite: partite, messaggio: e.messaggio));
    }
    on IngressoRifiutato catch (e)
    {
      emit(IngressoErrore(partite: partite, messaggio: e.messaggio));
    }
    on ErroreGenericoServer catch (e)
    {
      emit(IngressoErrore(partite: partite, messaggio: e.messaggio));
    }

    //se l'ingresso e fallito la bacheca e probabilmente cambiata (partita piena, chiusa o annullata),
    //quindi la ricarico subito; non emetto il Loading cosi la lista resta a schermo finche non arriva quella nuova
    await _caricaBacheca(emit);
  }

  Future<void> _caricaBacheca(Emitter<BachecaPubblicheState> emit) async
  {
    try
    {
      partite = await partitePubblicheUseCase.call();
      emit(BachecaPubblicheCaricata(partite: partite));
    }
    on ErroreGenericoServer catch (e)
    {
      emit(BachecaPubblicheErrore(messaggio: e.messaggio));
    }
  }
}
