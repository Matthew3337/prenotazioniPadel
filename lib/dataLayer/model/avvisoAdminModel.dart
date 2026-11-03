import 'package:flutter/material.dart';
import 'package:thepadel/domainLayer/enetity/avvisoAdmin.dart';

class AvvisoAdminModel extends AvvisoAdmin{

  AvvisoAdminModel({required super.id, required super.idPartita, required super.nomeCampo, required super.dataPartita, required super.oraInizio, required super.oraFine, required super.postiLiberi});

  factory AvvisoAdminModel.fromJson(Map<String, dynamic> json)
  {
    return AvvisoAdminModel(
      id: json['id'] as int,
      idPartita: json['idPartita'] as int,
      nomeCampo: json['nomeCampo'] as String,
      dataPartita: DateTime.parse(json['dataPartita']),
      oraInizio: _parseTimeOfDay(json['oraInizio']),
      oraFine: _parseTimeOfDay(json['oraFine']),
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
