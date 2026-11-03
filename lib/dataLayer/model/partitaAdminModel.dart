import 'package:flutter/material.dart';
import 'package:thepadel/dataLayer/model/setPartitaModel.dart';
import 'package:thepadel/domainLayer/enetity/partitaAdmin.dart';

class PartitaAdminModel extends PartitaAdmin{

  PartitaAdminModel({required super.id, required super.oraInizio, required super.oraFine, required super.stato, required super.tipo, required super.giocatori, required super.postiLiberi, required super.risultato});

  factory PartitaAdminModel.fromJson(Map<String, dynamic> json)
  {
    List<dynamic> giocatoriJson = json['giocatori'] as List<dynamic>;
    List<String> giocatori = giocatoriJson.map((e) => e as String).toList();

    //qui il risultato e direttamente l'elenco dei set, oppure null se la partita non ne ha
    List<SetPartitaModel>? risultato;
    if(json['risultato'] != null)
    {
      List<dynamic> setJson = json['risultato'] as List<dynamic>;
      risultato = setJson.map((e) => SetPartitaModel.fromJson(e as Map<String, dynamic>)).toList();
    }

    return PartitaAdminModel(
      id: json['id'] as int,
      oraInizio: _parseTimeOfDay(json['oraInizio']),
      oraFine: _parseTimeOfDay(json['oraFine']),
      stato: json['stato'] as String,
      tipo: json['tipo'] as String,
      giocatori: giocatori,
      postiLiberi: json['postiLiberi'] as int,
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
