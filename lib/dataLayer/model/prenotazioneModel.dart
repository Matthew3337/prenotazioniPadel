import 'package:flutter/material.dart';
import 'package:thepadel/domainLayer/enetity/prenotazione.dart';

class PrenotazioneModel extends Prenotazione{
  
  PrenotazioneModel({required super.dataPrenotazione, required super.id, required super.idCampo, required super.telefonoGiocatore1, required super.telefonoGiocatore2, required super.telefonoGiocatore3, required super.telefonoGiocatore4, required super.oraFine, required super.oraInizio, required super.stato});

  factory PrenotazioneModel.fromJson(Map<String, dynamic> json)
  {
    return PrenotazioneModel(
      dataPrenotazione: DateTime.parse(json['dataPrenotazione']), 
      id: json['id'] as int, 
      idCampo: json['idCampo'] as int, 
      telefonoGiocatore1: json['telefonoGiocatore1'] as String, 
      telefonoGiocatore2: json['telefonoGiocatore2'] as String?, 
      telefonoGiocatore3: json['telefonoGiocatore3'] as String?, 
      telefonoGiocatore4: json['telefonoGiocatore4'] as String?, 
      oraFine: _parseTimeOfDay(json['oraFine']), 
      oraInizio: _parseTimeOfDay(json['oraInizio']),
      stato: json['stato'] as String);
  }

  Map<String, dynamic> toJson()
  {
    return {
      'dataPrenotazione' : dataPrenotazione.toIso8601String(),
      'id' : id,
      'idCampo' : idCampo,
      'telefonoGiocatore1' : telefonoGiocatore1,
      'telefonoGiocatore2' : telefonoGiocatore2,
      'telefonoGiocatore3' : telefonoGiocatore3,
      'telefonoGiocatore4' : telefonoGiocatore4,
      'oraFine' : oraFine.toString(),
      'oraInizio' : oraInizio.toString(),
      'stato' : stato
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