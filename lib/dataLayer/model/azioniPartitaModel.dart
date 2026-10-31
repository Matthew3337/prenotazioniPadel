import 'package:thepadel/domainLayer/enetity/azioniPartita.dart';

class AzioniPartitaModel extends AzioniPartita{

  AzioniPartitaModel({required super.puoInvitare, required super.puoEliminare, required super.puoUscire, required super.puoConfermare, required super.puoRegistrareRisultato});

  factory AzioniPartitaModel.fromJson(Map<String, dynamic> json)
  {
    return AzioniPartitaModel(
      puoInvitare: json['puoInvitare'] as bool,
      puoEliminare: json['puoEliminare'] as bool,
      puoUscire: json['puoUscire'] as bool,
      puoConfermare: json['puoConfermare'] as bool,
      puoRegistrareRisultato: json['puoRegistrareRisultato'] as bool
    );
  }
}
