import 'package:thepadel/dataLayer/model/prenotazioneModel.dart';
import 'package:thepadel/dataLayer/model/slotOrarioModel.dart';
import 'package:thepadel/domainLayer/enetity/dettaglioPartita.dart';
import 'package:thepadel/domainLayer/enetity/distaccoClassifica.dart';
import 'package:thepadel/domainLayer/enetity/prenotazione.dart';
import 'package:thepadel/domainLayer/enetity/slotOrario.dart';
import 'package:thepadel/domainLayer/enetity/voceClassifica.dart';

// Sostituisci con i tuoi import/nome modello reali.
// import 'package:thepadel/dataLayer/model/slotDisponibileModel.dart';

//LA LOGICA E', HO UNO STATO HOME CHE GESTISCE LA PAFGINA E SARA SEMPRE EMESSO LUI. MA ALL INTERNO DELLO STATO HOME HO TRE STATI PER LE TRE SEZIONI, CON COPY WITH EMETTO L ATTUALE STATO HOME MA CON LA POSSIBILITA DI MODIFICARE GLI STARTI INTERNI

abstract class SectionState<T> {
  const SectionState();
}

class SectionLoading<T> extends SectionState<T> {
  const SectionLoading();
}

class SectionSuccess<T> extends SectionState<T> {
  final T data;

  const SectionSuccess(this.data);
}

class SectionEmpty<T> extends SectionState<T> {
  const SectionEmpty();
}

class SectionError<T> extends SectionState<T> {
  final String message;

  const SectionError(this.message);
}

class HomeState {
  final SectionState<Prenotazione> prossimaPartita;
  final SectionState<List<SlotOrario>> slotOggi;
  //la riga dell'utente in classifica: SectionEmpty se non c'e, come succede all'admin
  final SectionState<VoceClassifica> classifica;
  //il dettaglio della prossima partita: SectionEmpty se la prossima partita non c'e o non e stato possibile leggerla
  final SectionState<DettaglioPartita> dettaglioProssimaPartita;
  final SectionState<int> invitiRicevuti;
  final SectionState<int> partitePubblicheAperte;
  //segue la sezione classifica: SectionEmpty se l'utente non e in classifica
  final SectionState<DistaccoClassifica> distaccoClassifica;

  const HomeState({
    required this.prossimaPartita,
    required this.slotOggi,
    required this.classifica,
    required this.dettaglioProssimaPartita,
    required this.invitiRicevuti,
    required this.partitePubblicheAperte,
    required this.distaccoClassifica,
  });

  factory HomeState.initial() {
    return const HomeState(
      prossimaPartita: SectionLoading(),
      slotOggi: SectionLoading(),
      classifica: SectionLoading(),
      dettaglioProssimaPartita: SectionLoading(),
      invitiRicevuti: SectionLoading(),
      partitePubblicheAperte: SectionLoading(),
      distaccoClassifica: SectionLoading(),
    );
  }

  HomeState copyWith({ //serve a creare una nuova istanza di home state con tutto uguale tranne i campi che cambio passandoli come parametri 
    SectionState<Prenotazione>? prossimaPartita,
    SectionState<List<SlotOrario>>? slotOggi,
    SectionState<VoceClassifica>? classifica,
    SectionState<DettaglioPartita>? dettaglioProssimaPartita,
    SectionState<int>? invitiRicevuti,
    SectionState<int>? partitePubblicheAperte,
    SectionState<DistaccoClassifica>? distaccoClassifica,
  }) {
    return HomeState(
      prossimaPartita: prossimaPartita ?? this.prossimaPartita,
      slotOggi: slotOggi ?? this.slotOggi,
      classifica: classifica ?? this.classifica,
      dettaglioProssimaPartita: dettaglioProssimaPartita ?? this.dettaglioProssimaPartita,
      invitiRicevuti: invitiRicevuti ?? this.invitiRicevuti,
      partitePubblicheAperte: partitePubblicheAperte ?? this.partitePubblicheAperte,
      distaccoClassifica: distaccoClassifica ?? this.distaccoClassifica,
    );
  }
}