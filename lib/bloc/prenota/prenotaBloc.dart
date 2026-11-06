//gestisce la pagina prenota: il tabellone degli slot di tutti i campi per il giorno scelto
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:thepadel/bloc/prenota/prenotaEvent.dart';
import 'package:thepadel/bloc/prenota/prenotaState.dart';
import 'package:thepadel/dataLayer/exception.dart';
import 'package:thepadel/domainLayer/enetity/partitaStorico.dart';
import 'package:thepadel/domainLayer/enetity/slotOrario.dart';
import 'package:thepadel/useCase/homeUseCase.dart';
import 'package:thepadel/useCase/miePartiteUseCase.dart';
import 'package:thepadel/useCase/prenotaUseCase.dart';

class PrenotaBloc extends Bloc<PrenotaEvent, PrenotaState>{
  //attributi
  final ListaCampiUseCase listaCampiUseCase;
  final SlotDisponibiliUseCase slotUseCase;
  final MiePartiteUseCase miePartiteUseCase;

  //metodi
  PrenotaBloc({required this.listaCampiUseCase, required this.slotUseCase, required this.miePartiteUseCase}) : super(_statoIniziale()) {
    on<PrenotaRichiesta>(_onPrenotaRichiesta);
    on<PrenotaGiornoCambiato>(_onPrenotaGiornoCambiato);
  }

  static PrenotaInitial _statoIniziale()
  {
    final giorni = _prossimiGiorni();
    return PrenotaInitial(giorno: giorni.first, giorni: giorni);
  }

  //da oggi a oggi + 15 compreso, lo stesso limite che controlla il server.
  //Uso il costruttore di DateTime e non add(Duration): con il cambio dell'ora legale un giorno non e sempre di 24 ore
  static List<DateTime> _prossimiGiorni()
  {
    final oggi = DateTime.now();
    List<DateTime> giorni = [];
    for(int i = 0; i <= 15; i++)
    {
      giorni.add(DateTime(oggi.year, oggi.month, oggi.day + i));
    }
    return giorni;
  }

  Future<void> _onPrenotaRichiesta(PrenotaRichiesta evento, Emitter<PrenotaState> emit) async
  {
    await _caricaGiorno(state.giorno, emit);
  }

  Future<void> _onPrenotaGiornoCambiato(PrenotaGiornoCambiato evento, Emitter<PrenotaState> emit) async
  {
    await _caricaGiorno(evento.giorno, emit);
  }

  Future<void> _caricaGiorno(DateTime giornoRichiesto, Emitter<PrenotaState> emit) async
  {
    final giorni = _prossimiGiorni();
    //se la pagina resta aperta oltre la mezzanotte il giorno selezionato puo non essere piu tra quelli validi
    DateTime giorno = DateTime(giornoRichiesto.year, giornoRichiesto.month, giornoRichiesto.day);
    if(!giorni.contains(giorno))
    {
      giorno = giorni.first;
    }

    emit(PrenotaLoading(giorno: giorno, giorni: giorni));

    //le risposte possono arrivare dopo che l'utente ha gia scelto un altro giorno:
    //per questo prima di ogni emit controllo che il giorno sia ancora quello selezionato
    try
    {
      final campi = await listaCampiUseCase.call();
      final slots = await slotUseCase.call(giorno);
      final partiteUtente = await _caricaPartiteUtente(giorno);

      //il repository ordina per testo dell'ora, ma uno slot dopo mezzanotte va in fondo e non in cima
      Map<int, List<SlotOrario>> slotPerCampo = {};
      for(final campo in campi)
      {
        List<SlotOrario> slotDelCampo = [];
        for(final slot in slots)
        {
          if(slot.idCampo == campo.id)
          {
            slotDelCampo.add(slot);
          }
        }
        slotDelCampo.sort((a, b) => a.inizioEffettivo(giorno, campo.oraApertura).compareTo(b.inizioEffettivo(giorno, campo.oraApertura)));
        slotPerCampo[campo.id] = slotDelCampo;
      }

      if(state.giorno == giorno)
      {
        emit(PrenotaCaricato(giorno: giorno, giorni: giorni, campi: campi, slotPerCampo: slotPerCampo, partiteUtente: partiteUtente));
      }
    }
    on ErroreGenericoServer catch (e)
    {
      if(state.giorno == giorno)
      {
        emit(PrenotaErrore(giorno: giorno, giorni: giorni, messaggio: e.messaggio));
      }
    }
    on Exception //timeout o rete assente: il Client li lascia passare cosi come sono
    {
      if(state.giorno == giorno)
      {
        emit(PrenotaErrore(giorno: giorno, giorni: giorni, messaggio: ErroreGenericoServer().messaggio));
      }
    }
  }

  //senza le mie partite il tabellone si mostra lo stesso, solo senza "La tua partita".
  //Non uso lo storico perche ora contiene solo le partite gia finite
  Future<List<PartitaStorico>> _caricaPartiteUtente(DateTime giorno) async
  {
    List<PartitaStorico> partiteDelGiorno = [];
    try
    {
      final miePartite = await miePartiteUseCase.call();
      for(final partita in miePartite)
      {
        final data = partita.dataPartita;
        if(data.year == giorno.year && data.month == giorno.month && data.day == giorno.day)
        {
          partiteDelGiorno.add(partita);
        }
      }
    }
    on Exception
    {
      partiteDelGiorno = [];
    }
    return partiteDelGiorno;
  }
}
