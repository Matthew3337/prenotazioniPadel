//gestisce la pagina dei livelli: elenco degli utenti, ricerca e cambio del livello
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:thepadel/bloc/gestioneLivelli/gestioneLivelliEvent.dart';
import 'package:thepadel/bloc/gestioneLivelli/gestioneLivelliState.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/domainLayer/enetity/utenteAdmin.dart';
import 'package:thepadel/useCase/adminUseCase.dart';
import 'package:thepadel/useCase/eccezioniUseCase.dart';

class GestioneLivelliBloc extends Bloc<GestioneLivelliEvent, GestioneLivelliState>{
  //attributi
  final UtentiAdminUseCase utentiAdminUseCase;
  final CambiaLivelloUseCase cambiaLivelloUseCase;

  //l'ultima lista caricata, serve agli stati del cambio di livello per non far sparire l'elenco
  List<UtenteAdmin> utenti = [];

  //l'ultima ricerca fatta, serve per ricaricare la stessa lista dopo un salvataggio fallito
  String cerca = "";

  //metodi
  GestioneLivelliBloc({required this.utentiAdminUseCase, required this.cambiaLivelloUseCase}) : super(GestioneLivelliInitial()) {
    on<UtentiRichiesti>(_onUtentiRichiesti);
    on<CambiaLivelloRichiesto>(_onCambiaLivelloRichiesto);
  }

  Future<void> _onUtentiRichiesti(UtentiRichiesti evento, Emitter<GestioneLivelliState> emit) async
  {
    emit(GestioneLivelliLoading());
    cerca = evento.cerca;

    try
    {
      utenti = await utentiAdminUseCase.call(cerca);
      emit(UtentiCaricati(utenti: utenti));
    }
    on PartitaNonTrovata catch (e)
    {
      emit(UtentiErrore(messaggio: e.messaggio));
    }
    on OperazioneRifiutata catch (e)
    {
      emit(UtentiErrore(messaggio: e.messaggio));
    }
    on ErroreGenericoServer catch (e)
    {
      emit(UtentiErrore(messaggio: e.messaggio));
    }
    on Exception //timeout o rete assente: il Client li lascia passare cosi come sono, senza questo la pagina resterebbe ferma
    {
      emit(UtentiErrore(messaggio: ErroreGenericoServer().messaggio));
    }
  }

  Future<void> _onCambiaLivelloRichiesto(CambiaLivelloRichiesto evento, Emitter<GestioneLivelliState> emit) async
  {
    emit(CambioLivelloInCorso(utenti: utenti, telefono: evento.telefono));

    try
    {
      final aggiornato = await cambiaLivelloUseCase.call(evento.telefono, evento.livello);

      //cambia solo una riga, quindi aggiorno l'elenco senza richiederlo al server
      List<UtenteAdmin> nuovaLista = [];
      for(UtenteAdmin u in utenti)
      {
        if(u.telefono == aggiornato.telefono)
        {
          nuovaLista.add(aggiornato);
        }
        else
        {
          nuovaLista.add(u);
        }
      }
      utenti = nuovaLista;

      emit(CambioLivelloRiuscito(utenti: utenti, utente: aggiornato));
      return;
    }
    on LivelloNonValido catch (e)
    {
      //il server non e stato chiamato: la lista e ancora buona, non serve ricaricarla
      emit(CambioLivelloErrore(utenti: utenti, messaggio: e.message));
      return;
    }
    on PartitaNonTrovata catch (e)
    {
      emit(CambioLivelloErrore(utenti: utenti, messaggio: e.messaggio));
    }
    on OperazioneRifiutata catch (e)
    {
      emit(CambioLivelloErrore(utenti: utenti, messaggio: e.messaggio));
    }
    on ErroreGenericoServer catch (e)
    {
      emit(CambioLivelloErrore(utenti: utenti, messaggio: e.messaggio));
    }
    on Exception
    {
      emit(CambioLivelloErrore(utenti: utenti, messaggio: ErroreGenericoServer().messaggio));
    }

    //se il server ha rifiutato l'elenco e probabilmente cambiato, quindi lo ricarico;
    //non emetto il Loading cosi la lista resta a schermo finche non arriva quella nuova
    await _ricaricaUtenti(emit);
  }

  Future<void> _ricaricaUtenti(Emitter<GestioneLivelliState> emit) async
  {
    try
    {
      utenti = await utentiAdminUseCase.call(cerca);
      emit(UtentiCaricati(utenti: utenti));
    }
    //a differenza degli inviti, se fallisce anche la ricarica non mostro la pagina di errore:
    //l'errore l'ho gia segnalato e l'admin deve continuare a vedere la lista che aveva
    on PartitaNonTrovata
    {
      emit(UtentiCaricati(utenti: utenti));
    }
    on OperazioneRifiutata
    {
      emit(UtentiCaricati(utenti: utenti));
    }
    on ErroreGenericoServer
    {
      emit(UtentiCaricati(utenti: utenti));
    }
    on Exception
    {
      emit(UtentiCaricati(utenti: utenti));
    }
  }
}
