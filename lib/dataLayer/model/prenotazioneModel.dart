import 'package:flutter/material.dart';
import 'package:thepadel/domainLayer/enetity/prenotazione.dart';

class PrenotazioneModel extends Prenotazione{
  
  PrenotazioneModel({required super.dataPrenotazione, required super.id, required super.idCampo, required super.idGiocatore1, required super.idGiocatore2, required super.idGiocatore3, required super.idGiocatore4, required super.oraFine, required super.oraInizio});

  factory PrenotazioneModel.fromJson(Map<String, dynamic> json)
  {
    return PrenotazioneModel(
      dataPrenotazione: DateTime.parse(json['dataPrenotazione']), 
      id: json['id'] as int, 
      idCampo: json['idCampo'] as int, 
      idGiocatore1: json['idGiocatore1'] as int, 
      idGiocatore2: json['idGiocatore2'] as int?, 
      idGiocatore3: json['idGiocatore3'] as int?, 
      idGiocatore4: json['idGiocatore4'] as int?, 
      oraFine: _parseTimeOfDay(json['oraFine']), 
      oraInizio: _parseTimeOfDay(json['oraInizio']));
  }

  Map<String, dynamic> toJson()
  {
    return {
      'dataPrenotazione' : dataPrenotazione.toIso8601String(),
      'id' : id,
      'idCampo' : idCampo,
      'idGiocatore1' : idGiocatore1,
      'idGiocatore2' : idGiocatore2,
      'idGiocatore3' : idGiocatore3,
      'idGiocatore4' : idGiocatore4,
      'oraFine' : oraFine.toString(),
      'oraInizio' : oraInizio.toString()
    };
  }

  static TimeOfDay _parseTimeOfDay(String orario) {
  final parti = orario.split(':');
  return TimeOfDay(
    hour: int.parse(parti[0]),
    minute: int.parse(parti[1]),
    // i secondi (parti[2]) li ignoriamo, TimeOfDay non li supporta
  );
}

static String _formatTimeOfDay(TimeOfDay orario) {
    final h = orario.hour.toString().padLeft(2, '0');
    final m = orario.minute.toString().padLeft(2, '0');
    return '$h:$m:00'; // aggiungo i secondi per coerenza col formato backend
  }
}