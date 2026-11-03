//gestisce il dettaglio di una partita per l'admin e le sue modifiche, compreso il form del risultato
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:thepadel/bloc/dettaglioAdmin/dettaglioAdminEvent.dart';
import 'package:thepadel/bloc/dettaglioAdmin/dettaglioAdminState.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/domainLayer/enetity/dettaglioPartita.dart';
import 'package:thepadel/useCase/adminUseCase.dart';
import 'package:thepadel/useCase/dettaglioPartitaUseCase.dart';
import 'package:thepadel/useCase/eccezioniUseCase.dart';

class DettaglioAdminBloc extends Bloc<DettaglioAdminEvent, DettaglioAdminState>{
  //attributi
  final DettaglioPartitaUseCase dettaglioPartitaUseCase;
  final ModificaPartecipantiUseCase modificaPartecipantiUseCase;
  final ModificaRisultatoUseCase modificaRisultatoUseCase;
  final ModificaStatoUseCase modificaStatoUseCase;
  final AnnullaPartitaUseCase annullaPartitaUseCase;

  //l'ultimo dettaglio caricato, serve agli stati delle operazioni per non far sparire la pagina
  DettaglioPartita? dettaglio;

  //metodi
  DettaglioAdminBloc({required this.dettaglioPartitaUseCase, required this.modificaPartecipantiUseCase, required this.modificaRisultatoUseCase, required this.modificaStatoUseCase, required this.annullaPartitaUseCase}) : super(DettaglioAdminInitial()) {
    on<DettaglioAdminRichiesto>(_onDettaglioAdminRichiesto);
    on<ModificaPartecipantiRichiesta>(_onModificaPartecipantiRichiesta);
    on<ModificaRisultatoRichiesta>(_onModificaRisultatoRichiesta);
    on<ModificaStatoRichiesta>(_onModificaStatoRichiesta);
    on<AnnullaPartitaRichiesta>(_onAnnullaPartitaRichiesta);
  }

  Future<void> _onDettaglioAdminRichiesto(DettaglioAdminRichiesto evento, Emitter<DettaglioAdminState> emit) async
  {
    emit(DettaglioAdminLoading());
    await _caricaDettaglio(evento.id, emit);
  }

  Future<void> _onModificaPartecipantiRichiesta(ModificaPartecipantiRichiesta evento, Emitter<DettaglioAdminState> emit) async
  {
    //i bottoni compaiono solo con il dettaglio a schermo, se non c'e ancora non ha senso procedere
    final dettaglioAttuale = dettaglio;
    if(dettaglioAttuale == null)
    {
      return;
    }

    emit(OperazioneAdminInCorso(dettaglio: dettaglioAttuale));

    try
    {
      //il server risponde con il dettaglio aggiornato, lo salvo cosi le prossime operazioni partono da quello
      dettaglio = await modificaPartecipantiUseCase.call(evento.id, evento.telefoni);
      emit(OperazioneAdminRiuscita(dettaglio: dettaglio!, messaggio: "Partecipanti aggiornati"));
      return;
    }
    on PartecipantiMancanti catch (e)
    {
      //il server non e stato chiamato: il dettaglio e ancora buono, non serve ricaricarlo
      emit(OperazioneAdminErrore(dettaglio: dettaglioAttuale, messaggio: e.message));
      return;
    }
    on TroppiPartecipanti catch (e)
    {
      emit(OperazioneAdminErrore(dettaglio: dettaglioAttuale, messaggio: e.message));
      return;
    }
    on PartitaNonTrovata catch (e)
    {
      emit(OperazioneAdminErrore(dettaglio: dettaglioAttuale, messaggio: e.messaggio));
    }
    on OperazioneRifiutata catch (e)
    {
      emit(OperazioneAdminErrore(dettaglio: dettaglioAttuale, messaggio: e.messaggio));
    }
    on ErroreGenericoServer catch (e)
    {
      emit(OperazioneAdminErrore(dettaglio: dettaglioAttuale, messaggio: e.messaggio));
    }
    on Exception //timeout o rete assente: il Client li lascia passare cosi come sono, senza questo la pagina resterebbe ferma
    {
      emit(OperazioneAdminErrore(dettaglio: dettaglioAttuale, messaggio: ErroreGenericoServer().messaggio));
    }

    //se il server ha rifiutato la partita e probabilmente cambiata, quindi la ricarico;
    //non emetto il Loading cosi il dettaglio resta a schermo finche non arriva quello nuovo
    await _caricaDettaglio(evento.id, emit);
  }

