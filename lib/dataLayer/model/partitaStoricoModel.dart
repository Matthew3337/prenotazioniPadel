import 'package:flutter/material.dart';
import 'package:thepadel/dataLayer/model/risultatoPartitaModel.dart';
import 'package:thepadel/domainLayer/enetity/partitaStorico.dart';

class PartitaStoricoModel extends PartitaStorico{

  PartitaStoricoModel({required super.id, required super.idCampo, required super.nomeCampo, required super.dataPartita, required super.oraInizio, required super.oraFine, required super.stato, required super.tipo, required super.risultato});

  factory PartitaStoricoModel.fromJson(Map<String, dynamic> json)
  {
    //il risultato arriva null finche nessuno lo ha registrato
    RisultatoPartitaModel? risultato;
    if(json['risultato'] != null)
    {
      risultato = RisultatoPartitaModel.fromJson(json['risultato'] as Map<String, dynamic>);
    }

    return PartitaStoricoModel(
      id: json['id'] as int,
      idCampo: json['idCampo'] as int,
      nomeCampo: json['nomeCampo'] as String,
      dataPartita: DateTime.parse(json['dataPartita']),
      oraInizio: _parseTimeOfDay(json['oraInizio']),
      oraFine: _parseTimeOfDay(json['oraFine']),
      stato: json['stato'] as String,
      tipo: json['tipo'] as String,
      risultato: risultato
    );
  }

  static TimeOfDay _parseTimeOfDay(String orario)
  {
    final parti = orario.split(':');
    //i secondi (parti[2]) li ignoro, TimeOfDay non li supporta
    return TimeOfDay(hour: int.parse(parti[0]), minute: int.parse(parti[1]));
  }
}
