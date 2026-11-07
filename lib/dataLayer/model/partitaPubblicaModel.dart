import 'package:flutter/material.dart';
import 'package:thepadel/domainLayer/enetity/partitaPubblica.dart';

class PartitaPubblicaModel extends PartitaPubblica{

  PartitaPubblicaModel({required super.id, required super.idCampo, required super.nomeCampo, required super.dataPartita, required super.oraInizio, required super.oraFine, required super.nomeCreatore, required super.cognomeCreatore, required super.livelloCreatore, required super.postiLiberi});

  factory PartitaPubblicaModel.fromJson(Map<String, dynamic> json)
  {
    return PartitaPubblicaModel(
      id: json['id'] as int,
      idCampo: json['idCampo'] as int,
      nomeCampo: json['nomeCampo'] as String,
      dataPartita: DateTime.parse(json['dataPartita']),
      oraInizio: _parseTimeOfDay(json['oraInizio']),
      oraFine: _parseTimeOfDay(json['oraFine']),
      nomeCreatore: json['nomeCreatore'] as String?,
      cognomeCreatore: json['cognomeCreatore'] as String?,
      //il livello puo arrivare come intero (es. 3) o come decimale (es. 2.5), quindi lo leggo come num e lo converto.
      //Se il creatore e un admin il server manda null
      livelloCreatore: (json['livelloCreatore'] as num?)?.toDouble(),
      postiLiberi: json['postiLiberi'] as int
    );
  }

  static TimeOfDay _parseTimeOfDay(String orario)
  {
    final parti = orario.split(':');
    //i secondi (parti[2]) li ignoro, TimeOfDay non li supporta
    return TimeOfDay(hour: int.parse(parti[0]), minute: int.parse(parti[1]));
  }
}
