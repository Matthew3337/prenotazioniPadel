import 'package:thepadel/domainLayer/enetity/prenotazione.dart';
import 'package:thepadel/domainLayer/enetity/slotOrario.dart';
import 'package:thepadel/repositoryImpl/prenotazioneRepoImpl.dart';
import 'package:thepadel/useCase/eccezioniUseCase.dart';

class CreaPartitaUseCase {

  final PrenotazioneRepoImpl repo;

  CreaPartitaUseCase({required this.repo});

  //lo slot da solo non sa in che giorno si trova, per questo la data va passata a parte
  Future<Prenotazione> call(SlotOrario slot, DateTime data, String tipo)
  {
    if(tipo != "PUBBLICA" && tipo != "PRIVATA")
    {
      throw TipoPartitaMancante();
    }
    return repo.creaPartita(slot.idCampo, data, slot.oraInizio, tipo);
  }
}
