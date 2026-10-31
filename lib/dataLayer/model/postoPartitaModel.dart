import 'package:thepadel/domainLayer/enetity/postoPartita.dart';

class PostoPartitaModel extends PostoPartita{

  PostoPartitaModel({required super.tipo, required super.telefono, required super.nome, required super.cognome, required super.livello, required super.confermata});

  factory PostoPartitaModel.fromJson(Map<String, dynamic> json)
  {
    //il livello puo arrivare come intero (es. 3) o come decimale (es. 2.5), quindi lo leggo come num e lo converto
    double? livello;
    if(json['livello'] != null)
    {
      livello = (json['livello'] as num).toDouble();
    }

    return PostoPartitaModel(
      tipo: json['tipo'] as String,
      telefono: json['telefono'] as String?,
      nome: json['nome'] as String?,
      cognome: json['cognome'] as String?,
      livello: livello,
      confermata: json['confermata'] as bool
    );
  }
}
