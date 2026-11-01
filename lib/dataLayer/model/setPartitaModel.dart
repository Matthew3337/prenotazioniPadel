import 'package:thepadel/domainLayer/enetity/setPartita.dart';

class SetPartitaModel extends SetPartita{

  SetPartitaModel({required super.squadra1, required super.squadra2});

  factory SetPartitaModel.fromJson(Map<String, dynamic> json)
  {
    return SetPartitaModel(
      squadra1: json['squadra1'] as int,
      squadra2: json['squadra2'] as int
    );
  }
}
