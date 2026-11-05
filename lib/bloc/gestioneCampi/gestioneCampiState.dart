import 'package:thepadel/domainLayer/enetity/campo.dart';

abstract class GestioneCampiState {}

class GestioneCampiInitial extends GestioneCampiState {}
class GestioneCampiLoading extends GestioneCampiState {}

class CampiCaricati extends GestioneCampiState {
  final List<Campo> campi;
  CampiCaricati({required this.campi});
}

class CampiErrore extends GestioneCampiState {
  final String messaggio;
  CampiErrore({required this.messaggio});
}

//gli stati delle operazioni si portano dietro la lista, cosi la pagina puo continuare a mostrarla
class CampoInCorso extends GestioneCampiState {
  final List<Campo> campi;
  CampoInCorso({required this.campi});
}

//la lista qui contiene gia il campo salvato
class CampoSalvato extends GestioneCampiState {
  final List<Campo> campi;
  final Campo campo;
  CampoSalvato({required this.campi, required this.campo});
}

class CampoEliminato extends GestioneCampiState {
  final List<Campo> campi;
  CampoEliminato({required this.campi});
}

class CampoOperazioneErrore extends GestioneCampiState {
  final List<Campo> campi;
  final String messaggio;
  CampoOperazioneErrore({required this.campi, required this.messaggio});
}
