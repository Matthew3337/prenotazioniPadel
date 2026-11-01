import 'package:flutter/material.dart';
import 'package:thepadel/domainLayer/enetity/partitaInvito.dart';

class PartitaInvitoModel extends PartitaInvito{

  PartitaInvitoModel({required super.id, required super.idCampo, required super.nomeCampo, required super.dataPartita, required super.oraInizio, required super.oraFine, required super.stato, required super.tipo, required super.nomeCreatore, required super.cognomeCreatore});

  factory PartitaInvitoModel.fromJson(Map<String, dynamic> json)
  {
    return PartitaInvitoModel(
      id: json['id'] as int,
      idCampo: json['idCampo'] as int,
      nomeCampo: json['nomeCampo'] as String,
      dataPartita: DateTime.parse(json['dataPartita']),
      oraInizio: _parseTimeOfDay(json['oraInizio']),
      oraFine: _parseTimeOfDay(json['oraFine']),
      stato: json['stato'] as String,
      tipo: json['tipo'] as String,
      nomeCreatore: json['nomeCreatore'] as String,
      cognomeCreatore: json['cognomeCreatore'] as String
    );
  }

  static TimeOfDay _parseTimeOfDay(String orario)
  {
    final parti = orario.split(':');
    //i secondi (parti[2]) li ignoro, TimeOfDay non li supporta
    return TimeOfDay(hour: int.parse(parti[0]), minute: int.parse(parti[1]));
  }
}
