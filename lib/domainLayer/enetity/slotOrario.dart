import 'package:flutter/material.dart';

class SlotOrario {
  final int idCampo;
  final String oraInizio;
  final String oraFine;
  final bool disponibile;
  final String nomeCampo;

  SlotOrario({
    required this.idCampo,
    required this.oraInizio,
    required this.oraFine,
    required this.disponibile,
    required this.nomeCampo
  });

  //l'ora puo arrivare con o senza i secondi, a me servono solo ore e minuti
  TimeOfDay get inizio
  {
    final parti = oraInizio.split(':');
    return TimeOfDay(hour: int.parse(parti[0]), minute: int.parse(parti[1]));
  }

  //per il server la data di uno slot e quella della serata: un'ora precedente all'apertura del campo
  //(es. 00:30 con apertura alle 09:00) cade quindi nel giorno dopo
  DateTime inizioEffettivo(DateTime dataSerata, TimeOfDay oraApertura)
  {
    final ora = inizio;
    final dopoMezzanotte = ora.hour < oraApertura.hour || (ora.hour == oraApertura.hour && ora.minute < oraApertura.minute);
    final giorno = dopoMezzanotte ? dataSerata.day + 1 : dataSerata.day;
    return DateTime(dataSerata.year, dataSerata.month, giorno, ora.hour, ora.minute);
  }

}
