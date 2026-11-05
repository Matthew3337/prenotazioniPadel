//gestisce l'elenco dei campi per l'admin: lettura, salvataggio ed eliminazione
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:thepadel/bloc/gestioneCampi/gestioneCampiEvent.dart';
import 'package:thepadel/bloc/gestioneCampi/gestioneCampiState.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/domainLayer/enetity/campo.dart';
import 'package:thepadel/useCase/adminUseCase.dart';
import 'package:thepadel/useCase/eccezioniUseCase.dart';
import 'package:thepadel/useCase/prenotaUseCase.dart';

class GestioneCampiBloc extends Bloc<GestioneCampiEvent, GestioneCampiState>{
  //attributi
  final ListaCampiUseCase listaCampiUseCase;
  final SalvaCampoUseCase salvaCampoUseCase;
  final EliminaCampoUseCase eliminaCampoUseCase;

  //l'ultima lista caricata, serve agli stati delle operazioni per non far sparire l'elenco
  List<Campo> campi = [];

  //metodi
  GestioneCampiBloc({required this.listaCampiUseCase, required this.salvaCampoUseCase, required this.eliminaCampoUseCase}) : super(GestioneCampiInitial()) {
    on<CampiRichiesti>(_onCampiRichiesti);
    on<SalvaCampoRichiesto>(_onSalvaCampoRichiesto);
    on<EliminaCampoRichiesto>(_onEliminaCampoRichiesto);
  }

  Future<void> _onCampiRichiesti(CampiRichiesti evento, Emitter<GestioneCampiState> emit) async
  {
    emit(GestioneCampiLoading());

    try
    {
      campi = await listaCampiUseCase.call();
      emit(CampiCaricati(campi: campi));
    }
    on ErroreGenericoServer catch (e)
    {
      emit(CampiErrore(messaggio: e.messaggio));
    }
    on Exception //timeout o rete assente: il Client li lascia passare cosi come sono, senza questo la pagina resterebbe ferma
    {
      emit(CampiErrore(messaggio: ErroreGenericoServer().messaggio));
    }
  }

  //a differenza degli altri bloc admin, dopo un errore non ricarico la lista: il form deve poter mostrare
  //il messaggio del server e uno stato arrivato subito dopo lo farebbe sparire
  Future<void> _onSalvaCampoRichiesto(SalvaCampoRichiesto evento, Emitter<GestioneCampiState> emit) async
  {
    emit(CampoInCorso(campi: campi));

    try
    {
      final salvato = await salvaCampoUseCase.call(evento.id, evento.nome, evento.alCoperto, evento.oraApertura, evento.oraChiusura);

      //cambia solo una riga, quindi aggiorno l'elenco senza richiederlo al server
      List<Campo> nuovaLista = [];
      for(Campo c in campi)
      {
        if(c.id == salvato.id)
        {
          nuovaLista.add(salvato);
        }
        else
        {
          nuovaLista.add(c);
        }
      }
      if(evento.id == null)
      {
        nuovaLista.add(salvato);
      }
      campi = nuovaLista;

      emit(CampoSalvato(campi: campi, campo: salvato));
    }
    on NomeCampoMancante catch (e)
    {
      emit(CampoOperazioneErrore(campi: campi, messaggio: e.message));
    }
    on PartitaNonTrovata catch (e)
    {
      emit(CampoOperazioneErrore(campi: campi, messaggio: e.messaggio));
    }
    on OperazioneRifiutata catch (e)
    {
      emit(CampoOperazioneErrore(campi: campi, messaggio: e.messaggio));
    }
    on ErroreGenericoServer catch (e)
    {
      emit(CampoOperazioneErrore(campi: campi, messaggio: e.messaggio));
    }
    on Exception
    {
      emit(CampoOperazioneErrore(campi: campi, messaggio: ErroreGenericoServer().messaggio));
    }
  }

  Future<void> _onEliminaCampoRichiesto(EliminaCampoRichiesto evento, Emitter<GestioneCampiState> emit) async
  {
    emit(CampoInCorso(campi: campi));

    try
    {
      await eliminaCampoUseCase.call(evento.id);

      List<Campo> nuovaLista = [];
      for(Campo c in campi)
      {
        if(c.id != evento.id)
        {
          nuovaLista.add(c);
        }
      }
      campi = nuovaLista;

      emit(CampoEliminato(campi: campi));
    }
    on PartitaNonTrovata catch (e)
    {
      emit(CampoOperazioneErrore(campi: campi, messaggio: e.messaggio));
    }
    on OperazioneRifiutata catch (e)
    {
      emit(CampoOperazioneErrore(campi: campi, messaggio: e.messaggio));
    }
    on ErroreGenericoServer catch (e)
    {
      emit(CampoOperazioneErrore(campi: campi, messaggio: e.messaggio));
    }
    on Exception
    {
      emit(CampoOperazioneErrore(campi: campi, messaggio: ErroreGenericoServer().messaggio));
    }
  }
}
