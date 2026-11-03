import 'package:thepadel/domainLayer/enetity/prenotazione.dart';
import 'package:thepadel/domainLayer/enetity/slotOrario.dart';
import 'package:thepadel/repositoryImpl/campoRepoImpl.dart';
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

//gli slot che si possono ancora prenotare in una data, campo per campo.
//Il server segna come disponibili anche quelli gia iniziati, che pero rifiuterebbe: per questo li tolgo qui
class SlotLiberiDataUseCase {

  final CampoRepoImpl repo;

  SlotLiberiDataUseCase({required this.repo});

  Future<List<SlotOrario>> call(DateTime data, DateTime adesso) async
  {
    final campi = await repo.getListaCampi();
    final slots = await repo.getListaOrariSlotCampiAll(data);

    List<SlotOrario> liberi = [];
    for(final campo in campi)
    {
      List<SlotOrario> liberiDelCampo = [];
      for(final slot in slots)
      {
        if(slot.idCampo == campo.id && slot.disponibile && slot.inizioEffettivo(data, campo.oraApertura).isAfter(adesso))
        {
          liberiDelCampo.add(slot);
        }
      }
      liberiDelCampo.sort((a, b) => a.inizioEffettivo(data, campo.oraApertura).compareTo(b.inizioEffettivo(data, campo.oraApertura)));
      liberi.addAll(liberiDelCampo);
    }
    return liberi;
  }
}
