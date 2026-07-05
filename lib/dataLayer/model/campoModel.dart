import 'package:flutter/material.dart';
import 'package:thepadel/domainLayer/enetity/campo.dart';

class CampoModel extends Campo {

  CampoModel({required super.alCoperto, required super.id, required super.nome, required super.oraApertura, required super.oraChiusura });

  //factory non instanzia l oggetto subito qunidn consente un esecuzione piu complessa prima e consente di ritornare sottoclassi
  factory CampoModel.fromJson(Map<String, dynamic> json)
  {
    return CampoModel(
      alCoperto: json['alCoperto'] as bool,
      id: json['id'] as int,
      nome : json['nome'] as String,
      oraApertura: _parseTimeOfDay(json['oraApertura']),
      oraChiusura: _parseTimeOfDay(json['oraChiusura'])
    );
  }

  Map<String, dynamic> toJson()
  {
    return {
      "id" : id,
      "nome" : nome,
      "alCoperto" : alCoperto,
      "oraApertura" : _formatTimeOfDay(oraApertura),
      "oraChiusura" : _formatTimeOfDay(oraChiusura)
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