import 'package:thepadel/domainLayer/enetity/utenteAdmin.dart';

class UtenteAdminModel extends UtenteAdmin{

  UtenteAdminModel({required super.telefono, required super.nome, required super.cognome, required super.livello, required super.punteggio});

  factory UtenteAdminModel.fromJson(Map<String, dynamic> json)
  {
    return UtenteAdminModel(
      telefono: json['telefono'] as String,
      nome: json['nome'] as String,
      cognome: json['cognome'] as String,
      //il livello puo arrivare come intero (es. 3) o come decimale (es. 2.5), quindi lo leggo come num e lo converto
      livello: (json['livello'] as num).toDouble(),
      punteggio: json['punteggio'] as int
    );
  }
}
