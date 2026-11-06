//gestisce la ricerca degli utenti da invitare mentre si prenota, quando la partita non esiste ancora.
//Qui non si invita nessuno: gli utenti scelti partono insieme alla prenotazione, con CreaPartitaRichiesta
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:thepadel/bloc/cercaInvitati/cercaInvitatiEvent.dart';
import 'package:thepadel/bloc/cercaInvitati/cercaInvitatiState.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/useCase/invitaUtentiUseCase.dart';

class CercaInvitatiBloc extends Bloc<CercaInvitatiEvent, CercaInvitatiState>{
  //attributi
  final UtentiInvitabiliUseCase utentiInvitabiliUseCase;

  //l'ultima ricerca chiesta dalla pagina
  String cerca = "";

  //metodi
  CercaInvitatiBloc({required this.utentiInvitabiliUseCase}) : super(CercaInvitatiInitial()) {
    on<CercaInvitatiRichiesta>(_onCercaInvitatiRichiesta);
  }

  Future<void> _onCercaInvitatiRichiesta(CercaInvitatiRichiesta evento, Emitter<CercaInvitatiState> emit) async
  {
    cerca = evento.cerca;
    emit(CercaInvitatiLoading());

    //se l'utente scrive in fretta la risposta di una ricerca vecchia puo arrivare dopo quella nuova:
    //per questo prima di ogni emit controllo che la ricerca sia ancora l'ultima chiesta
    try
    {
      final utenti = await utentiInvitabiliUseCase.call(evento.cerca);
      if(cerca == evento.cerca)
      {
        emit(CercaInvitatiCaricati(utenti: utenti));
      }
    }
    on ErroreGenericoServer catch (e)
    {
      if(cerca == evento.cerca)
      {
        emit(CercaInvitatiErrore(messaggio: e.messaggio));
      }
    }
    on Exception //timeout o rete assente: il Client li lascia passare cosi come sono, senza questo la pagina resterebbe ferma
    {
      if(cerca == evento.cerca)
      {
        emit(CercaInvitatiErrore(messaggio: ErroreGenericoServer().messaggio));
      }
    }
  }
}
