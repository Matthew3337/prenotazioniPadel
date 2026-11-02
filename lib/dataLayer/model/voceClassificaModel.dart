import 'package:thepadel/domainLayer/enetity/voceClassifica.dart';

class VoceClassificaModel extends VoceClassifica{

  VoceClassificaModel({required super.posizione, required super.telefono, required super.nome, required super.cognome, required super.punteggio, required super.utenteCorrente});

  factory VoceClassificaModel.fromJson(Map<String, dynamic> json)
  {
    return VoceClassificaModel(
      posizione: json['posizione'] as int,
      telefono: json['telefono'] as String,
      nome: json['nome'] as String,
      cognome: json['cognome'] as String,
      punteggio: json['punteggio'] as int,
      utenteCorrente: json['utenteCorrente'] as bool
    );
  }
}
