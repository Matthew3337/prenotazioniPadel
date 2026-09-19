import 'package:thepadel/dataLayer/model/prenotazioneModel.dart';
import 'package:thepadel/dataLayer/model/slotOrarioModel.dart';
import 'package:thepadel/domainLayer/enetity/prenotazione.dart';
import 'package:thepadel/domainLayer/enetity/slotOrario.dart';

// Sostituisci con i tuoi import/nome modello reali.
// import 'package:thepadel/dataLayer/model/slotDisponibileModel.dart';
// import 'package:thepadel/dataLayer/model/classificaModel.dart';

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

  // Rinomina ClassificaModel con il tuo modello effettivo.
 // final SectionState<ClassificaModel> classifica;

  const HomeState({
    required this.prossimaPartita,
    required this.slotOggi,
    //required this.classifica,
  });

  factory HomeState.initial() {
    return const HomeState(
      prossimaPartita: SectionLoading(),
      slotOggi: SectionLoading(),
      //classifica: SectionLoading(),
    );
  }

  HomeState copyWith({ //serve a creare una nuova istanza di home state con tutto uguale tranne i campi che cambio passandoli come parametri 
    SectionState<Prenotazione>? prossimaPartita,
    SectionState<List<SlotOrario>>? slotOggi,
    //SectionState<ClassificaModel>? classifica,
  }) {
    return HomeState(
      prossimaPartita: prossimaPartita ?? this.prossimaPartita,
      slotOggi: slotOggi ?? this.slotOggi,
      //classifica: classifica ?? this.classifica,
    );
  }
}