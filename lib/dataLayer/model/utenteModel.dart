import 'package:thepadel/domainLayer/enetity/utente.dart';

class UtenteModel extends Utente{

  UtenteModel({required super.cognome, required super.dataNasctia, required super.id, required super.isAdmin, required super.nome, required super.password, required super.telefono, required super.livello});

  factory UtenteModel.fromJson(Map<String, dynamic> json)
  {
    return UtenteModel(
      id : json['id'] as int,
      nome: json['nome'] as String,
      cognome : json['cognome'] as String,
      telefono : json['telefono'] as String,
      password : json['password'] as String,
      isAdmin : json['isAdmin'] as bool,
      dataNasctia : DateTime.parse(json['dataNasctia']),
      livello : json['livello'] as double
    );
  }
}