import 'package:thepadel/domainLayer/enetity/slotOrario.dart';

class SlotOrarioModel extends SlotOrario{
  SlotOrarioModel({required super.idCampo, required super.oraInizio, required super.oraFine, required super.disponibile});

  factory SlotOrarioModel.fromJson(Map<String, dynamic> json) {
    return SlotOrarioModel(
      idCampo: json['idCampo'],
      oraInizio: json['oraInizio'],
      oraFine: json['oraFine'],
      disponibile: json['disponibile'],
    );
  }
  
}