import 'package:thepadel/domainLayer/enetity/campo.dart';
import 'package:thepadel/domainLayer/enetity/partitaStorico.dart';
import 'package:thepadel/domainLayer/enetity/slotOrario.dart';

//tutti gli stati sanno quale giorno e selezionato, cosi la barra dei giorni resta a schermo anche durante il caricamento e in errore
abstract class PrenotaState {
  final DateTime giorno; //a mezzanotte, e sempre uno di giorni
  final List<DateTime> giorni; //i 7 giorni selezionabili, a partire da oggi
  PrenotaState({required this.giorno, required this.giorni});
}

class PrenotaInitial extends PrenotaState {
  PrenotaInitial({required super.giorno, required super.giorni});
}

class PrenotaLoading extends PrenotaState {
  PrenotaLoading({required super.giorno, required super.giorni});
}

class PrenotaCaricato extends PrenotaState {
  final List<Campo> campi;
  final Map<int, List<SlotOrario>> slotPerCampo; //la chiave e l'id del campo, gli slot sono in ordine di orario
  final List<PartitaStorico> partiteUtente; //le partite dell'utente nel giorno selezionato, vuota anche se lo storico non e arrivato

  PrenotaCaricato({required super.giorno, required super.giorni, required this.campi, required this.slotPerCampo, required this.partiteUtente});

  //metodi

  //la partita dell'utente che occupa questo slot, null se non ce n'e una
  PartitaStorico? partitaUtenteDelloSlot(SlotOrario slot)
  {
    final inizio = slot.inizio;
    for(final partita in partiteUtente)
    {
      if(partita.idCampo == slot.idCampo && partita.oraInizio.hour == inizio.hour && partita.oraInizio.minute == inizio.minute)
      {
        return partita;
      }
    }
    return null;
  }

  //il server segna come disponibili anche gli slot gia iniziati, quindi va controllato a parte
  bool slotPassato(SlotOrario slot, DateTime adesso)
  {
    for(final campo in campi)
    {
      if(campo.id == slot.idCampo)
      {
        return slot.inizioEffettivo(giorno, campo.oraApertura).isBefore(adesso);
      }
    }
    return false;
  }
}

class PrenotaErrore extends PrenotaState {
  final String messaggio;
  PrenotaErrore({required super.giorno, required super.giorni, required this.messaggio});
}
