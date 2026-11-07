import 'package:thepadel/domainLayer/enetity/postoPartita.dart';

class PostoPartitaModel extends PostoPartita{

  PostoPartitaModel({required super.idPosto, required super.tipo, required super.telefono, required super.nome, required super.cognome, required super.livello, required super.confermata, required super.squadra, required super.eliminato});

  factory PostoPartitaModel.fromJson(Map<String, dynamic> json)
  {
    //il livello puo arrivare come intero (es. 3) o come decimale (es. 2.5), quindi lo leggo come num e lo converto
    double? livello;
    if(json['livello'] != null)
    {
      livello = (json['livello'] as num).toDouble();
    }

    //idPosto e squadra con as int? valgono null anche se il server non li manda ancora
    return PostoPartitaModel(
      idPosto: json['idPosto'] as int?,
      tipo: json['tipo'] as String,
      telefono: json['telefono'] as String?,
      nome: json['nome'] as String?,
      cognome: json['cognome'] as String?,
      livello: livello,
      confermata: json['confermata'] as bool,
      squadra: json['squadra'] as int?,
      //il server lo manda solo da quando esiste l'eliminazione dell'account: se manca il posto non e eliminato
      eliminato: json['eliminato'] as bool? ?? false
    );
  }
}
