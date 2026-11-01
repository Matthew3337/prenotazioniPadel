import 'package:thepadel/dataLayer/model/setPartitaModel.dart';
import 'package:thepadel/domainLayer/enetity/risultatoPartita.dart';

class RisultatoPartitaModel extends RisultatoPartita{

  RisultatoPartitaModel({required super.set, required super.squadraUtente, required super.esito, required super.puntiAssegnati});

  factory RisultatoPartitaModel.fromJson(Map<String, dynamic> json)
  {
    List<dynamic> setJson = json['set'] as List<dynamic>;
    List<SetPartitaModel> set = setJson.map((e) => SetPartitaModel.fromJson(e as Map<String, dynamic>)).toList();

    return RisultatoPartitaModel(
      set: set,
      squadraUtente: json['squadraUtente'] as int?,
      esito: json['esito'] as String?,
      puntiAssegnati: json['puntiAssegnati'] as int?
    );
  }
}
