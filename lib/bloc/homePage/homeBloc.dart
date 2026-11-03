//gestisce tutta la home page 
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:thepadel/bloc/homePage/homeEvent.dart';
import 'package:thepadel/bloc/homePage/homeState.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/domainLayer/enetity/distaccoClassifica.dart';
import 'package:thepadel/domainLayer/enetity/voceClassifica.dart';
import 'package:thepadel/useCase/bachecaInvitiUseCase.dart';
import 'package:thepadel/useCase/bachecaPubblicheUseCase.dart';
import 'package:thepadel/useCase/classificaUseCase.dart';
import 'package:thepadel/useCase/dettaglioPartitaUseCase.dart';
import 'package:thepadel/useCase/homeUseCase.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState>{
  //attrubuti 
  ProssimaPartitaUseCase prossimaPartitaUseCase;
  SlotOggiUseCase slotOggiUseCase;
  ClassificaUseCase classificaUseCase;
  DettaglioPartitaUseCase dettaglioPartitaUseCase;
  BachecaInvitiUseCase bachecaInvitiUseCase;
  PartitePubblicheUseCase partitePubblicheUseCase;

  //metodi 
  HomeBloc({required this.prossimaPartitaUseCase, required this.slotOggiUseCase, required this.classificaUseCase, required this.dettaglioPartitaUseCase, required this.bachecaInvitiUseCase, required this.partitePubblicheUseCase}) : super(HomeState.initial()) {//dichiaro lo stato iniziale 
    on<HomeProssimaPartitaRequested>(_onPPartitaDownload);
    on<HomeSlotOggiRequested>(_onSlotDownload);
    on<HomeClassificaRequested>(_onClassificaDownload);
    on<HomeInvitiRequested>(_onInvitiDownload);
    on<HomePartitePubblicheRequested>(_onPubblicheDownload);
  }

  //in tutti gli handler l'ultimo catch prende timeout e rete assente, che il Client lascia passare cosi come sono:
  //senza, la sezione resterebbe in caricamento per sempre

  Future<void> _onPPartitaDownload(HomeProssimaPartitaRequested event, Emitter<HomeState> emit ) async
  {
    emit(state.copyWith(prossimaPartita: SectionLoading(), dettaglioProssimaPartita: SectionLoading())); // emetto lo stato home ma con lo stato della sezione prossima partita in loading 

    int? idPartita;
    try
    {
      //usecase
      final prenotazione = await prossimaPartitaUseCase.call();
      if(prenotazione != null)
      {
        idPartita = prenotazione.id;
        emit(state.copyWith(prossimaPartita: SectionSuccess(prenotazione)));
      }
      else
      {
        emit(state.copyWith(prossimaPartita: SectionEmpty(), dettaglioProssimaPartita: SectionEmpty()));
      }
      
    }
    on ErroreGenericoServer catch(e)
    {
      emit(state.copyWith(prossimaPartita: SectionError(e.messaggio), dettaglioProssimaPartita: SectionEmpty()));
    }
    on Exception
    {
      emit(state.copyWith(prossimaPartita: SectionError(ErroreGenericoServer().messaggio), dettaglioProssimaPartita: SectionEmpty()));
    }

    if(idPartita != null)
    {
      await _caricaDettaglioProssimaPartita(idPartita, emit);
    }
  }

  //se il dettaglio fallisce la prossima partita resta com'e: la card puo mostrare comunque campo e orario
  Future<void> _caricaDettaglioProssimaPartita(int idPartita, Emitter<HomeState> emit) async
  {
    try
    {
      final dettaglio = await dettaglioPartitaUseCase.call(idPartita);
      emit(state.copyWith(dettaglioProssimaPartita: SectionSuccess(dettaglio)));
    }
    on PartitaNonTrovata catch (e)
    {
      emit(state.copyWith(dettaglioProssimaPartita: SectionError(e.messaggio)));
    }
    on ErroreGenericoServer catch (e)
    {
      emit(state.copyWith(dettaglioProssimaPartita: SectionError(e.messaggio)));
    }
    on Exception
    {
      emit(state.copyWith(dettaglioProssimaPartita: SectionError(ErroreGenericoServer().messaggio)));
    }
  }

  Future<void> _onSlotDownload(HomeSlotOggiRequested event, Emitter<HomeState> emit) async
  {
    emit(state.copyWith(slotOggi: SectionLoading()));

    try
    {
      //use case 
      final slots = await slotOggiUseCase.call(DateTime.now());
      if(slots.isNotEmpty)
      {
        emit(state.copyWith(slotOggi: SectionSuccess(slots)));
      }
      else
      {
        emit(state.copyWith(slotOggi: SectionEmpty()));
      }
    }
    on ErroreGenericoServer catch (e)
    {
      emit(state.copyWith(slotOggi: SectionError(e.messaggio)));
    }
    on Exception
    {
      emit(state.copyWith(slotOggi: SectionError(ErroreGenericoServer().messaggio)));
    }


  }

  Future<void> _onClassificaDownload(HomeClassificaRequested event, Emitter<HomeState> emit) async
  {
    emit(state.copyWith(classifica: SectionLoading(), distaccoClassifica: SectionLoading()));

    try
    {
      final voci = await classificaUseCase.call();

      //alla home serve solo la riga dell'utente; l'admin non e in classifica, quindi puo non esserci
      VoceClassifica? voceUtente;
      for(final voce in voci)
      {
        if(voce.utenteCorrente)
        {
          voceUtente = voce;
        }
      }

      if(voceUtente != null)
      {
        emit(state.copyWith(classifica: SectionSuccess(voceUtente), distaccoClassifica: SectionSuccess(_calcolaDistacco(voceUtente, voci))));
      }
      else
      {
        emit(state.copyWith(classifica: SectionEmpty(), distaccoClassifica: SectionEmpty()));
      }
    }
    on ErroreGenericoServer catch (e)
    {
      emit(state.copyWith(classifica: SectionError(e.messaggio), distaccoClassifica: SectionError(e.messaggio)));
    }
    on Exception
    {
      final messaggio = ErroreGenericoServer().messaggio;
      emit(state.copyWith(classifica: SectionError(messaggio), distaccoClassifica: SectionError(messaggio)));
    }
  }

  //la posizione sopra e la piu alta tra quelle minori della mia: non basta togliere uno, con i pari merito (1, 2, 2, 4) il 3 non esiste
  DistaccoClassifica _calcolaDistacco(VoceClassifica voceUtente, List<VoceClassifica> voci)
  {
    VoceClassifica? voceSopra;
    for(final voce in voci)
    {
      if(voce.posizione < voceUtente.posizione && (voceSopra == null || voce.posizione > voceSopra.posizione))
      {
        voceSopra = voce;
      }
    }

    if(voceSopra == null)
    {
      return DistaccoClassifica(punti: null, posizioneSopra: null);
    }
    return DistaccoClassifica(punti: voceSopra.punteggio - voceUtente.punteggio, posizioneSopra: voceSopra.posizione);
  }

  Future<void> _onInvitiDownload(HomeInvitiRequested event, Emitter<HomeState> emit) async
  {
    emit(state.copyWith(invitiRicevuti: SectionLoading()));

    try
    {
      final inviti = await bachecaInvitiUseCase.call();
      emit(state.copyWith(invitiRicevuti: SectionSuccess(inviti.length)));
    }
    on ErroreGenericoServer catch (e)
    {
      emit(state.copyWith(invitiRicevuti: SectionError(e.messaggio)));
    }
    on Exception
    {
      emit(state.copyWith(invitiRicevuti: SectionError(ErroreGenericoServer().messaggio)));
    }
  }

  Future<void> _onPubblicheDownload(HomePartitePubblicheRequested event, Emitter<HomeState> emit) async
  {
    emit(state.copyWith(partitePubblicheAperte: SectionLoading()));

    try
    {
      final partite = await partitePubblicheUseCase.call();
      emit(state.copyWith(partitePubblicheAperte: SectionSuccess(partite.length)));
    }
    on ErroreGenericoServer catch (e)
    {
      emit(state.copyWith(partitePubblicheAperte: SectionError(e.messaggio)));
    }
    on Exception
    {
      emit(state.copyWith(partitePubblicheAperte: SectionError(ErroreGenericoServer().messaggio)));
    }
  }
}
