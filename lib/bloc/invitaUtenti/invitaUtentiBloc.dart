//gestisce la pagina di selezione degli invitati: elenco degli utenti invitabili, ricerca e invito
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:thepadel/bloc/invitaUtenti/invitaUtentiEvent.dart';
import 'package:thepadel/bloc/invitaUtenti/invitaUtentiState.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/domainLayer/enetity/utenteInvitabile.dart';
import 'package:thepadel/useCase/dettaglioPartitaUseCase.dart';
import 'package:thepadel/useCase/invitaUtentiUseCase.dart';

class InvitaUtentiBloc extends Bloc<InvitaUtentiEvent, InvitaUtentiState>{
  //attributi
  final InvitabiliUseCase invitabiliUseCase;
  final InvitaUtenteUseCase invitaUtenteUseCase;
  final DettaglioPartitaUseCase dettaglioPartitaUseCase;

  //l'ultima lista caricata, serve agli stati dell'invito per non far sparire l'elenco
  List<UtenteInvitabile> utenti = [];

  //l'ultima ricerca fatta, serve per ricaricare la stessa lista dopo un invito fallito
  String cerca = "";

  //metodi
  InvitaUtentiBloc({required this.invitabiliUseCase, required this.invitaUtenteUseCase, required this.dettaglioPartitaUseCase}) : super(InvitaUtentiInitial()) {
    on<InvitabiliRichiesti>(_onInvitabiliRichiesti);
    on<InvitoRichiesto>(_onInvitoRichiesto);
  }

  Future<void> _onInvitabiliRichiesti(InvitabiliRichiesti evento, Emitter<InvitaUtentiState> emit) async
  {
    emit(InvitaUtentiLoading());
    cerca = evento.cerca;
    await _caricaInvitabili(evento.idPartita, emit);
  }

  Future<void> _onInvitoRichiesto(InvitoRichiesto evento, Emitter<InvitaUtentiState> emit) async
  {
    emit(InvitoInCorso(utenti: utenti, telefono: evento.telefono));

    try
    {
      final dettaglio = await invitaUtenteUseCase.call(evento.idPartita, evento.telefono);

      //l'invitato ora e in partita, quindi lo tolgo dall'elenco senza richiederlo al server
      List<UtenteInvitabile> rimasti = [];
      for(UtenteInvitabile u in utenti)
      {
        if(u.telefono != evento.telefono)
        {
          rimasti.add(u);
        }
      }
      utenti = rimasti;

      emit(InvitoRiuscito(utenti: utenti, dettaglio: dettaglio));
      return;
    }
    on PartitaNonTrovata catch (e)
    {
      emit(InvitoErrore(utenti: utenti, messaggio: e.messaggio));
    }
    on OperazioneRifiutata catch (e)
    {
      emit(InvitoErrore(utenti: utenti, messaggio: e.messaggio));
    }
    on ErroreGenericoServer catch (e)
    {
      emit(InvitoErrore(utenti: utenti, messaggio: e.messaggio));
    }
    on Exception //timeout o rete assente: il Client li lascia passare cosi come sono, senza questo la pagina resterebbe ferma
    {
      emit(InvitoErrore(utenti: utenti, messaggio: ErroreGenericoServer().messaggio));
    }

    //se l'invito e fallito la partita o l'elenco sono probabilmente cambiati (posti finiti, utente entrato da solo),
    //quindi ricarico subito; non emetto il Loading cosi la lista resta a schermo finche non arriva quella nuova
    await _caricaInvitabili(evento.idPartita, emit);
  }

  Future<void> _caricaInvitabili(int idPartita, Emitter<InvitaUtentiState> emit) async
  {
    try
    {
      //l'elenco degli invitabili non dice quanti posti restano, quindi li prendo dal dettaglio della partita
      final dettaglio = await dettaglioPartitaUseCase.call(idPartita);
      utenti = await invitabiliUseCase.call(idPartita, cerca);
      emit(InvitabiliCaricati(utenti: utenti, postiLiberi: dettaglio.postiLiberi));
    }
    on PartitaNonTrovata catch (e)
    {
      emit(InvitabiliErrore(messaggio: e.messaggio));
    }
    on OperazioneRifiutata catch (e)
    {
      emit(InvitabiliErrore(messaggio: e.messaggio));
    }
    on ErroreGenericoServer catch (e)
    {
      emit(InvitabiliErrore(messaggio: e.messaggio));
    }
    on Exception
    {
      emit(InvitabiliErrore(messaggio: ErroreGenericoServer().messaggio));
    }
  }
}
