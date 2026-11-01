import 'package:thepadel/domainLayer/enetity/utenteInvitabile.dart';

class UtenteInvitabileModel extends UtenteInvitabile{

  UtenteInvitabileModel({required super.telefono, required super.nome, required super.cognome, required super.livello});

  factory UtenteInvitabileModel.fromJson(Map<String, dynamic> json)
  {
    return UtenteInvitabileModel(
      telefono: json['telefono'] as String,
      nome: json['nome'] as String,
      cognome: json['cognome'] as String,
      //il livello puo arrivare come intero (es. 3) o come decimale (es. 2.5), quindi lo leggo come num e lo converto
      livello: (json['livello'] as num).toDouble()
    );
  }
}
