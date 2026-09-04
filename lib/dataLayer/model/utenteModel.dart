import 'package:thepadel/domainLayer/enetity/utente.dart';

class UtenteModel extends Utente{

  UtenteModel({required super.cognome, required super.dataNascita, required super.id, required super.isAdmin, required super.nome, required super.telefono, required super.livello});

  factory UtenteModel.fromJson(Map<String, dynamic> json)
  {
    return UtenteModel(
      id : json['id'] as int,
      nome: json['nome'] as String,
      cognome : json['cognome'] as String,
      telefono : json['telefono'] as String,
      isAdmin : json['isAdmin'] as bool,
      dataNascita : DateTime.parse(json['dataNascita']),
      livello : json['livello'] as double
    );
  }
}