  Future<void> _onModificaRisultatoRichiesta(ModificaRisultatoRichiesta evento, Emitter<DettaglioAdminState> emit) async
  {
    final dettaglioAttuale = dettaglio;
    if(dettaglioAttuale == null)
    {
      return;
    }

    emit(OperazioneAdminInCorso(dettaglio: dettaglioAttuale));

    try
    {
      dettaglio = await modificaRisultatoUseCase.call(evento.id, evento.squadra1, evento.squadra2, evento.set);
      emit(OperazioneAdminRiuscita(dettaglio: dettaglio!, messaggio: "Risultato aggiornato"));
      return;
    }
    on SquadraIncompleta catch (e)
    {
      //come per i partecipanti, gli errori del form non arrivano dal server: niente ricarica
      emit(OperazioneAdminErrore(dettaglio: dettaglioAttuale, messaggio: e.message));
      return;
    }
    on GiocatoriRipetuti catch (e)
    {
      emit(OperazioneAdminErrore(dettaglio: dettaglioAttuale, messaggio: e.message));
      return;
    }
    on NumeroSetNonValido catch (e)
    {
      emit(OperazioneAdminErrore(dettaglio: dettaglioAttuale, messaggio: e.message));
      return;
    }
    on SetNonValido catch (e)
    {
      emit(OperazioneAdminErrore(dettaglio: dettaglioAttuale, messaggio: e.message));
      return;
    }
    on PartitaNonTrovata catch (e)
    {
      emit(OperazioneAdminErrore(dettaglio: dettaglioAttuale, messaggio: e.messaggio));
    }
    on OperazioneRifiutata catch (e)
    {
      emit(OperazioneAdminErrore(dettaglio: dettaglioAttuale, messaggio: e.messaggio));
    }
    on ErroreGenericoServer catch (e)
    {
      emit(OperazioneAdminErrore(dettaglio: dettaglioAttuale, messaggio: e.messaggio));
    }
    on Exception
    {
      emit(OperazioneAdminErrore(dettaglio: dettaglioAttuale, messaggio: ErroreGenericoServer().messaggio));
    }

    await _caricaDettaglio(evento.id, emit);
  }

  Future<void> _onModificaStatoRichiesta(ModificaStatoRichiesta evento, Emitter<DettaglioAdminState> emit) async
  {
    final dettaglioAttuale = dettaglio;
    if(dettaglioAttuale == null)
    {
      return;
    }

    emit(OperazioneAdminInCorso(dettaglio: dettaglioAttuale));

    try
    {
      dettaglio = await modificaStatoUseCase.call(evento.id, evento.stato);
      emit(OperazioneAdminRiuscita(dettaglio: dettaglio!, messaggio: "Stato aggiornato"));
      return;
    }
    on PartitaNonTrovata catch (e)
    {
      emit(OperazioneAdminErrore(dettaglio: dettaglioAttuale, messaggio: e.messaggio));
    }
    on OperazioneRifiutata catch (e)
    {
      emit(OperazioneAdminErrore(dettaglio: dettaglioAttuale, messaggio: e.messaggio));
    }
    on ErroreGenericoServer catch (e)
    {
      emit(OperazioneAdminErrore(dettaglio: dettaglioAttuale, messaggio: e.messaggio));
    }
    on Exception
    {
      emit(OperazioneAdminErrore(dettaglio: dettaglioAttuale, messaggio: ErroreGenericoServer().messaggio));
    }

    await _caricaDettaglio(evento.id, emit);
  }

  Future<void> _onAnnullaPartitaRichiesta(AnnullaPartitaRichiesta evento, Emitter<DettaglioAdminState> emit) async
  {
    final dettaglioAttuale = dettaglio;
    if(dettaglioAttuale == null)
    {
      return;
    }

    emit(OperazioneAdminInCorso(dettaglio: dettaglioAttuale));

    try
    {
      dettaglio = await annullaPartitaUseCase.call(evento.id);
      emit(OperazioneAdminRiuscita(dettaglio: dettaglio!, messaggio: "Partita annullata"));
      return;
    }
    on PartitaNonTrovata catch (e)
    {
      emit(OperazioneAdminErrore(dettaglio: dettaglioAttuale, messaggio: e.messaggio));
    }
    on OperazioneRifiutata catch (e)
    {
      emit(OperazioneAdminErrore(dettaglio: dettaglioAttuale, messaggio: e.messaggio));
    }
    on ErroreGenericoServer catch (e)
    {
      emit(OperazioneAdminErrore(dettaglio: dettaglioAttuale, messaggio: e.messaggio));
    }
    on Exception
    {
      emit(OperazioneAdminErrore(dettaglio: dettaglioAttuale, messaggio: ErroreGenericoServer().messaggio));
    }

    await _caricaDettaglio(evento.id, emit);
  }

  Future<void> _caricaDettaglio(int id, Emitter<DettaglioAdminState> emit) async
  {
    try
    {
      dettaglio = await dettaglioPartitaUseCase.call(id);
      emit(DettaglioAdminCaricato(dettaglio: dettaglio!));
    }
    on PartitaNonTrovata catch (e)
    {
      emit(DettaglioAdminErrore(messaggio: e.messaggio));
    }
    on ErroreGenericoServer catch (e)
    {
      emit(DettaglioAdminErrore(messaggio: e.messaggio));
    }
    on Exception
    {
      emit(DettaglioAdminErrore(messaggio: ErroreGenericoServer().messaggio));
    }
  }
}
