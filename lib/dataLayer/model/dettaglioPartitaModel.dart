import 'package:flutter/material.dart';
import 'package:thepadel/dataLayer/model/azioniPartitaModel.dart';
import 'package:thepadel/dataLayer/model/postoPartitaModel.dart';
import 'package:thepadel/domainLayer/enetity/dettaglioPartita.dart';

class DettaglioPartitaModel extends DettaglioPartita{

  DettaglioPartitaModel({required super.id, required super.idCampo, required super.nomeCampo, required super.dataPartita, required super.oraInizio, required super.oraFine, required super.stato, required super.tipo, required super.telefonoCreatore, required super.posti, required super.azioni});

  factory DettaglioPartitaModel.fromJson(Map<String, dynamic> json)
  {
    List<dynamic> postiJson = json['posti'] as List<dynamic>;
    List<PostoPartitaModel> posti = postiJson.map((e) => PostoPartitaModel.fromJson(e as Map<String, dynamic>)).toList();

    return DettaglioPartitaModel(
      id: json['id'] as int,
      idCampo: json['idCampo'] as int,
      nomeCampo: json['nomeCampo'] as String,
      dataPartita: DateTime.parse(json['dataPartita']),
      oraInizio: _parseTimeOfDay(json['oraInizio']),
      oraFine: _parseTimeOfDay(json['oraFine']),
      stato: json['stato'] as String,
      tipo: json['tipo'] as String,
      telefonoCreatore: json['telefonoCreatore'] as String,
      posti: posti,
      azioni: AzioniPartitaModel.fromJson(json['azioni'] as Map<String, dynamic>)
    );
  }

  static TimeOfDay _parseTimeOfDay(String orario)
  {
    final parti = orario.split(':');
    //i secondi (parti[2]) li ignoro, TimeOfDay non li supporta
    return TimeOfDay(hour: int.parse(parti[0]), minute: int.parse(parti[1]));
  }
}
